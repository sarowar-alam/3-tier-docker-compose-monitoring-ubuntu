# Phase 1: Deploy Three-Tier Application with Docker Compose

This guide walks you through manually deploying the BMI Health Tracker application on AWS EC2 Ubuntu using Docker Compose. You'll learn each step hands-on before automating in later phases.

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│           AWS EC2 Ubuntu Instance           │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │       Docker Compose Stack           │  │
│  │                                      │  │
│  │  ┌──────────┐    ┌──────────┐      │  │
│  │  │ Frontend │    │ Backend  │      │  │
│  │  │  Nginx   │◄───│ Node.js  │      │  │
│  │  │  React   │    │ Express  │      │  │
│  │  └────┬─────┘    └────┬─────┘      │  │
│  │       │               │             │  │
│  │     Port 80      Port 3000          │  │
│  │       │               │             │  │
│  │       │          ┌────▼─────┐       │  │
│  │       │          │PostgreSQL│       │  │
│  │       │          │   :5432  │       │  │
│  │       │          └──────────┘       │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

---

## Prerequisites

### 1. AWS EC2 Instance Requirements
- **OS**: Ubuntu 22.04 LTS (or 20.04 LTS)
- **Instance Type**: Minimum t2.small (1 vCPU, 2GB RAM)
  - Recommended: t2.medium (2 vCPU, 4GB RAM) for better performance
- **Storage**: Minimum 20GB SSD
- **Elastic IP**: Recommended for stable access

### 2. Security Group Configuration
Configure your EC2 Security Group with these inbound rules:

| Type       | Port | Source      | Purpose              |
|------------|------|-------------|----------------------|
| SSH        | 22   | Your IP     | Remote access        |
| HTTP       | 80   | 0.0.0.0/0   | Application access   |
| Custom TCP | 3001 | Your IP     | Grafana (Phase 2)    |

### 3. SSH Key Pair
- Have your `.pem` key file ready for SSH access
- Set permissions: `chmod 400 your-key.pem` (Linux/Mac)

---

## Step 1: Connect to EC2 Instance

### From Windows (PowerShell)
```powershell
ssh -i "path\to\your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### From Linux/Mac
```bash
ssh -i "path/to/your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

**Replace `YOUR_EC2_PUBLIC_IP`** with your actual EC2 public IP address.

---

## Step 2: Update System Packages

Once connected to EC2, update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

This ensures all packages are up to date.

---

## Step 3: Install Docker

### Install Docker Engine

```bash
# Remove old versions (if any)
sudo apt remove docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

**Expected output:**
```
Docker version 24.x.x, build xxxxx
Docker Compose version v2.x.x
```

### Add User to Docker Group

This allows running Docker without `sudo`:

```bash
sudo usermod -aG docker $USER
```

**Important:** Log out and log back in for this to take effect!

```bash
exit
# Then SSH back in
ssh -i "path/to/your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

Verify you can run Docker without sudo:
```bash
docker ps
```

---

## Step 4: Clone the Repository

```bash
cd ~
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu
```

Verify files are present:
```bash
ls -la
```

You should see:
- `backend/` - Backend API code
- `frontend/` - Frontend React code
- `database/` - Database initialization scripts
- `docker-compose.yml` - Main orchestration file
- `.env.example` - Environment template

---

## Step 5: Configure Environment Variables

### Create Environment File

```bash
cp .env.example .env
```

### Edit the Environment File

```bash
nano .env
```

Update these values:

```env
# PostgreSQL Configuration
POSTGRES_USER=bmi_user
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
POSTGRES_DB=bmidb

# Application Configuration
NODE_ENV=production

# Frontend URL - set to your EC2 public IP
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP
```

**Important Configuration Notes:**

1. **POSTGRES_PASSWORD**: Replace with a strong password (min 16 characters, mix of letters, numbers, symbols)
   - Example: `Str0ng!P@ssw0rd#2026`
   - **Never commit this to git!**

