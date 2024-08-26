#!/bin/bash

# Function to securely read passphrase
read_passphrase() {
  local passphrase
  local passphrase_confirm

  while true; do
    read -s -p "Enter passphrase for encryption: " passphrase
    echo

    read -s -p "Confirm passphrase: " passphrase_confirm
    echo

    if [ "$passphrase" = "$passphrase_confirm" ]; then
      echo "$passphrase"
      return 0
    else
      echo "Passphrases do not match. Please try again."
    fi
  done
}

# Check if vault directory exists
if [ ! -d "./vault" ]; then
  echo "Error: ./vault directory not found."
  exit 1
fi

# Check if vault directory is not empty
if [ -z "$(ls -A ./vault)" ]; then
  echo "Error: The vault directory is empty."
  exit 1
fi

# Count files in vault directory
files_count=$(find ./vault -type f | wc -l)

# Read passphrase from stdin if available, otherwise prompt
if [ -t 0 ]; then
  passphrase=$(read_passphrase)
else
  read -s passphrase
fi

# Verify that we got a passphrase
if [ -z "$passphrase" ]; then
  echo "Error: No passphrase provided. Exiting."
  exit 1
fi

# Generate checksum of vault directory
vault_checksum=$(find ./vault -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | cut -d' ' -f1)

# Create tar archive of vault directory
tar -czf vault_content.tar.gz ./vault

# Prepend checksum to tar archive
(
  echo -n "$vault_checksum"
  cat vault_content.tar.gz
) >vault.tar.gz
rm vault_content.tar.gz

# Encrypt tar archive (now including checksum)
echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 \
  --symmetric --cipher-algo AES256 --s2k-mode 3 --s2k-count 65011712 \
  --s2k-digest-algo SHA512 --no-symkey-cache \
  --output vault.tar.gz.gpg vault.tar.gz

# Check if encryption was successful
if [ $? -eq 0 ]; then
  echo "Encryption successful: vault.tar.gz.gpg"

  # Remove unencrypted tar file
  rm vault.tar.gz

  # Function to get file size in bytes and convert to MB
  get_file_size_in_mb() {
    local file="$1"
    local file_size_bytes
    local file_size_mb

    # Get file size in bytes using appropriate `stat` syntax for the platform
    if [[ $OSTYPE == "darwin"* ]]; then
      # macOS
      file_size_bytes=$(stat -f%z "$file")
    else
      # Linux and other Unix-like systems
      file_size_bytes=$(stat -c%s "$file")
    fi

    # Convert bytes to MB with two decimal places
    file_size_mb=$(echo "scale=2; $file_size_bytes / 1024 / 1024" | bc)

    echo "$file_size_mb"
  }

  encrypted_size=$(get_file_size_in_mb vault.tar.gz.gpg)

  printf "Files encrypted: %s\n" "$(echo "$files_count" | xargs)"
  printf "Vault archive size: %s\n" "$(echo "$encrypted_size" | xargs)mb"
  printf "Vault checksum: %s\n" "$(echo "$vault_checksum" | xargs)"
else
  echo "Encryption failed"
  exit 1
fi

