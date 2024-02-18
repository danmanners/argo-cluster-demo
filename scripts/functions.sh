# Description: Common functions used in the scripts

# Function to get the git root path
function getGitRootPath() {
  git rev-parse --show-toplevel
}

# Function to parse through all of the user defined input
function parseUserInput() {
  user_input=${1}
  if [[ -z "${!user_input}" ]]; then
    printf "\t> Please enter your $(echo ${user_input} | sed "s|_|\ |g"): "
    read -r $user_input
  fi
}

# Function to check all user defined input
function checkUserInput() {
  user_inputs=("$@")
  for user_input in "${user_inputs[@]}"; do
    echo -e "\t- $(echo ${user_input} | sed "s|_|\ |g"): ${!user_input}"
  done
  printf "🔍 Do these look correct? (y/n) "
  read -r confirm
  # Ask the user to confirm the input
  if [[ $confirm != "y" ]]; then
    echo "😕 Please re-run the script with the correct environment variables."
    exit 1
  fi
}

# Function to set github cli values
function setGitHubCLIValues() {
  # Check if GitHub CLI is already authenticated
  if ! gh auth status >/dev/null 2>&1; then
    # Set GitHub CLI to non-interactive mode
    gh config set prompt disabled
    # Set the github.com protocol to SSH
    gh config set -h github.com git_protocol ssh
    # Open the browser to authenticate with GitHub
    open https://github.com/login/device
    # Perform the github auth
    gh auth login -w
    # Re-enable the prompt
    gh config set prompt enabled
  else
    echo -e "\t🎉 GitHub CLI is already authenticated."
    return
  fi
}

# Function to check if a tool is installed
function checkToolInstalled() {
  tool=$1
  check_tool=$(echo $tool | awk -F, '{print $1}')
  if ! command -v $check_tool &>/dev/null; then
    echo -e "\t❌ $check_tool is not installed."
    if ! command -v brew &>/dev/null; then
      echo -e "\t❌ Homebrew is not installed. Please install Homebrew and try again."
      open https://brew.sh
      exit 1
    else
      # Check if the user wants to install the tool
      printf "\t> $check_tool is not installed. Do you want to install it? (y/n) "
      read -r install
      if [[ $install != "y" ]]; then
        echo -e "\t😕 Skipping $check_tool installation."
        exit 1
      fi
      # Install the tool
      echo -e "\t✅ Installing $check_tool..."
      # Check the third argument of the tool, if it exists, make sure we run brew tap before installing the tool
      if [[ $(echo $tool | awk -F, '{print $3}') != "" ]]; then
        brew tap $(echo $tool | awk -F, '{print $3}')
      fi
      # Install the tool
      if [[ $(echo $tool | awk -F, '{print $2}') != "" ]]; then
        brew install $(echo $tool | awk -F, '{print $2}')
      else
        brew install $check_tool
      fi
    fi
  # Check if the tool was installed successfully
  else
    echo -e "\t✅ $check_tool is installed."
  fi
}

# Create the users Sealed Secrets Keypair
function createSealedSecretsKeypair() {
  # Set the keys directory
  keys_directory="$(getGitRootPath)/keys"
  private_key_path="${keys_directory}/sealed-secret.key"
  public_key_path="${keys_directory}/sealed-secret.crt"

  # Check if the keys already exist
  if [[ ! -f "${private_key_path}" ]]; then
    echo -e "\t🔑 Creating the Sealed Secrets Keypair..."
    # Generate the keypair that will be used to encrypt the secrets
    openssl req -x509 \
      -days 3650 -nodes \
      -newkey rsa:4096 \
      -keyout "$private_key_path" \
      -out "$public_key_path" \
      -subj "/CN=sealed-secret/O=sealed-secret" >/dev/null 2>&1

    echo -e "\t🎉 Sealed Secrets Keypair created."
  else
    echo -e "\t🎉 Sealed Secrets Keypair already exists."
  fi
}

# Function to create our age encryption keypair
function createAgeKeypair() {
  # Set the keys directory
  keys_directory="$(getGitRootPath)/keys"
  private_key_path="${keys_directory}/age.key"
  public_key_path="${keys_directory}/age.pub"

  # Check if the keys already exist
  if [[ ! -f "${private_key_path}" ]]; then
    echo -e "\t🔑 Creating the Age Keypair..."
    # Generate the keypair
    age-keygen -o $private_key_path >/dev/null 2>&1
    age-keygen -y $private_key_path >${public_key_path}
    echo -e "\t🎉 Age Keypair created."
  else
    echo -e "\t🎉 Age Keypair already exists."
  fi
}

# Function to create our sops file and encrypt our sealed secrets keypair
function createSopsConfig() {
  # Set the keys directory
  keys_directory="$(getGitRootPath)/keys"
  sops_template_file="${keys_directory}/sops_template.yaml"
  sops_file_path="$(getGitRootPath)/.sops.yaml"

  # Check if the sops file already exists
  if [[ ! -f "${sops_file_path}" ]]; then
    echo -e "\t🔑 Creating the Sops File..."
    sed "s|REPLACE_THIS|$(cat ${keys_directory}/age.pub)|g" $sops_template_file >$sops_file_path
    echo -e "\t🎉 Sops File created."
  else
    echo -e "\t🎉 Sops File already exists."
  fi
}

# Function to encrypt our Sealed Secrets Key
function encryptSealedSecretsKey() {
  # Set the keys directory
  keys_directory="$(getGitRootPath)/keys"
  private_key_path="${keys_directory}/sealed-secret.key"
  encrypted_key_path="${keys_directory}/sealed-secret.key.enc"

  # Check if the encrypted key already exists
  if [[ ! -f "${encrypted_key_path}" ]]; then
    echo -e "\t🔐 Encrypting the Sealed Secrets Key..."
    # Encrypt the key
    sops -e --output ${encrypted_key_path} ${private_key_path}
    echo -e "\t🎉 Sealed Secrets Key encrypted."
  else
    echo -e "\t🎉 Sealed Secrets Key already encrypted."
  fi
}

# Function to list all of the repository secrets
function listGitHubRepoSecrets() {
  github_username=$1
  # Get the repository name
  remote_repo="${github_username}/$(basename -s .git $(git config --get remote.origin.url))"
  # List the secrets in the repository
  gh secret list -R $remote_repo
}

# Function to define and create our repository secrets using the GitHub CLI
function createGitHubRepoSecrets() {
  # Get the repository name
  remote_repo=$(basename -s .git $(git config --get remote.origin.url))
  # Provide the list of secrets that we want to create in the repository
  secrets=(
    "aws_access_key_id"
    "aws_secret_access_key"
    "region"
  )
  # Loop through the secrets and create them in the repository
  for secret in "${secrets[@]}"; do
    # Check if the secret already exists
    if gh secret list -R $remote_repo | grep -q $secret; then
      echo -e "\t🎉 $secret"
    fi
  done
}

# Function to replace values files using sed
function replaceValuesFiles() {
  original_value=${1}
  new_value=${2}
  list_of_files=${3}
  echo "List of Files: $list_of_files"
}