2. **FRONTEND_URL**: Replace `YOUR_EC2_PUBLIC_IP` with your actual EC2 public IP
   - Example: `FRONTEND_URL=http://54.123.45.67`
   - This is needed for CORS configuration

**Save and exit:**
- Press `Ctrl + X`
- Press `Y` to confirm
- Press `Enter` to save

### Verify Configuration

```bash
cat .env
```

Make sure all values are properly set (passwords should be hidden when you share this output).

---

## Step 6: Build Docker Images

Build all three services (this may take 5-10 minutes):

```bash
docker compose build
```

**What's happening:**
- Building backend Node.js image (~2-3 minutes)
- Building frontend React + Nginx image (~3-5 minutes)
- Pulling PostgreSQL 14 alpine image (~1 minute)

**Expected output:**
```
[+] Building 234.5s (25/25) FINISHED
 => [backend internal] load build definition
 => [frontend internal] load build definition
 ...
```

### Verify Images

```bash
docker images
```

You should see:
```
REPOSITORY                    TAG       SIZE
3-tier-docker-compose-backend latest    ~200MB
3-tier-docker-compose-frontend latest   ~50MB
postgres                      14-alpine ~230MB
```

---

## Step 7: Start the Application

### Start All Services

```bash
docker compose up -d
```

The `-d` flag runs containers in detached mode (background).

**Expected output:**
```
[+] Running 3/3
 ✔ Container bmi-postgres   Started
 ✔ Container bmi-backend    Started
 ✔ Container bmi-frontend   Started
```

### Wait for Health Checks

Services have health checks configured. Wait about 30-60 seconds for all to become healthy.

---

## Step 8: Verify Deployment

### Check Container Status

```bash
docker compose ps
```

**Expected output (all should show "healthy"):**
```
NAME             IMAGE                              STATUS
bmi-postgres     postgres:14-alpine                 Up (healthy)
bmi-backend      3-tier-docker-compose-backend      Up (healthy)
bmi-frontend     3-tier-docker-compose-frontend     Up (healthy)
```

If status shows "starting" or "unhealthy", wait a bit longer or check logs (see troubleshooting).

### Test Backend Health Endpoint

```bash
curl http://localhost:3000/health
```

**Expected output:**
```json
{"status":"healthy","timestamp":"2026-02-14T..."}
```

### Test Frontend

```bash
curl -I http://localhost
```

**Expected output:**
```
HTTP/1.1 200 OK
Server: nginx
...
```

### Test Database Connection

```bash
docker compose exec postgres psql -U bmi_user -d bmidb -c "\dt"
```

**Expected output (list of tables):**
```
              List of relations
 Schema |     Name      | Type  |  Owner
--------+---------------+-------+----------
 public | measurements  | table | bmi_user
```

---

## Step 9: Access the Application

### From Your Browser

1. Open browser and navigate to:
   ```
   http://YOUR_EC2_PUBLIC_IP
   ```

2. You should see the BMI Health Tracker interface

3. Test the application:
   - Enter weight, height, age, sex, activity level
   - Click "Calculate"
   - View results with BMI, BMR, and daily calorie needs
   - Check that data persists (refresh page, data should still be there)

---

## Step 10: Monitor Logs (Optional)

### View All Logs

```bash
docker compose logs -f
```

Press `Ctrl + C` to exit.

### View Specific Service Logs

```bash
# Backend logs
docker compose logs -f backend

# Frontend logs
docker compose logs -f frontend

# Database logs
docker compose logs -f postgres
```

---

## Common Commands Reference

### Service Management

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# Restart services
docker compose restart

# Rebuild and start
docker compose up -d --build

# View status
docker compose ps

# View logs
docker compose logs -f [service-name]
```

### Container Management

```bash
# List all containers
docker ps -a

# Execute command in container
docker compose exec [service] [command]

# Example: Access PostgreSQL shell
docker compose exec postgres psql -U bmi_user -d bmidb

# Example: Access backend shell
docker compose exec backend sh
```

### Cleanup

```bash
# Stop and remove containers (keeps volumes)
docker compose down

