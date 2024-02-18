#!/bin/bash
set -e
## MacOS Provisioning Script
# This script is used to setup a new MacOS environment for development.
# We'll make sure that all of the required tools and resources are
# available on your local machine and ready to go.

# Load all of the core functions from the same directory of the environment-setup script
source $(dirname ${0})/functions.sh

# List of required tools
tools=(
  "age"
  "aws,awscli" # awscli is the name for the brew package, whereas aws is the name of the command line tool
  "gh"
  "git"
  "helm"
  "jq"
  "kubectl"
  "node"
  "openssl"
  "talhelper"
  "talosctl,talosctl,siderolabs/talos" # talosctl is the name of the tool and what needs to be installed,
  # siderolabs/talos is the git repo that needs to be tapped prior to attempting to install the tool
  "yarn"
)

# List of required environment variables
required_env_vars=(
  "GitHub_Username"
  "AWS_Account_ID"
)

# Check if the required tools are installed
echo "🔧 Checking if the required tools are installed..."
for tool in "${tools[@]}"; do
  checkToolInstalled $tool
done

# Ensure that the github cli is logged in
echo "🔧 Setting up the GitHub CLI..."
setGitHubCLIValues

# Have the user input all of their required environment variables
echo "🔧 Setting up the required values..."
# Check if the user is already authenticated with GitHub and has a username set
if [[ $(gh api user | jq -r .login) != "null" ]]; then
  GitHub_Username=$(gh api user | jq -r .login)
fi
# Get the current AWS Account ID
if aws sts get-caller-identity >/dev/null 2>&1; then
  AWS_Account_ID=$(aws sts get-caller-identity | jq -r .Account)
fi
# Check all required environment variables and ask the user to input them if not already set
for user_input in "${required_env_vars[@]}"; do
  parseUserInput $user_input
done

# Check that everything looks good to the user; get confirmation
echo "🔍 Please review the following required values:"
checkUserInput "${required_env_vars[@]}"

# Check if the users Sealed Secrets Keypair exists
echo "🔐 Checking if the Sealed Secrets Keypair exists..."
createSealedSecretsKeypair

# Check if the users age Keypair exists
echo "🔐 Checking if the age Keypair exists..."
createAgeKeypair

# Check if the user has their .sops.yaml file configured
echo "🔐 Checking if the .sops.yaml file exists..."
createSopsConfig

# Encrypting our Sealed Secrets Key
echo "🔐 Encrypting the Sealed Secrets Key..."
encryptSealedSecretsKey

# Get the current list of repository secrets
echo "🔑 Listing the current repository secrets..."
# listGitHubRepoSecrets $GitHub_Username
createGitHubRepoSecrets $GitHub_Username
