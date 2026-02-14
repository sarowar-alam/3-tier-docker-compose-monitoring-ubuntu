# Complete Deployment Guide - All Phases

This guide walks you through deploying the entire BMI Health Tracker application with monitoring and CI/CD automation on AWS EC2.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **AWS Account** with EC2 access
- [ ] **EC2 Instance** - Ubuntu 22.04, t2.medium minimum, with Elastic IP
- [ ] **Security Group** configured:
  - Port 22 (SSH) - Your IP
  - Port 80 (HTTP) - 0.0.0.0/0
  - Port 3001 (Grafana) - Your IP
  - Port 9090 (Prometheus) - Your IP (optional)
- [ ] **SSH Key Pair** (.pem file) for EC2 access
- [ ] **GitHub Account** with repository created
- [ ] **Docker Hub Account** (free) - for Phase 3
- [ ] **Git installed** on your local machine

## 🚀 Deployment Overview

```
Phase 1: Application (2 hours)
  └─> Three-tier app running on EC2
       
Phase 2: Monitoring (45 minutes)
  └─> Full observability stack added
       
Phase 3: CI/CD (1 hour)
  └─> Automated deployment pipeline
```

**Total time: ~4 hours** to production-ready deployment

---

## Phase 1: Deploy Application

### Step 1.1: Prepare Local Repository

**On your Windows machine:**

```powershell
# Navigate to project
cd "c:\CLOUD\OneDrive - Hogarth Worldwide\Documents\Ostad\Batch-08\module-10\3-tier-app-docker-compose"

# Initialize git if not already done
git init

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Three-tier Docker application with monitoring and CI/CD"

# Add remote repository
git remote add origin https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git

# Push to GitHub
git push -u origin main
```

### Step 1.2: Connect to EC2

```powershell
# From Windows PowerShell
ssh -i "C:\path\to\your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### Step 1.3: Install Docker on EC2

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Run Docker installation script
curl -fsSL https://get.docker.com | sudo sh

# Install Docker Compose plugin
sudo apt install -y docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version

# Log out and back in for group changes
exit
```

**Log back in:**
```powershell
ssh -i "C:\path\to\your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP
```

### Step 1.4: Clone Repository

```bash
cd ~
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu
```

### Step 1.5: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Update these values:**
```env
POSTGRES_USER=bmi_user
POSTGRES_PASSWORD=YourSecurePassword123!  # Change this!
POSTGRES_DB=bmidb
NODE_ENV=production
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP    # Your actual IP!
```

**Save:** Ctrl+X, Y, Enter

### Step 1.6: Build and Deploy

```bash
# Build Docker images (takes 5-10 minutes first time)
docker compose build

# Start all services
docker compose up -d

# Wait for services to become healthy (~30 seconds)
sleep 30

# Check status
docker compose ps
```

**Expected output:**
```
NAME             STATUS
bmi-postgres     Up (healthy)
bmi-backend      Up (healthy)
bmi-frontend     Up (healthy)
```

### Step 1.7: Verify Application

```bash
# Test backend
curl http://localhost:3000/health

# Test frontend
curl http://localhost

# Test from browser
# Navigate to: http://YOUR_EC2_PUBLIC_IP
```

**✅ Phase 1 Complete!** Application is running.

**Test the app:**
1. Open browser: `http://YOUR_EC2_PUBLIC_IP`
2. Enter weight, height, age, sex, activity level
3. Click Calculate
4. View BMI, BMR, and calorie results
5. Check data persists (refresh page)

---

## Phase 2: Add Monitoring

### Step 2.1: Verify Phase 1 is Healthy

```bash
# On EC2
cd ~/3-tier-docker-compose-monitoring-ubuntu
docker compose ps
```

All three services should show "healthy"

### Step 2.2: Update Security Group

Add port 3001 for Grafana:

**AWS Console:**
1. EC2 → Security Groups → Your SG
2. Edit inbound rules → Add rule
3. Type: Custom TCP, Port: 3001, Source: My IP
4. Save

### Step 2.3: Start Monitoring Stack

```bash
# Start monitoring services
docker compose -f docker-compose.monitoring.yml up -d

# Wait for services to start
sleep 20

# Check status
docker compose -f docker-compose.monitoring.yml ps
```

**Expected output:**
```
NAME              STATUS
grafana           Up (healthy)
prometheus        Up (healthy)
loki              Up (healthy)
promtail          Up
cadvisor          Up
node-exporter     Up
```

### Step 2.4: Access Grafana

