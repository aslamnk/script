#!/bin/bash

# Define the public and private key paths
PRIVATE_KEY_PATH="$HOME/.ssh/id_rsa"
PUB_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# Force SSH key reset by generating a new RSA key pair
echo "Forcing SSH key reset..."
if [ -f "$PRIVATE_KEY_PATH" ]; then
    rm -f "$PRIVATE_KEY_PATH" "$PUB_KEY_PATH"
    echo "Existing SSH key pair removed."
fi

# Generate a new RSA key pair
ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N ""
echo "New SSH key pair generated."

# Calculate the expiry time 90 days from now in the format YYYYMMDDHHMMSSZ
EXPIRY_TIME=$(date -u -d "90 days" +"%Y%m%d%H%M%SZ")

# Read the public key content
PUBLIC_KEY_CONTENT=$(cat "$PUB_KEY_PATH")

# Define the full entry with the expiry time
FULL_ENTRY="expiry-time=\"$EXPIRY_TIME\" $PUBLIC_KEY_CONTENT"

# Define the authorized_keys file path
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"
BACKUP_FILE="$HOME/.ssh/authorized_keys.bak"

# Backup the current authorized_keys file if it exists
if [ -f "$AUTHORIZED_KEYS_FILE" ]; then
    mv "$AUTHORIZED_KEYS_FILE" "$BACKUP_FILE"
    echo "Existing authorized_keys file renamed to authorized_keys.bak."
fi

# Add the new key with the expiry command
echo "$FULL_ENTRY" > "$AUTHORIZED_KEYS_FILE"
echo "The key has been added to the authorized_keys file with an expiry time of $EXPIRY_TIME."

# Prompt for the user's email directly
read -p "Enter your email address: " USER_EMAIL

# Define the user info file path
USER_EMAIL_FILE="/home/user_expiry_info.txt"  # Replace with the actual path
USERNAME=$(whoami)

# Remove any existing entry for the user to prevent duplicates
grep -v "^$USERNAME:" "$USER_EMAIL_FILE" > "$USER_EMAIL_FILE.tmp" && mv "$USER_EMAIL_FILE.tmp" "$USER_EMAIL_FILE"

# Write the username, expiry time, and email to the file, preserving existing data
echo "$USERNAME:$EXPIRY_TIME:$USER_EMAIL" >> "$USER_EMAIL_FILE"
echo "Username and expiry time updated in $USER_EMAIL_FILE."

