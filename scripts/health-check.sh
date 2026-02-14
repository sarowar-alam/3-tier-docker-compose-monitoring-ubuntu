#!/bin/bash
# Health Check Script for Docker Compose Application
# Verifies all services are running correctly

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
        PUBLIC_IP=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "YOUR_EC2_IP")
    fi
    
    # Trim whitespace and return
    echo "$PUBLIC_IP" | tr -d '[:space:]'
}

echo "=========================================="
echo "Docker Compose Health Check"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if docker compose is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}ERROR: docker-compose.yml not found in current directory${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

echo "Checking Docker Compose services..."
echo ""

# Check container status
echo "1. Container Status:"
docker compose ps
echo ""

# Check if all containers are running
RUNNING=$(docker compose ps -q | wc -l)
TOTAL=3

if [ $RUNNING -eq $TOTAL ]; then
    echo -e "${GREEN}SUCCESS: All $TOTAL containers are running${NC}"
else
    echo -e "${YELLOW}WARNING: Only $RUNNING out of $TOTAL containers are running${NC}"
fi
echo ""

# Check backend health endpoint
echo "2. Backend Health Check:"
if curl -s -f http://localhost:3000/health > /dev/null 2>&1; then
    HEALTH=$(curl -s http://localhost:3000/health)
    echo -e "${GREEN}SUCCESS: Backend is healthy${NC}"
    echo "Response: $HEALTH"
else
    echo -e "${RED}ERROR: Backend health check failed${NC}"
fi
echo ""

# Check frontend accessibility
echo "3. Frontend Accessibility:"
if curl -s -f http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS: Frontend is accessible${NC}"
else
    echo -e "${RED}ERROR: Frontend is not accessible${NC}"
fi
echo ""

# Check database connection
echo "4. Database Connection:"
if docker compose exec -T postgres pg_isready -U bmi_user -d bmidb > /dev/null 2>&1; then
    echo -e "${GREEN}SUCCESS: Database is ready${NC}"
    
    # Count records
    COUNT=$(docker compose exec -T postgres psql -U bmi_user -d bmidb -t -c "SELECT COUNT(*) FROM measurements;" 2>/dev/null | tr -d ' ')
    echo "Records in database: $COUNT"
else
    echo -e "${RED}ERROR: Database is not ready${NC}"
fi
echo ""

# Check volumes
echo "5. Docker Volumes:"
docker volume ls | grep bmi
echo ""

# Check networks
echo "6. Docker Networks:"
docker network ls | grep bmi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Final recommendation
if [ $RUNNING -eq $TOTAL ]; then
    echo -e "${GREEN}SUCCESS: All checks passed! Application is healthy.${NC}"
    echo ""
    echo "Access your application at:"
    echo "  http://$(get_ec2_public_ip)"
else
    echo -e "${YELLOW}WARNING: Some services may need attention.${NC}"
    echo ""
    echo "View logs with:"
    echo "  docker compose logs -f"
fi
echo ""
