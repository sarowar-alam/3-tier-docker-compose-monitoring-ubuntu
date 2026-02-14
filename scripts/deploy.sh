#!/bin/bash
# Deployment Script for EC2
# Can be run manually or triggered by CI/CD

set -e

# Configuration
PROJECT_DIR="${HOME}/3-tier-docker-compose-monitoring-ubuntu"
BACKUP_DIR="${PROJECT_DIR}/backups"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=========================================="
echo "🚀 Deployment Script"
echo "=========================================="
echo ""

# Check if running in project directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml not found${NC}"
    echo "Please run this script from the project directory"
    exit 1
fi

# Backup database before deployment
echo -e "${BLUE}📦 Creating database backup...${NC}"
if [ -f "./scripts/backup-database.sh" ]; then
    bash ./scripts/backup-database.sh || echo -e "${YELLOW}⚠️  Backup failed, continuing...${NC}"
fi

# Pull latest code
echo ""
echo -e "${BLUE}📥 Pulling latest code from GitHub...${NC}"
git fetch origin
git pull origin main

# Pull latest images
echo ""
echo -e "${BLUE}🐳 Pulling latest Docker images...${NC}"
docker compose pull || echo -e "${YELLOW}⚠️  No pre-built images, will build locally${NC}"

# Stop services gracefully
echo ""
echo -e "${BLUE}🛑 Stopping services gracefully...${NC}"
docker compose down --timeout 30

# Start services
echo ""
echo -e "${BLUE}🚀 Starting services...${NC}"
docker compose up -d --build

# Wait for health checks
echo ""
echo -e "${BLUE}⏳ Waiting for services to become healthy...${NC}"
sleep 15

# Check service status
echo ""
echo -e "${BLUE}📊 Service Status:${NC}"
docker compose ps

# Verify health
echo ""
echo -e "${BLUE}🏥 Verifying health...${NC}"

HEALTHY=true

# Check backend
if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    HEALTHY=false
fi

# Check frontend
if curl -sf http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is accessible${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
    HEALTHY=false
fi

# Check database
if docker compose exec -T postgres pg_isready -U bmi_user -d bmidb > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is ready${NC}"
else
    echo -e "${RED}❌ Database is not ready${NC}"
    HEALTHY=false
fi

echo ""

if [ "$HEALTHY" = true ]; then
    echo "=========================================="
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
    echo "=========================================="
    echo ""
    echo "Application URLs:"
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "YOUR_EC2_IP")
    echo "  Application: http://${PUBLIC_IP}"
    echo "  Grafana: http://${PUBLIC_IP}:3001"
    echo ""
else
    echo "=========================================="
    echo -e "${RED}⚠️  Deployment completed with issues${NC}"
    echo "=========================================="
    echo ""
    echo "Check logs with: docker compose logs -f"
    echo ""
    exit 1
fi

# Clean up old images
echo "🧹 Cleaning up old Docker images..."
docker image prune -af --filter "until=24h" > /dev/null 2>&1 || true

echo ""
echo "Deployment timestamp: $(date)"
echo ""