**Open browser:**
```
http://YOUR_EC2_PUBLIC_IP:3001
```

**Login:**
- Username: `admin`
- Password: `admin`
- Change password when prompted (or skip)

### Step 2.5: Explore Dashboards

1. Click **Dashboards** (left sidebar)
2. Click **Browse**
3. Two dashboards are pre-loaded:
   - **Docker Container Monitoring** - CPU, memory, network metrics
   - **Application Logs** - Real-time log viewer

**Try the Container Monitoring dashboard:**
- See CPU usage per container
- Monitor memory consumption
- Track network I/O
- All updating in real-time!

**Try the Logs dashboard:**
- View live logs from all containers
- Search for errors
- Filter by container name

### Step 2.6: Test Log Queries

1. Click **Explore** (compass icon)
2. Select **Loki** data source
3. Try queries:

```logql
# All application logs
{container_name=~"bmi-.*"}

# Backend only
{container_name="bmi-backend"}

# Search for errors
{container_name=~"bmi-.*"} |~ "error"
```

**✅ Phase 2 Complete!** Full monitoring is active.

**What you can now do:**
- Monitor container resource usage
- View real-time application logs
- Track system metrics (CPU, memory, disk)
- Troubleshoot issues with centralized logging
- See application performance trends

---

## Phase 3: Enable CI/CD Automation

### Step 3.1: Create Docker Hub Account

