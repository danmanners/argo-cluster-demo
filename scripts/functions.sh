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
  github_username=${1}
  # Get the repository name
  remote_repo="${github_username}/$(basename -s .git $(git config --get remote.origin.url))"
  # List the secrets in the repository
  for item in $(gh secret list -R $remote_repo --json name | jq -rc '.[].name'); do
    echo -e "\t- $item"
  done
}

# Function to define and create our repository secrets using the GitHub CLI
function createGitHubRepoSecrets() {
  # Get the repository name
  remote_repo="${1}/$(basename -s .git $(git config --get remote.origin.url))"
  # Provide the list of secrets that we want to create in the repository
  secrets=(
    "AWS_Account_ID"
    "aws_access_key_id"
    "aws_secret_access_key"
    "region"
  )
  # Loop through the secrets and create them in the repository
  for secret in "${secrets[@]}"; do
    # Check if the secret already exists
    upperSecret=$(echo ${secret} | tr '[:lower:]' '[:upper:]')
    printf "\t✨ Creating the ${upperSecret} secret..."
    if [[ "${!secret}" ]]; then
      gh secret set ${upperSecret} -R $remote_repo -b "${!secret}" >/dev/null 2>&1
    else
      gh secret set ${upperSecret} -R $remote_repo -b "$(aws configure get default.${secret})" >/dev/null 2>&1
    fi
    # Check if the secret was created successfully
    if [[ $? -eq 0 ]]; then
      echo -e "🎉 secret created."
    else
      echo -e "❌ secret failed to create."
    fi
  done
}

# Function to create the appropriate ECR registry
function createECRRegistry() {
  # Reusable function inside of this function
  function chk() {
    # If the repository exists, return 0, else return 1
    if [[ $(aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | xargs) =~ "${1}" ]]; then
      # if "${1}" in $(aws ecr describe-repositories | jq -r '.repositories[].repositoryName' | xargs); then
      return 0
    else
      return 1
    fi
  }
  # Get the repository name
  repository_name=$(basename -s .git $(git config --get remote.origin.url))
  # Check if the ECR registry already exists
  if chk "${repository_name}"; then
    echo -e "\t🎉 ECR Registry already exists."
  else
    echo -e "\t🔧 Creating the ECR Registry..."
    aws ecr create-repository --region=$(aws configure get default.region) --repository-name=${repository_name} >/dev/null 2>&1
    echo -e "\t🎉 ECR Registry created."
  fi
}

# Function to do the Route53 HostedZone ID Lookup
function getRoute53HostedZoneIDLookup() {
  # Get the domain name
  domain_name=${1}
  # Get the hosted zone id
  hosted_zone_id=$(aws route53 list-hosted-zones | jq -rc '.HostedZones[]|select(.Name == "'${domain_name}.'")')
  if [[ ! $hosted_zone_id ]]; then
    # If the hosted zone id is not found, return empty
    return
  else
    # Return the hosted zone id
    echo $hosted_zone_id | jq -r .Id | awk -F/ '{print $3}'
  fi
}

# Function to create the appropriate Route53 HostedZone and NS records in the parent domain
function createRoute53HostedZone() {
  # Get the domain name
  domain_name="${1}"
  parent_domain="$(echo ${domain_name} | cut -d'.' -f2-)" # Get the domain name without the subdomain
  parent_hosted_zone_id=$(getRoute53HostedZoneIDLookup ${parent_domain})

  # Create the Route53 Hosted Zone
  hz_create=$(aws route53 create-hosted-zone --name ${domain_name} --caller-reference $(date +%s))
  ns_records=$(echo "${hz_create}" | jq -rc '.DelegationSet.NameServers[] | {Value: .}' | jq -sc)
  # Create the data blob for the NS records
  post_data=$(
    jq -nc '{
      Changes: [
        { Action: "CREATE",
          ResourceRecordSet: {
            Name: "'${domain_name}'.",
            Type: "NS",
            TTL: 300,
            ResourceRecords: '${ns_records}'
          }
        }
      ]
    }'
  )

  # Create the NS records in the parent domain
  aws route53 change-resource-record-sets \
    --hosted-zone-id ${parent_hosted_zone_id} \
    --change-batch ${post_data} | jq -r
}

# Function to return errors for the Route53 HostedZone ID Lookup
function route53Error() {
  echo -e "\t❌ The Route53 Hosted Zone ID for \"${1}\" cannot be found."
}
