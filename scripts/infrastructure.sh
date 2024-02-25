#!/bin/bash
# This script will be utilized by GitHub Actions to instantiate the Infrastructure using Pulumi

# Exit if any of the intermediate steps fail
set -e
# Load all of the core functions from the same directory of the environment-setup script
source $(dirname ${0})/functions.sh

