#!/bin/bash
# Load all of the core functions from the same directory of the environment-setup script
source $(dirname ${0})/functions.sh

# Get and sign all the certificates
signClusterCSRs