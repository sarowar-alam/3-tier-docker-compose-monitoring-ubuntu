#!/bin/bash
# Docker Installation Script for Ubuntu 22.04/20.04
# This script automates Docker and Docker Compose installation on EC2

set -e  # Exit on any error

echo "=========================================="
echo "Docker Installation Script for Ubuntu"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "⚠️  Please do not run as root. Run as ubuntu user."
    exit 1
fi

echo "Step 1: Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "Step 2: Removing old Docker versions (if any)..."
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

echo ""
echo "Step 3: Installing prerequisites..."
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

echo ""
echo "Step 4: Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo ""
echo "Step 5: Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ""
echo "Step 6: Installing Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ""
echo "Step 7: Adding current user to docker group..."
sudo usermod -aG docker $USER

echo ""
echo "Step 8: Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo ""
echo "=========================================="
echo "✅ Docker Installation Complete!"
echo "=========================================="
echo ""
docker --version
docker compose version
echo ""
echo "⚠️  IMPORTANT: Please log out and log back in for docker group changes to take effect!"
echo ""
echo "After logging back in, verify with:"
echo "  docker ps"
echo ""
echo "Next steps:"
echo "  1. Log out: exit"
echo "  2. SSH back in"
echo "  3. Clone repo: git clone https://github.com/sarowar-alam/3-tier-docker-compose-ubuntu.git"
echo "  4. Follow PHASE1-DEPLOYMENT.md"
echo ""