# Stop and remove everything including volumes (DATA LOSS!)
docker compose down -v

# Remove unused images
docker image prune -a
```

---

## Troubleshooting

### Issue: Container shows "unhealthy"

**Check logs:**
```bash
docker compose logs backend
```

**Common causes:**
- Database not ready yet (wait 1-2 minutes)
- Wrong environment variables
- Port conflicts

### Issue: Cannot connect from browser

**Check EC2 Security Group:**
- Ensure port 80 is open to 0.0.0.0/0
- Verify you're using the correct public IP (not private IP)

**Check if services are running:**
```bash
docker compose ps
curl http://localhost
```

### Issue: Database connection errors

**Verify environment variables:**
```bash
cat .env
```

**Check database is ready:**
```bash
docker compose exec postgres pg_isready -U bmi_user -d bmidb
```

**Restart services:**
```bash
docker compose restart backend
```

### Issue: "No space left on device"

**Check disk space:**
```bash
df -h
```

**Clean up Docker:**
```bash
docker system prune -a --volumes
```

### Issue: Permission denied errors

**Ensure user is in docker group:**
```bash
groups $USER
```

Should show "docker" in the list. If not:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue: Port already in use

**Check what's using port 80:**
```bash
sudo lsof -i :80
```

**Stop conflicting service (if Apache/Nginx installed):**
```bash
sudo systemctl stop apache2  # or nginx
sudo systemctl disable apache2
```

---

## Data Persistence

### Database Data

Database data is stored in Docker volume `bmi-postgres-data`. This persists even when containers are stopped or rebuilt.

**View volumes:**
```bash
docker volume ls
```

**Backup database:**
```bash
docker compose exec postgres pg_dump -U bmi_user bmidb > backup_$(date +%Y%m%d_%H%M%S).sql
```

**Restore database:**
```bash
cat backup_file.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb
```

---

## Security Best Practices

1. **Never commit `.env` file to git**
   - It's already in `.gitignore`
   - Contains sensitive passwords

2. **Use strong passwords**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols

3. **Restrict Security Group access**
   - Port 22 (SSH): Only your IP
   - Port 3001 (Grafana): Only your IP
   - Port 80 (HTTP): Public (0.0.0.0/0)

4. **Keep system updated**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

5. **Enable EC2 CloudWatch monitoring**
   - Monitor CPU, disk, network usage
   - Set up alarms for high resource usage

---

## Performance Optimization

### Increase Container Resources

If running on larger instance, allocate more resources in `docker-compose.yml`:

```yaml
backend:
  deploy:
    resources:
      limits:
        cpus: '1.0'
        memory: 1G
      reservations:
        memory: 512M
```

### Enable Connection Pooling (Already configured)

Backend already uses PostgreSQL connection pooling (max 20 connections).

---

## Next Steps

✅ **Phase 1 Complete!** Your three-tier application is now running on EC2 with Docker Compose.

**What you've accomplished:**
- Dockerized a three-tier application
- Deployed to AWS EC2
- Configured networking and persistence
- Learned Docker Compose fundamentals

**Ready for Phase 2:**
- Add comprehensive monitoring (Prometheus, Grafana, Loki)
- Visualize application metrics
- Centralized logging
- Container health monitoring

📚 **Next Guide:** `PHASE2-MONITORING.md` (coming after git push)

---

## Quick Reference: Complete Deployment Flow

```bash
# 1. Connect to EC2
ssh -i "key.pem" ubuntu@YOUR_EC2_IP

# 2. Install Docker
# ... (see Step 3 for full commands)

# 3. Clone repo
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 4. Configure
cp .env.example .env
nano .env  # Edit values

# 5. Deploy
docker compose build
docker compose up -d

# 6. Verify
docker compose ps
curl http://localhost:3000/health

# 7. Access from browser
# http://YOUR_EC2_IP
```

---

## Support

**Common Issues:** See Troubleshooting section above

**GitHub Issues:** https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/issues

**Check logs for errors:**
```bash
docker compose logs -f
```

---

**Happy Dockerizing! 🐳**