1. Go to [hub.docker.com/signup](https://hub.docker.com/signup)
2. Sign up (free account)
3. Verify email
4. Log in

### Step 3.2: Create Docker Hub Repositories

**Create backend repository:**
1. Click **Create Repository**
2. Name: `bmi-backend`
3. Visibility: **Public**
4. Description: "BMI Health Tracker - Backend API"
5. Click **Create**

**Create frontend repository:**
1. Click **Create Repository**
2. Name: `bmi-frontend`
3. Visibility: **Public**
4. Description: "BMI Health Tracker - Frontend React App"
5. Click **Create**

### Step 3.3: Generate Docker Hub Token

1. Click your username → **Account Settings**
2. Click **Security** tab
3. Click **New Access Token**
4. Description: `GitHub Actions CI/CD`
5. Permissions: **Read, Write, Delete**
6. Click **Generate**
7. **COPY THE TOKEN** - save it safely!

### Step 3.4: Add GitHub Secrets

Go to your GitHub repository:
```
https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu
```

**Navigate to:**
Settings → Secrets and variables → Actions → New repository secret

**Add these 5 secrets:**

| Secret Name | Value | Example |
|-------------|-------|---------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | `sarowaralam` |
| `DOCKERHUB_TOKEN` | Token from Step 3.3 | `dckr_pat_ABC123...` |
| `EC2_HOST` | Your EC2 public IP | `54.123.45.67` |
| `EC2_USER` | EC2 username | `ubuntu` |
| `EC2_SSH_KEY` | Your private key content | (entire .pem file) |

**Get EC2_SSH_KEY content:**

Windows (PowerShell):
```powershell
Get-Content "C:\path\to\your-key.pem"
```

Linux/Mac:
```bash
cat ~/.ssh/your-key.pem
```

Copy **entire** content including `-----BEGIN` and `-----END` lines.

### Step 3.5: Test CI/CD Pipeline

**On your Windows machine:**

```powershell
cd "c:\CLOUD\OneDrive - Hogarth Worldwide\Documents\Ostad\Batch-08\module-10\3-tier-app-docker-compose"

# Make a small test change
echo "# CI/CD Test" >> CICD-TEST.txt

# Commit and push
git add .
git commit -m "test: CI/CD pipeline test"
git push origin main
```

### Step 3.6: Watch GitHub Actions

1. Go to GitHub → **Actions** tab
2. You'll see workflow running: **Build and Push Docker Images**
3. Click on it to watch progress
4. Two jobs run in parallel:
   - build-backend (~3-5 min)
   - build-frontend (~3-5 min)

**Wait for green checkmarks ✅**

### Step 3.7: Verify Images on Docker Hub

1. Go to [hub.docker.com](https://hub.docker.com)
2. Check your repositories:
   - `YOUR_USERNAME/bmi-backend:latest` ✅
   - `YOUR_USERNAME/bmi-frontend:latest` ✅

### Step 3.8: Trigger Deployment

**In GitHub → Actions:**

1. Click **Deploy to AWS EC2** workflow
2. Click **Run workflow** button
3. Select `production`
4. Click **Run workflow**

**Watch deployment (~3 minutes):**
- Connects to EC2 via SSH
- Pulls latest code
- Pulls latest images from Docker Hub
- Restarts containers
- Performs health checks

**Wait for green checkmark ✅**

### Step 3.9: Verify on EC2

```bash
# On EC2
cd ~/3-tier-docker-compose-monitoring-ubuntu

# Check latest commit
git log -1

# Verify images are from Docker Hub
docker images | grep bmi
```

### Step 3.10: Test End-to-End Automation

**Make a real code change:**

Edit `backend/src/server.js`:

```javascript
// Find health endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0',  // Add this line
    environment: process.env.NODE_ENV  // Add this line
  });
});
```

**Commit and push:**

```powershell
git add backend/src/server.js
git commit -m "feat: add version info to health endpoint"
git push origin main
```

**Watch magic happen:**
1. GitHub Actions builds images (~5 min)
2. Pushes to Docker Hub
3. Deploys to EC2 automatically (~3 min)
4. **Total: ~8 minutes from push to live!**

**Verify change is live:**

```bash
curl http://YOUR_EC2_IP:3000/health
```

Should show your new version field!

**✅ Phase 3 Complete!** Full CI/CD automation is active.

**What you can now do:**
- Push code → automatic deployment (~8 min)
- Zero-downtime rolling updates
- Git-based rollback (revert commit)
- Pre-built images on Docker Hub
- Consistent deployments every time

---

## 🎉 Congratulations!

You've deployed a **production-ready three-tier application** with:

### ✅ Complete Infrastructure:
- Dockerized React frontend
- Dockerized Node.js backend
- Dockerized PostgreSQL database
- Network isolation for security
- Persistent data storage

### ✅ Full Observability:
- Prometheus for metrics
- Grafana dashboards
- Loki for log aggregation
- Real-time container monitoring
- System metrics tracking

### ✅ Enterprise CI/CD:
- Automated builds on every push
- Docker Hub image registry
- Automated EC2 deployments
- Zero-downtime updates
- Health check verification
- Git-based version control

---

## 📊 Your Complete Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  AWS EC2 Ubuntu Instance                │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │           Application Stack (Phase 1)             │ │
│  │                                                   │ │
│  │  ┌──────────┐    ┌──────────┐    ┌─────────┐   │ │
│  │  │ Frontend │───▶│ Backend  │───▶│Database │   │ │
│  │  │  Nginx   │    │ Node.js  │    │PostgreSQL│  │ │
│  │  │  :80     │    │  :3000   │    │  :5432  │   │ │
│  │  └──────────┘    └──────────┘    └─────────┘   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │          Monitoring Stack (Phase 2)               │ │
│  │                                                   │ │
│  │  ┌─────────┐  ┌──────────┐  ┌────┐  ┌─────────┐│ │
│  │  │ Grafana │◀─│Prometheus│◀─│Loki│◀─│Promtail ││ │
│  │  │  :3001  │  │   :9090  │  │    │  │         ││ │
│  │  └─────────┘  └──────────┘  └────┘  └─────────┘│ │
│  │                    ▲          ▲                  │ │
│  │              ┌─────┴──────────┴─────┐           │ │
│  │              │ cAdvisor + Node Exp  │           │ │
│  │              └──────────────────────┘           │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                            ▲
                            │
                    ┌───────┴────────┐
                    │  CI/CD Pipeline │
                    │  (Phase 3)      │
                    │                 │
                GitHub Actions        Docker Hub
                    │                     │
                    └──────────┬──────────┘
                               │
                    Developer: git push origin main
```

---

## 🔄 Daily Workflow

### For Developers:

```bash
# 1. Make code changes locally
git add .
git commit -m "new feature"
git push origin main

# 2. Get coffee ☕ (8 minutes)

# 3. Feature is live! ✅
```

### For Operations:

**Monitoring:**
- Check Grafana daily: `http://YOUR_EC2_IP:3001`
- Review CPU/memory trends
- Check error logs in Loki

**Maintenance:**
- Backups: `bash scripts/backup-database.sh`
- Health checks: `bash scripts/health-check.sh`
- Updates: `git pull && docker compose pull && docker compose up -d`

---

## 📚 Documentation Reference

| Phase | Guide | Purpose |
|-------|-------|---------|
| 1 | [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md) | Deploy application manually |
| 2 | [PHASE2-MONITORING.md](PHASE2-MONITORING.md) | Add monitoring stack |
| 3 | [PHASE3-CICD.md](PHASE3-CICD.md) | Enable CI/CD automation |
| - | [README.md](README.md) | Project overview |

---

## 🛠️ Essential Commands

### Application Management:
```bash
# Start
docker compose up -d

# Stop
docker compose down

# View logs
docker compose logs -f

# Check status
docker compose ps

# Restart service
docker compose restart backend
```

### Monitoring Management:
```bash
# Start
docker compose -f docker-compose.monitoring.yml up -d

# Stop
docker compose -f docker-compose.monitoring.yml down

# View logs
docker compose -f docker-compose.monitoring.yml logs -f grafana
```

### Database Operations:
```bash
# Backup
bash scripts/backup-database.sh

# Connect
docker compose exec postgres psql -U bmi_user -d bmidb

# View data
docker compose exec postgres psql -U bmi_user -d bmidb -c "SELECT * FROM measurements LIMIT 5;"
```

### Health Checks:
```bash
# Run health check script
bash scripts/health-check.sh

# Manual checks
curl http://localhost:3000/health
curl http://localhost
```

---

## 🆘 Quick Troubleshooting

### Application not accessible?
```bash
# Check containers
docker compose ps

# Check logs
docker compose logs -f

# Verify security group has port 80 open
```

### Grafana not loading?
```bash
# Check monitoring stack
docker compose -f docker-compose.monitoring.yml ps

# Verify security group has port 3001 open

# Check logs
docker compose -f docker-compose.monitoring.yml logs grafana
```

### CI/CD not deploying?
```bash
# Verify GitHub Secrets are correct
# Check Actions tab for error messages
# Test SSH manually: ssh -i key.pem ubuntu@YOUR_EC2_IP
```

### High memory usage?
```bash
# Check resources
docker stats

# Consider upgrading to t2.large
# Or reduce monitoring retention
```

---

## 🔐 Security Checklist

- [ ] Strong PostgreSQL password in `.env`
- [ ] `.env` file not committed to git
- [ ] EC2 Security Group restricts SSH to your IP
- [ ] Grafana default password changed
- [ ] Docker Hub token has minimal permissions
- [ ] GitHub Secrets properly configured
- [ ] Regular system updates: `sudo apt update && sudo apt upgrade`

---

## 🎓 What You've Learned

### Docker & Containers:
- Multi-stage Dockerfiles
- Docker Compose orchestration
- Container networking
- Volume persistence
- Health checks
- Resource management

### DevOps Practices:
- Infrastructure as Code
- CI/CD pipelines
- Automated deployments
- Zero-downtime updates
- Git-based workflows

### Observability:
- Metrics collection (Prometheus)
- Log aggregation (Loki)
- Dashboard creation (Grafana)
- Query languages (PromQL, LogQL)
- Performance monitoring

### Cloud Deployment:
- AWS EC2 provisioning
- Security groups
- SSH key management
- Production deployments

---

## 🚀 Next Level (Optional)

### 1. Add HTTPS:
```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com
```

### 2. Add Domain Name:
- Register domain (Namecheap, GoDaddy)
- Point A record to EC2 IP
- Update `FRONTEND_URL` in `.env`

### 3. Scaling:
- Add read-only PostgreSQL replicas
- Use AWS Application Load Balancer
- Deploy to multiple EC2 instances

### 4. Backup Automation:
```bash
# Add to crontab
crontab -e

# Daily backups at 2 AM
0 2 * * * cd ~/3-tier-docker-compose-monitoring-ubuntu && bash scripts/backup-database.sh
```

### 5. Alerts:
- Configure Prometheus alerts
- Add Slack/email notifications
- Set up PagerDuty integration

---

## 📞 Support

**Issues?**
- Check phase-specific documentation
- Review troubleshooting sections
- Check GitHub Actions logs
- Review container logs: `docker compose logs`

**Resources:**
- Docker: [docs.docker.com](https://docs.docker.com)
- GitHub Actions: [docs.github.com/actions](https://docs.github.com/actions)
- Grafana: [grafana.com/docs](https://grafana.com/docs/)

---

## 🎊 Final Notes

You've built something impressive! This is a **production-ready** setup that many companies use in real production environments.

**Key Achievements:**
- ✅ 9 containers orchestrated seamlessly
- ✅ Full observability and monitoring
- ✅ Automated CI/CD pipeline
- ✅ Zero-downtime deployments
- ✅ Best practices implemented

**Time invested:** ~4 hours  
**Value created:** Enterprise-grade deployment! 

**You're now ready to deploy real production applications!** 🎉🚀

---

**Happy Coding and Deploying!**

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
