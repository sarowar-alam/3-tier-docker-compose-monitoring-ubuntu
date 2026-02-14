#!/bin/bash
#
# Setup GitHub Self-Hosted Runner on Ubuntu EC2
# This script installs and configures a GitHub Actions runner
#

set -e

echo "=========================================="
echo "GitHub Self-Hosted Runner Setup"
echo "=========================================="

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo "ERROR: Please run as ubuntu user"
    exit 1
fi

# Create actions-runner directory
cd ~
mkdir -p actions-runner
cd actions-runner

# Download latest runner
echo ""
echo "Downloading GitHub Actions Runner..."
RUNNER_VERSION="2.311.0"
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Extract runner
echo "Extracting..."
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

echo ""
echo "=========================================="
echo "Runner downloaded successfully!"
echo "=========================================="
echo ""
echo "NEXT STEPS:"
echo ""
echo "1. Go to your GitHub repository:"
echo "   https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners/new"
echo ""
echo "2. Copy the token shown there"
echo ""
echo "3. Run the configuration:"
echo "   cd ~/actions-runner"
echo "   ./config.sh --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu --token YOUR_TOKEN"
echo ""
echo "4. When prompted:"
echo "   - Runner name: ec2-ubuntu-runner"
echo "   - Labels: self-hosted,Linux,X64,aws-ec2"
echo "   - Work folder: _work (default)"
echo ""
echo "5. Install and start as service:"
echo "   sudo ./svc.sh install"
echo "   sudo ./svc.sh start"
echo ""
echo "6. Check status:"
echo "   sudo ./svc.sh status"
echo ""
echo "=========================================="
