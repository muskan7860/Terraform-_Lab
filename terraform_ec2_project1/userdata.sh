#!/bin/bash

# Exit immediately if any command fails
set -e

# Log all output
exec > >(tee /var/log/user-data.log) 2>&1

echo "===== User Data Execution Started ====="

# Update package index
apt-get update -y

# Install Docker only if not already installed
if ! command -v docker >/dev/null 2>&1; then

    echo "Installing Docker..."

    apt-get install -y docker.io

    systemctl enable docker

    systemctl start docker

    usermod -aG docker ubuntu

else

    echo "Docker is already installed."

fi

echo "Docker Version:"
docker --version

echo "===== User Data Execution Completed ====="