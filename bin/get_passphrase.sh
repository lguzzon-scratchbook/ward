#!/bin/bash

# Check if the passphrase is stored in an environment variable
if [ -n "${WARD_PASSPHRASE-}" ]; then
  echo "${WARD_PASSPHRASE}"
  exit 0
fi

# If not, and we're in an interactive environment, prompt the user
if [ -t 0 ]; then
  read -r -s -p "Enter the passphrase for encryption: " passphrase
  echo
  echo "${passphrase}"
else
  echo "Error: WARD_PASSPHRASE environment variable not set in non-interactive mode." >&2
  exit 1
fi

