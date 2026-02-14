#!/bin/bash
# Start Application with Monitoring Stack
# This script starts both the main application and monitoring services

set -e

# Function to get EC2 public IP with IMDSv2 support
get_ec2_public_ip() {
    # Try to get token for IMDSv2
    local TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --connect-timeout 2 2>/dev/null)
    
    if [ -n "$TOKEN" ]; then
        # Use IMDSv2 with token
        local PUBLIC_IP=$(curl -s \
            -H "X-aws-ec2-metadata-token: $TOKEN" \
            --connect-timeout 2 \
            http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    else
        # Fallback to IMDSv1
        local PUBLIC_IP=$(curl -s --connect-timeout 2 \
            http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    fi
    
    # If still empty, try external service
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "localhost")
    fi
    
    # Trim whitespace and return
    echo "$PUBLIC_IP" | tr -d '[:space:]'
}

echo "=========================================="
echo "Starting BMI Health Tracker"
echo "with Full Monitoring Stack"
echo "=========================================="
echo ""

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "ERROR: docker-compose.yml not found"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "WARNING: .env file not found"
    echo "Creating from .env.example..."
    cp .env.example .env
    echo "WARNING: Please edit .env file with your configuration before proceeding"
    exit 1
fi

# Start main application
echo "[1/2] Starting main application stack..."
docker compose up -d

echo ""
echo "Waiting for application to become healthy..."
sleep 20

# Check application health
if docker compose ps | grep -q "healthy"; then
    echo "SUCCESS: Application is healthy"
else
    echo "WARNING: Application may not be fully ready yet"
fi

echo ""
echo "[2/2] Starting monitoring stack..."
docker compose -f docker-compose.monitoring.yml up -d

echo ""
echo "Waiting for monitoring services to start..."
sleep 15

# Display status
echo ""
echo "=========================================="
echo "Service Status"
echo "=========================================="
echo ""
echo "Main Application:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "Monitoring Stack:"
docker compose -f docker-compose.monitoring.yml ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=========================================="
echo "All Services Started Successfully!"
echo "=========================================="
echo ""

# Get public IP
PUBLIC_IP=$(get_ec2_public_ip)

echo "Access URLs:"
echo "  Application:    http://${PUBLIC_IP}"
echo "  Grafana:        http://${PUBLIC_IP}:3001 (admin/admin)"
echo "  Prometheus:     http://${PUBLIC_IP}:9090"
echo "  Backend Health: http://${PUBLIC_IP}:3000/health"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo "  docker compose -f docker-compose.monitoring.yml logs -f grafana"
echo ""
echo "Stop all services:"
echo "  docker compose down"
echo "  docker compose -f docker-compose.monitoring.yml down"
echo ""
