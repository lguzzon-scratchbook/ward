#!/bin/bash

# Function to securely remove files
remove_securely() {
  if command -v shred >/dev/null; then
    shred -u "$1"
  else
    rm -P "$1"
  fi
}

# Prompt for passphrase
read -rs -p "Enter the passphrase for decryption: " passphrase
echo

# Create a temporary file to store the passphrase
temp_passphrase_file=$(mktemp)
echo "$passphrase" >"$temp_passphrase_file"

# Decrypt the encrypted tar archive
gpg --batch --passphrase-file "$temp_passphrase_file" --decrypt vault.tar.gz.gpg >vault_with_checksum.tar.gz

# Check if decryption was successful
if [ $? -ne 0 ]; then
  echo "Failed to decrypt archive. Exiting."
  remove_securely "$temp_passphrase_file"
  exit 1
fi

# Extract the checksum and the actual tar content
stored_checksum=$(head -c 64 vault_with_checksum.tar.gz)
tail -c +65 vault_with_checksum.tar.gz >vault.tar.gz

# Extract the tar archive
tar -xzf vault.tar.gz

# Clean up
remove_securely "$temp_passphrase_file"
remove_securely vault_with_checksum.tar.gz
remove_securely vault.tar.gz

echo "Decryption process completed."
echo "Stored checksum: $stored_checksum"

