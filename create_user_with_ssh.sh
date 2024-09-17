#!/bin/bash

# Ensure the script is being run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Variables (replace 'username' and 'ssh_comment' as needed)
USERNAME="username"
SSH_COMMENT="username"
HOME_DIR="/home/$USERNAME"
SSH_DIR="$HOME_DIR/.ssh"
KEY_PATH="$SSH_DIR/id_rsa"
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

# Step 1: Create user with specified home directory and bash shell
echo "Creating user $USERNAME..."
useradd -m -d "$HOME_DIR" -s /bin/bash "$USERNAME"

# Step 2: Create .ssh directory
echo "Creating .ssh directory for $USERNAME..."
mkdir -p "$SSH_DIR"

# Step 3: Change ownership of .ssh directory to the user
echo "Changing ownership of $SSH_DIR to $USERNAME..."
chown -R "$USERNAME:$USERNAME" "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Step 4: Switch to the new user and generate the RSA key pair
echo "Generating RSA key pair for $USERNAME..."
sudo -u "$USERNAME" ssh-keygen -t rsa -m PEM -C "$SSH_COMMENT" -f "$KEY_PATH" -N ""

# Step 5: Create and populate the authorized_keys file
echo "Setting up authorized_keys..."
sudo -u "$USERNAME" cp "$KEY_PATH.pub" "$AUTHORIZED_KEYS"

# Set proper permissions for the authorized_keys file
chmod 600 "$AUTHORIZED_KEYS"
chown "$USERNAME:$USERNAME" "$AUTHORIZED_KEYS"

echo "SSH setup for $USERNAME is complete."
