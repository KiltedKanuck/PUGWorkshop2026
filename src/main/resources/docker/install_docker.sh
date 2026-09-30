#!/bin/bash
# install_docker.sh
# This script installs Docker CE and CLI on Ubuntu

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run as root or use sudo" >&2
    exit 1
fi

# Update package lists and install dependencies
apt update && apt upgrade -y
apt install -y ca-certificates curl gnupg lsb-release unzip

# Add Docker's official GPG key
install -m 0755 -d /usr/share/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
chmod a+r /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list

# Install Docker CE and CLI and required plugins
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
docker --version

# Add user to Docker group
newgrp docker
usermod -aG docker $USER

# Configure networking for Docker
update-alternatives --set iptables /usr/sbin/iptables-legacy

echo "Docker installation complete. Please restart your session for changes to take effect."
