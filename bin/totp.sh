#!/bin/bash

# Check if oathtool is installed
if ! command -v oathtool &> /dev/null; then
  echo "Error: oathtool is not installed. Please install oath-toolkit." >&2
  exit 1
fi

# Check if a secret key is provided
if [ $# -eq 0 ]; then
  echo "Error: No secret key provided." >&2
  echo "Usage: $0 <secret_key>" >&2
  exit 1
fi

# Get the secret key from all arguments
secret_key="$*"

# Function to validate and process the secret key
validate_secret_key() {
  local secret_key="$1"
  # Remove spaces
  secret_key="${secret_key// }"
  # Convert to uppercase
  secret_key="${secret_key^^}"
  # Check if it's a valid base32 string
  if [[ $secret_key =~ ^[A-Z2-7]+={0,2}$ ]] && [[ ${#secret_key} -ge 16 ]]; then
    echo "$secret_key"
    return 0
  else
    echo "Error: Invalid secret key. It should be a base32 encoded string (with or without spaces)." >&2
    return 1
  fi
}

# Process the secret key
processed_secret=$(validate_secret_key "$secret_key")
if [ $? -ne 0 ]; then
  echo "$processed_secret" >&2
  exit 1
fi

# Generate the TOTP code
totp_code=$(oathtool --totp -b "$processed_secret")

# Print the TOTP code
echo "Your TOTP code is: $totp_code"

