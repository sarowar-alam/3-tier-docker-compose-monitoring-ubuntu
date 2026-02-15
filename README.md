# BMI Health Tracker - Production Three-Tier Application

> **Enterprise-grade BMI/BMR calculator with comprehensive monitoring and automated CI/CD**

A fully containerized, production-ready health tracking application featuring automated deployments, real-time monitoring, and observability. Built with Docker Compose, deployed on AWS EC2, monitored with Prometheus/Grafana/Loki, and automated with self-hosted GitHub Actions runners.

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/ec2/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%7C%20Grafana-E6522C?logo=prometheus&logoColor=white)](https://prometheus.io/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Installation](#installation)
  - [Phase 1: Application Deployment](#phase-1-application-deployment)
  - [Phase 2: Monitoring Stack](#phase-2-monitoring-stack)
  - [Phase 3: CI/CD Automation](#phase-3-cicd-automation)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Development](#development)
- [Operations](#operations)
  - [Service Management](#service-management)
  - [Database Operations](#database-operations)
  - [Backup & Restore](#backup--restore)
  - [Logs & Debugging](#logs--debugging)
- [Monitoring & Observability](#monitoring--observability)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Performance](#performance)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)

---

## Overview

### What is This?

The BMI Health Tracker is a **reference implementation** of modern DevOps practices, demonstrating:

- ✅ **Container Orchestration** with Docker Compose
- ✅ **Infrastructure as Code** for reproducible deployments
- ✅ **Observability** with metrics, logs, and dashboards
- ✅ **CI/CD Automation** using self-hosted GitHub Actions runners
- ✅ **Security Best Practices** for production environments
- ✅ **High Availability** patterns with health checks and zero-downtime deployments

### Features

**Application Capabilities:**
- BMI (Body Mass Index) calculation with health category classification
- BMR (Basal Metabolic Rate) using Mifflin-St Jeor equation
- Daily calorie estimation based on activity levels
- Historical data tracking with PostgreSQL persistence
- Trend visualization with Chart.js
- Responsive mobile-friendly UI

**Infrastructure Capabilities:**
- Multi-container orchestration with Docker Compose
- Automated database migrations
- Health check monitoring for all services
- Container metrics collection (CPU, Memory, Network)
- Centralized log aggregation
- Pre-configured Grafana dashboards
- Automated build and deployment pipeline
- Zero-downtime rolling updates

### Use Cases

This repository is ideal for:
- **Learning:** DevOps engineers studying container orchestration and monitoring
- **Reference:** Teams implementing similar infrastructure patterns
- **Prototyping:** Quick MVP deployment with production-grade setup
- **Training:** Hands-on lab for Docker, monitoring, and CI/CD concepts

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS EC2 Ubuntu Instance (t2.medium)                  │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                  Docker Compose Environment                      │  │
│  │                                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │         Phase 1: Application Stack (3 containers)       │   │  │
│  │  │                                                         │   │  │
│  │  │    ┌──────────────┐      ┌──────────────┐             │   │  │
│  │  │    │  Frontend    │      │   Backend    │             │   │  │
│  │  │    │    React     │◄────►│   Node.js    │             │   │  │
│  │  │    │   + Nginx    │      │   Express    │             │   │  │
│  │  │    │   Port 80    │      │  Port 3000   │             │   │  │
│  │  │    └──────┬───────┘      └──────┬───────┘             │   │  │
│  │  │           │                     │                     │   │  │
│  │  │           └─────────┬───────────┘                     │   │  │
│  │  │                     │                                 │   │  │
│  │  │                ┌────▼──────┐                          │   │  │
│  │  │                │ PostgreSQL│                          │   │  │
│  │  │                │  Port 5432│                          │   │  │
│  │  │                │  (volume) │                          │   │  │
│  │  │                └───────────┘                          │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  │                                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │       Phase 2: Monitoring Stack (6 containers)          │   │  │
│  │  │                                                         │   │  │
│  │  │  ┌───────────┐  ┌──────────┐  ┌────────────┐          │   │  │
│  │  │  │Prometheus │◄─┤ cAdvisor │  │   Loki     │          │   │  │
│  │  │  │  :9090    │  │  :8080   │  │   :3100    │          │   │  │
│  │  │  └─────┬─────┘  └──────────┘  └──────▲─────┘          │   │  │
│  │  │        │                              │                │   │  │
│  │  │        │        ┌────────────┐        │                │   │  │
│  │  │        └───────►│  Grafana   │        │                │   │  │
│  │  │                 │   :3001    │        │                │   │  │
│  │  │                 └────────────┘        │                │   │  │
│  │  │                                       │                │   │  │
│  │  │  ┌────────────┐                 ┌────┴──────┐         │   │  │
│  │  │  │   Node     │                 │ Promtail  │         │   │  │
│  │  │  │  Exporter  │                 │  (logs)   │         │   │  │
│  │  │  │  :9100     │                 └───────────┘         │   │  │
│  │  │  └────────────┘                                       │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  │                                                                  │  │
│  │  ┌─────────────────────────────────────────────────────────┐   │  │
│  │  │        Phase 3: CI/CD (1 service)                      │   │  │
│  │  │                                                         │   │  │
│  │  │           ┌────────────────────────┐                   │   │  │
│  │  │           │  GitHub Actions Runner │                   │   │  │
│  │  │           │   (systemd service)    │                   │   │  │
│  │  │           │                        │                   │   │  │
│  │  │           │  • Pull code from Git  │                   │   │  │
│  │  │           │  • Build Docker images│                   │   │  │
│  │  │           │  • Deploy containers  │                   │   │  │
│  │  │           │  • Run health checks  │                   │   │  │
│  │  │           └────────────────────────┘                   │   │  │
│  │  └─────────────────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  Security Group: Ports 22, 80, 3001, 9090                             │
└─────────────────────────────────────────────────────────────────────────┘

                                    │
                            ┌───────┴────────┐
                            │                │
                 ┌──────────▼──┐   ┌─────────▼──────┐
                 │   GitHub    │   │   Developer    │
                 │  Repository │   │   Workstation  │
                 └─────────────┘   └────────────────┘
```

### Design Decisions

#### Why Docker Compose (not Kubernetes)?

- **Simplicity:** Single-host deployment perfect for small-medium workloads
- **Cost:** No orchestration overhead, runs on one EC2 instance
- **Visibility:** Clear service definitions in YAML
- **Development:** Same environment locally and in production

#### Why Self-Hosted Runner (not Docker Hub)?

- **Speed:** Local builds ~2-3 min vs 7-10 min with Docker Hub
- **Security:** No credentials in GitHub Secrets, direct local access
- **Cost:** Free, no Docker Hub subscription needed
- **Simplicity:** Single instance, all operations local

#### Why Three Networks?

- **Security:** Database isolated from frontend (defense in depth)
- **Segmentation:** backend-network, frontend-network, monitoring-network
- **Principle of Least Privilege:** Services only access what they need

---

## Technology Stack

### Application Tier

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Frontend** | React | 18.2.0 | UI framework |
| | Vite | 5.0.0 | Build tool & dev server |
| | Chart.js | 4.4.0 | Data visualization |
| | Nginx | 1.25 (Alpine) | Web server & reverse proxy |
| **Backend** | Node.js | 18 (Alpine) | JavaScript runtime |
| | Express.js | 4.18.2 | Web framework |
| | pg (node-postgres) | 8.11.3 | PostgreSQL client |
| **Database** | PostgreSQL | 14 (Alpine) | Relational database |

### Monitoring Tier

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Metrics** | Prometheus | v2.50.1 | Time-series database |
| | cAdvisor | v0.47.0 | Container metrics |
| | Node Exporter | v1.7.0 | Host metrics |
| **Visualization** | Grafana | 10.3.3 | Dashboard platform |
| **Logs** | Loki | 2.9.4 | Log aggregation |
| | Promtail | 2.9.4 | Log collector |

### CI/CD Tier

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Automation** | GitHub Actions | N/A | Workflow runner |
| | Self-hosted Runner | 2.311.0 | Local build agent |
| **Container Runtime** | Docker | 25.0.0+ | Container engine |
| | Docker Compose | 2.24.0+ | Multi-container orchestration |

### Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| **Cloud** | AWS EC2 | Ubuntu 22.04 LTS, t2.medium (4GB RAM, 2 vCPU) |
| **Storage** | EBS | gp3 SSD, 30GB root volume |
| **Network** | VPC | Public subnet, Elastic IP, Security Groups |
| **DNS** | Public IP | Direct access via IPv4 |

---

## Prerequisites

### Required Knowledge

- Basic Linux command line navigation
- Understanding of Docker concepts (images, containers, volumes, networks)
- Git version control basics
- SSH key-based authentication

### Required Accounts

1. **AWS Account**
   - Access to EC2 service
   - Ability to create Security Groups
   - Understanding of IAM basics

2. **GitHub Account**
   - Repository access
   - Ability to configure Actions
   - Personal Access Token (for runner registration)

### Required Software (Local Machine)

- **SSH Client** (PuTTY, OpenSSH, or built-in terminal)
- **Git** (2.40+)
- **Text Editor** (VS Code, Sublime, vim, etc.)

### AWS EC2 Requirements

**Minimum Specifications:**
- Instance Type: t2.small (2GB RAM, 1 vCPU)
- Storage: 20GB EBS gp3
- Operating System: Ubuntu 22.04 LTS
- Network: Public IPv4 address

**Recommended Specifications:**
- Instance Type: **t2.medium (4GB RAM, 2 vCPU)** ✅
- Storage: 30GB EBS gp3
- Operating System: Ubuntu 22.04 LTS
- Network: Elastic IP (static)

**Security Group Configuration:**

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 80 | TCP | 0.0.0.0/0 | HTTP (Frontend) |
| 3001 | TCP | Your IP | Grafana (optional) |
| 9090 | TCP | Your IP | Prometheus (optional) |

**Why t2.medium?**
- 4GB RAM needed for 9 containers + runner
- 2 vCPUs allow parallel builds
- Total memory usage: ~2.5-3GB under load

---

## Quick Start

### 🚀 Deploy in 15 Minutes

If you want to get everything running quickly:

```bash
# 1. SSH to your EC2 instance
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# 2. Clone repository
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 3. Run automated setup
chmod +x scripts/*.sh
./scripts/setup-all.sh

# 4. Access your application
# Frontend: http://YOUR_EC2_IP
# Grafana:  http://YOUR_EC2_IP:3001 (admin/admin)
# Prometheus: http://YOUR_EC2_IP:9090
```

That's it! All 9 containers will be running with monitoring configured.

**What `setup-all.sh` does:**
1. Installs Docker & Docker Compose
2. Configures environment variables
3. Deploys Phase 1 (application)
4. Deploys Phase 2 (monitoring)
5. Runs health checks
6. Displays access information

### 🎯 Phased Approach (Recommended for Learning)

For a deeper understanding, deploy in phases:

| Phase | Time | Components | Guide |
|-------|------|------------|-------|
| **1** | 1-2 hours | Application (3 containers) | [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md) |
| **2** | 30-45 min | Monitoring (6 containers) | [PHASE2-MONITORING.md](PHASE2-MONITORING.md) |
| **3** | 1 hour | CI/CD (runner + workflows) | [SETUP-GITHUB-RUNNER.md](SETUP-GITHUB-RUNNER.md) |

---

## Installation

### Phase 1: Application Deployment

**Goal:** Deploy the 3-tier application (frontend, backend, database)

**Time:** 1-2 hours (first time), 15 minutes (subsequent)

**Detailed Guide:** [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md)

#### Quick Steps

```bash
# On EC2 instance
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# Configure environment
cp .env.example .env
nano .env  # Set POSTGRES_PASSWORD and FRONTEND_URL

# Deploy
docker compose up -d

# Verify
docker compose ps
curl http://localhost:3000/health
```

#### What You Get

- ✅ React frontend on port 80
- ✅ Node.js backend API on port 3000 (internal)
- ✅ PostgreSQL database with automated migrations
- ✅ Health checks for all services
- ✅ Data persistence with Docker volumes

#### Endpoints After Phase 1

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://YOUR_EC2_IP | None |
| Backend API | http://localhost:3000 | None (internal only) |
| Database | localhost:5432 | See .env file |

**Validation:**

```bash
# All services should show "Up"
docker compose ps

# Backend health should return JSON
curl http://localhost:3000/health

# Frontend should serve HTML
curl http://localhost | head -n 5
```

---

### Phase 2: Monitoring Stack

**Goal:** Add observability with Prometheus, Grafana, and Loki

**Time:** 30-45 minutes

**Detailed Guide:** [PHASE2-MONITORING.md](PHASE2-MONITORING.md)

#### Quick Steps

```bash
# On EC2 (after Phase 1 is running)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Verify
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

#### What You Get

- ✅ **Prometheus** - Metrics collection and alerting
- ✅ **Grafana** - Pre-configured dashboards (3)
- ✅ **Loki** - Log aggregation system
- ✅ **Promtail** - Log shipping from all containers
- ✅ **cAdvisor** - Container resource metrics
- ✅ **Node Exporter** - Host system metrics

#### Dashboards Included

1. **Docker Container Monitoring**
   - CPU usage per container
   - Memory usage trends
   - Network I/O (RX/TX)
   - Container restart count

2. **Docker Logs Dashboard**
   - All container logs (real-time)
   - Error log filtering
   - Service-specific views (frontend, backend, database)
   - Log rate graphs

3. **Application Logs**
   - Application-specific logging
   - Error tracking
   - Performance metrics

#### Endpoints After Phase 2

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://YOUR_EC2_IP:3001 | admin / admin |
| Prometheus | http://YOUR_EC2_IP:9090 | None |
| Loki | http://localhost:3100 | None (internal) |

**Validation:**

```bash
# 9 containers should be running (3 app + 6 monitoring)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps

# Prometheus targets should be UP
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'

# Grafana should be accessible
curl -I http://localhost:3001
```

---

### Phase 3: CI/CD Automation

**Goal:** Automate deployments with self-hosted GitHub Actions runner

**Time:** 1 hour setup, then automatic forever

**Detailed Guide:** [SETUP-GITHUB-RUNNER.md](SETUP-GITHUB-RUNNER.md)

#### Architecture: Self-Hosted Runner

```
┌──────────────┐         ┌─────────────────┐         ┌──────────────┐
│   GitHub     │ Webhook │ Self-Hosted     │ Docker  │   Docker     │
│  Repository  ├────────►│ Actions Runner  ├────────►│  Containers  │
│              │         │  (EC2 Service)  │         │              │
└──────────────┘         └─────────────────┘         └──────────────┘
       │                          │                           │
       │ Push Code                │ Pull Code                 │
       │                          │ Build Images              │
       └──────────────────────────┴───────────────────────────┘
                    Fast (~2-3 min total)
```

**Why Self-Hosted?**
- **2-3 min deployments** (vs 7-10 min with Docker Hub)
- **No external registry** needed (no Docker Hub account)
- **More secure** (no SSH keys in GitHub Secrets)
- **Free** (uses your existing EC2 resources)

#### Quick Steps

```bash
# 1. On EC2, download and extract runner
cd ~
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf actions-runner-linux-x64-2.311.0.tar.gz

# 2. Get token from GitHub
# https://github.com/YOUR_USERNAME/YOUR_REPO/settings/actions/runners/new

# 3. Configure runner
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# 4. Install as service
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status

# 5. Verify in GitHub
# Settings → Actions → Runners → Should see your runner (green dot)
```

#### What You Get

- ✅ **Automated Builds** - Every push to `main` triggers build
- ✅ **Automated Deployments** - New containers deployed automatically
- ✅ **Health Checks** - Deployment fails if health checks don't pass
- ✅ **Git-Based Rollback** - Revert by reverting commit
- ✅ **Status Reporting** - See build/deploy status in GitHub Actions tab

#### Workflow File

Location: `.github/workflows/deploy.yml`

**Triggered by:**
- Push to `main` branch
- Manual dispatch (click "Run workflow" in GitHub)

**Steps:**
1. Checkout code
2. Pull latest from Git (on EC2)
3. Build backend & frontend images
4. Deploy Phase 1 containers
5. Ensure Phase 2 monitoring is running
6. Run health checks (backend, frontend, Grafana, Prometheus)
7. Show container status
8. Clean up old images
9. Display deployment summary

**Example Output:**

```
✅ Deployment completed successfully!
==========================================
Phase 1 - Application:
  Frontend: http://65.0.133.186
  Backend API: http://65.0.133.186:3000 (internal)

Phase 2 - Monitoring:
  Grafana: http://65.0.133.186:3001
  Prometheus: http://65.0.133.186:9090

Total Containers: 9 (3 app + 6 monitoring)
==========================================
```

#### Daily Workflow

```bash
# 1. Make code changes locally
code backend/src/server.js

# 2. Commit and push
git add .
git commit -m "feat: Add new endpoint"
git push origin main

# 3. Watch deployment in GitHub
# https://github.com/YOUR_USERNAME/YOUR_REPO/actions

# 4. Verify on your EC2
# http://YOUR_EC2_IP (automatically updated!)
```

**Benefits:**
- No manual SSH needed
- No manual docker commands
- Consistent deployments every time
- Full audit trail in Git

---

## Project Structure

```
3-tier-docker-compose-monitoring-ubuntu/
│
├── .github/
│   └── workflows/
│       └── deploy.yml                    # CI/CD workflow definition
│
├── backend/
│   ├── Dockerfile                        # Backend container definition
│   ├── .dockerignore                     # Exclude from image
│   ├── package.json                      # Node.js dependencies
│   ├── package-lock.json
│   ├── ecosystem.config.js               # PM2 configuration (optional)
│   ├── src/
│   │   ├── server.js                     # Express app entry point
│   │   ├── db.js                         # PostgreSQL connection pool
│   │   ├── routes.js                     # API route handlers
│   │   └── calculations.js               # BMI/BMR math functions
│   └── migrations/                       # Legacy SQL migrations (not used)
│       ├── 001_create_measurements.sql
│       └── 002_add_measurement_date.sql
│
├── frontend/
│   ├── Dockerfile                        # Frontend multi-stage build
│   ├── .dockerignore                     # Exclude node_modules
│   ├── nginx.conf                        # Nginx web server config
│   ├── package.json                      # React dependencies
│   ├── package-lock.json
│   ├── vite.config.js                    # Vite build configuration
│   ├── index.html                        # HTML entry point
│   ├── public/                           # Static assets
│   └── src/
│       ├── main.jsx                      # React app bootstrap
│       ├── App.jsx                       # Main component
│       ├── index.css                     # Global styles
│       ├── api.js                        # Axios HTTP client
│       └── components/
│           ├── MeasurementForm.jsx       # Input form component
│           └── TrendChart.jsx            # Chart.js visualization
│
├── database/
│   └── init-scripts/                     # Auto-run on first startup
│       ├── 01-init.sql                   # Create database & user
│       ├── 02-create-measurements.sql    # Create tables
│       └── 03-add-measurement-date.sql   # Add columns
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml                # Scrape configs, retention
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   ├── docker-monitoring.json    # Container metrics dashboard
│   │   │   ├── docker-logs.json          # Logs dashboard
│   │   │   └── application-logs.json     # App-specific logs
│   │   └── provisioning/
│   │       ├── dashboards/
│   │       │   └── dashboards.yml        # Auto-load dashboards
│   │       └── datasources/
│   │           └── datasources.yml       # Prometheus + Loki config
│   ├── loki/
│   │   └── loki-config.yml               # Log storage config (v13 schema)
│   └── promtail/
│       └── promtail-config.yml           # Log collection rules
│
├── scripts/
│   ├── setup-all.sh                      # One-command full deployment
│   ├── setup-docker.sh                   # Install Docker + Compose
│   ├── setup-github-runner.sh            # Install Actions runner
│   ├── start-with-monitoring.sh          # Start app + monitoring
│   ├── health-check.sh                   # Verify all services
│   └── get-public-ip.sh                  # Retrieve EC2 public IP
│
├── docker-compose.yml                    # Phase 1: Application stack
├── docker-compose.monitoring.yml         # Phase 2: Monitoring stack
├── docker-compose.prod.yml               # Production overrides (optional)
│
├── .env.example                          # Environment variable template
├── .gitignore                            # Git ignore patterns
├── .gitattributes                        # Git line ending config
│
├── README.md                             # This file (production guide)
├── PHASE1-DEPLOYMENT.md                  # Detailed Phase 1 guide
├── PHASE2-MONITORING.md                  # Detailed Phase 2 guide
├── SETUP-GITHUB-RUNNER.md                # Self-hosted runner setup
├── QUICKSTART-RUNNER.md                  # Quick runner setup
├── DEPLOYMENT-GUIDE.md                   # Comprehensive deployment guide
│
└── LICENSE                               # MIT License
```

### Key Files Explained

| File | Purpose | When to Edit |
|------|---------|--------------|
| `docker-compose.yml` | Main application stack | Add/remove services, change ports |
| `docker-compose.monitoring.yml` | Monitoring stack | Configure monitoring tools |
| `.env` | Runtime configuration | Passwords, URLs, environment settings |
| `.github/workflows/deploy.yml` | CI/CD pipeline | Customize deployment steps |
| `backend/src/server.js` | API entry point | Add new endpoints, middleware |
| `frontend/src/App.jsx` | UI main component | Change UI layout, add features |
| `monitoring/grafana/dashboards/*.json` | Dashboard definitions | Customize metrics/graphs |
| `monitoring/prometheus/prometheus.yml` | Metrics scraping | Add new scrape targets |

---

## Configuration

### Environment Variables

Create `.env` from template:

```bash
cp .env.example .env
nano .env
```

**Required Variables:**

```env
# Database Configuration
POSTGRES_USER=bmi_user                    # PostgreSQL username
POSTGRES_PASSWORD=CHANGEME_SecurePass123  # Strong password (16+ chars)
POSTGRES_DB=bmidb                         # Database name

# Application Configuration
NODE_ENV=production                       # 'development' or 'production'
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP    # Your EC2 public IP

# Optional: Database Connection (auto-configured)
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
```

**Security Notes:**
- ⚠️ Never commit `.env` to Git (already in `.gitignore`)
- ✅ Use 16+ character passwords with letters, numbers, symbols
- ✅ Change default password immediately
- ✅ Different passwords for dev/prod environments

### Docker Compose Configuration

#### Main Application (docker-compose.yml)

**Networks:**
```yaml
networks:
  backend-network:    # postgres <-> backend
  frontend-network:   # backend <-> frontend
```

**Volumes:**
```yaml
volumes:
  postgres-data:      # Persistent database storage
```

**Services:**

1. **postgres** (Database)
   - Image: `postgres:14-alpine`
   - Health check: `pg_isready` every 10s
   - Init scripts: Runs SQL in `database/init-scripts/` on first start
   - Restart policy: `always` (survives EC2 reboots)

2. **backend** (API)
   - Build: `./backend/Dockerfile`
   - Depends on: postgres (waits for healthy)
   - Health check: `curl /health` every 30s
   - Environment: Loads from `.env`

3. **frontend** (Web)
   - Build: `./frontend/Dockerfile` (multi-stage)
   - Depends on: backend (waits for healthy)
   - Port mapping: `80:80` (host:container)
   - Nginx config: Proxies `/api/*` to backend

#### Monitoring Stack (docker-compose.monitoring.yml)

**Networks:**
```yaml
networks:
  monitoring-network:   # Shared by all monitoring tools
  backend-network:      # Prometheus scrapes backend
```

**Volumes:**
```yaml
volumes:
  prometheus-data:      # Metrics storage (15 days retention)
  grafana-data:         # Dashboard configs and data
  loki-data:            # Log storage (7 days retention)
```

**Services:**

1. **prometheus** - Metrics database
   - Scrapes: backend, cadvisor, node-exporter
   - Retention: 15 days
   - Storage: 10GB max

2. **grafana** - Visualization
   - Auto-provisions: Datasources + dashboards
   - Default login: admin/admin (change on first login)

3. **loki** - Log aggregation
   - Schema: v13 with tsdb index
   - Retention: 7 days

4. **promtail** - Log collector
   - Sources: All Docker containers via docker_sd_configs
   - Labels: container_name, service, stream

5. **cadvisor** - Container metrics
   - Exposes: CPU, memory, network per container

6. **node-exporter** - Host metrics
   - Exposes: CPU, memory, disk, network for EC2

### Nginx Configuration

Location: `frontend/nginx.conf`

**Key Settings:**

```nginx
# Reverse proxy for API calls
location /api/ {
    proxy_pass http://backend:3000/api/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

# Static file serving
location / {
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
}

# Gzip compression
gzip on;
gzip_types text/css application/javascript application/json;
```

---

## Development

### Local Development Setup

**Prerequisites:**
- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Node.js 18+ (for local testing without Docker)
- Git

**Quick Start:**

```bash
# 1. Clone repository
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 2. Create .env
cp .env.example .env
# Edit .env: Set FRONTEND_URL=http://localhost

# 3. Start development stack
docker compose up

# 4. Access application
# Frontend: http://localhost
# Backend API: http://localhost:3000
# Backend Health: http://localhost:3000/health
```

**Hot Reload Development:**

For faster iteration without rebuilding containers:

```bash
# Backend (with nodemon):
cd backend
npm install
npm run dev  # Watches src/ for changes

# Frontend (with Vite):
cd frontend
npm install
npm run dev  # Opens http://localhost:5173
```

### Making Changes

#### Backend Changes

**Add New API Endpoint:**

1. Edit `backend/src/routes.js`:

```javascript
// Add new endpoint
router.get('/api/measurements/:id', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM measurements WHERE id = $1',
      [req.params.id]
    );
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

2. Rebuild and test:

```bash
docker compose up -d --build backend
docker compose logs -f backend
curl http://localhost:3000/api/measurements/1
```

#### Frontend Changes

**Add New Component:**

1. Create `frontend/src/components/MyComponent.jsx`:

```jsx
import { useState } from 'react';

export function My Component() {
  const [data, setData] = useState(null);
  
  return (
    <div>
      <h2>My New Feature</h2>
      {/* Your JSX here */}
    </div>
  );
}
```

2. Import in `frontend/src/App.jsx`:

```jsx
import { MyComponent } from './components/MyComponent';

function App() {
  return (
    <>
      {/* Existing components */}
      <MyComponent />
    </>
  );
}
```

3. Rebuild and test:

```bash
docker compose up -d --build frontend
# Visit http://localhost in browser
```

#### Database Changes

**Add New Table/Column:**

1. Create migration file `database/init-scripts/04-add-new-table.sql`:

```sql
CREATE TABLE IF NOT EXISTS user_preferences (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  theme VARCHAR(20) DEFAULT 'light',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

2. For existing databases, run migrations:

```bash
# Option 1: Recreate volume (loses data)
docker compose down -v
docker compose up -d

# Option 2: Exec into container and run SQL
cat database/init-scripts/04-add-new-table.sql | \
  docker compose exec -T postgres psql -U bmi_user -d bmidb
```

### Testing

#### Manual Testing

```bash
# Backend health check
curl http://localhost:3000/health

# Create measurement
curl -X POST http://localhost:3000/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weight":70,"height":175,"age":30,"gender":"male","activityLevel":"moderate"}'

# Get all measurements
curl http://localhost:3000/api/measurements

# Frontend smoke test
curl -I http://localhost
```

#### Automated Testing (Optional)

Add test scripts to `backend/package.json`:

```json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

### Debugging

#### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend

# Last 100 lines
docker compose logs --tail=100 backend

# With timestamps
docker compose logs -f --timestamps backend
```

#### Access Container Shell

```bash
# Backend container
docker compose exec backend sh

# Database container
docker compose exec postgres sh

# Check Node.js process
docker compose exec backend ps aux

# Check environment variables
docker compose exec backend env
```

#### Database Debugging

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U bmi_user -d bmidb

# Common queries:
\dt                     # List tables
\d measurements         # Describe table
SELECT * FROM measurements LIMIT 5;
SELECT COUNT(*) FROM measurements;
```

---

## Operations

### Service Management

#### Start Services

```bash
# Start all (Phase 1 only)
docker compose up -d

# Start with monitoring (Phase 1 + 2)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Start specific service
docker compose up -d backend

# Start with build (rebuild images)
docker compose up -d --build
```

#### Stop Services

```bash
# Stop all
docker compose down

# Stop with monitoring
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down

# Stop but keep volumes (preserve data)
docker compose down

# Stop and remove volumes (DELETES DATA!)
docker compose down -v
```

#### Restart Services

```bash
# Restart all
docker compose restart

# Restart specific service
docker compose restart backend

# Restart with monitoring
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart
```

#### View Status

```bash
# Service status
docker compose ps

# Detailed status
docker compose ps -a

# Resource usage
docker stats

# Container inspect
docker compose exec backend docker inspect $(docker compose ps -q backend)
```

### Database Operations

#### Backup Database

```bash
# Backup to file
docker compose exec postgres pg_dump -U bmi_user bmidb > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker compose exec postgres pg_dump -U bmi_user bmidb | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Automated daily backup (add to crontab)
0 2 * * * cd /home/ubuntu/3-tier-docker-compose-monitoring-ubuntu && \
  docker compose exec -T postgres pg_dump -U bmi_user bmidb | gzip > \
  /home/ubuntu/backups/bmidb_$(date +\%Y\%m\%d).sql.gz
```

#### Restore Database

```bash
# From SQL file
cat backup.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb

# From compressed file
gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U bmi_user -d bmidb

# Drop and recreate database first (if needed)
docker compose exec postgres psql -U bmi_user -d postgres -c "DROP DATABASE IF NOT EXISTS bmidb;"
docker compose exec postgres psql -U bmi_user -d postgres -c "CREATE DATABASE bmidb;"
cat backup.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb
```

#### Database Maintenance

```bash
# Vacuum (reclaim storage)
docker compose exec postgres psql -U bmi_user -d bmidb -c "VACUUM FULL;"

# Analyze (update statistics)
docker compose exec postgres psql -U bmi_user -d bmidb -c "ANALYZE;"

# Check database size
docker compose exec postgres psql -U bmi_user -d bmidb -c "\l+"

# Check table sizes
docker compose exec postgres psql -U bmi_user -d bmidb -c "
  SELECT
    schemaname AS schema,
    tablename AS table,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
  FROM pg_tables
  WHERE schemaname = 'public'
  ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"
```

### Logs & Debugging

#### View Logs

```bash
# Follow all logs
docker compose logs -f

# Specific service
docker compose logs -f backend

# Last N lines
docker compose logs --tail=100 frontend

# With timestamps
docker compose logs -f --timestamps backend

# Since specific time
docker compose logs --since 2024-02-14T10:00 backend
```

#### Log Rotation

Logs are automatically rotated by Docker. Configure in `docker-compose.yml`:

```yaml
services:
  backend:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"    # Max file size
        max-file: "3"      # Number of files to keep
```

#### Debugging Containers

```bash
# Check if container is running
docker compose ps backend

# Inspect container
docker compose exec backend sh

# Check environment variables
docker compose exec backend env

# Check running processes
docker compose exec backend ps aux

# Check network connectivity
docker compose exec backend ping postgres
docker compose exec backend curl http://backend:3000/health

# File system check
docker compose exec backend ls -la /app
docker compose exec backend cat /app/package.json
```

### Health Checks

#### Manual Health Checks

```bash
# Backend API health
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","timestamp":"2026-02-15T..."}

# Frontend availability
curl -I http://localhost

# Prometheus health
curl http://localhost:9090/-/healthy

# Grafana health
curl -I http://localhost:3001/api/health
```

#### Automated Health Check Script

Use provided script:

```bash
chmod +x scripts/health-check.sh
./scripts/health-check.sh
```

**Output:**

```
========================================
BMI Application Health Check
========================================
✓ Backend:    Healthy (200 OK)
✓ Frontend:   Accessible (200 OK)
✓ Prometheus: Healthy (200 OK)
✓ Grafana:    Accessible (200 OK)
✓ Loki:       Ready (200 OK)
========================================
All services are healthy!
========================================
```

### Maintenance Tasks

#### Update Application

```bash
# 1. Pull latest code
git pull origin main

# 2. Rebuild and restart
docker compose up -d --build

# 3. Verify
docker compose ps
./scripts/health-check.sh
```

#### Update Docker Images

```bash
# Pull latest base images
docker compose pull

# Rebuild with latest
docker compose up -d --build

# Remove old images
docker image prune -af
```

#### Clean Up Resources

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes (CAREFUL! This deletes data)
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused (NUCLEAR OPTION)
docker system prune -af --volumes
```

#### Disk Space Monitoring

```bash
# Check disk usage
df -h

# Docker disk usage
docker system df

# Detailed Docker usage
docker system df -v

# Find large files
du -sh /* | sort -h

# Clean Docker build cache
docker builder prune -a
```

---

## Monitoring & Observability

### Accessing Dashboards

| Dashboard | URL | Credentials | Purpose |
|-----------|-----|-------------|---------|
| **Grafana** | http://YOUR_EC2_IP:3001 | admin / admin | Visualization platform |
| **Prometheus** | http://YOUR_EC2_IP:9090 | None | Metrics database & queries |
| **Loki** | http://localhost:3100 | None | Log API (use via Grafana) |

### Pre-Configured Dashboards

#### 1. Docker Container Monitoring

**Metrics Displayed:**
- CPU usage per container (%)
- Memory usage per container (MB)
- Network I/O (RX/TX bytes)
- Container restart count
- Container uptime

**PromQL Queries Used:**

```promql
# CPU usage
rate(container_cpu_usage_seconds_total{name=~".+"}[5m]) * 100

# Memory usage
container_memory_usage_bytes{name=~".+"}  

# Network received
rate(container_network_receive_bytes_total{name=~".+"}[5m])

# Network transmitted
rate(container_network_transmit_bytes_total{name=~".+"}[5m])
```

#### 2. Docker Logs Dashboard

**Log Streams:**
- All Container Logs (real-time, 10s refresh)
- Log Rate by Container (graph)
- Error Logs (filtered for "error|exception|fail")
- Frontend Logs (Nginx access/error)
- Backend Logs (Node.js application)
- Database Logs (PostgreSQL)

**LogQL Queries Used:**

```logql
# All logs
{container_name=~"/bmi-.*"}

# Error logs only
{container_name=~"/bmi-.*"} |~ "(?i)error|exception|fail"

# Specific service
{container_name="/bmi-frontend"}
```

#### 3. Application Logs

**Focused Views:**
- Combined application logs (backend + frontend + postgres)
- Log rate trends
- Error filtering and highlighting

### Custom Metrics

#### Add New Prometheus Scrape Target

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  # Existing targets...
  
  # Add new target
  - job_name: 'my-new-service'
    static_configs:
      - targets: ['my-service:9999']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

Restart Prometheus:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart prometheus
```

#### Create Custom Dashboard

1. **In Grafana UI:**
   - Click "+" → "Dashboard"
   - Add Panel → Choose visualization
   - Write PromQL query
   - Save dashboard

2. **Export to JSON:**
   - Dashboard settings → JSON Model
   - Copy JSON
   - Save to `monitoring/grafana/dashboards/my-dashboard.json`

3. **Auto-provision:**
   - On next Grafana restart, dashboard loads automatically

### Alerting (Optional)

#### Configure Prometheus Alerts

Create `monitoring/prometheus/alerts.yml`:

```yaml
groups:
  - name: application
    rules:
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes{name=~".+"} / container_spec_memory_limit_bytes{name=~".+"} > 0.9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Container {{ $labels.name }} memory usage > 90%"
          
      - alert: ContainerDown
        expr: up{job="backend"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Backend container is down"
```

Add to `prometheus.yml`:

```yaml
rule_files:
  - "/etc/prometheus/alerts.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

---

## Deployment

### Manual Deployment

**On EC2:**

```bash
# 1. Pull latest code
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main

# 2. Rebuild and deploy
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build

# 3. Verify
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
./scripts/health-check.sh
```

### Automated Deployment (CI/CD)

**With Self-Hosted Runner:**

```bash
# Just push code to GitHub
git add .
git commit -m "feat: Add new feature"
git push origin main

# GitHub Actions runner on EC2 will:
# 1. Pull latest code
# 2. Build Docker images
# 3. Deploy containers
# 4. Run health checks
# 5. Report status

# Monitor in GitHub:
# https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

**Workflow File:** `.github/workflows/deploy.yml`

**Triggers:**
- Push to `main` branch → Automatic deployment
- Manual trigger → Click "Run workflow" in GitHub Actions

**Duration:** ~2-3 minutes (with self-hosted runner)

### Rollback Strategy

#### Git-Based Rollback

```bash
# 1. Find commit to revert to
git log --oneline -10

# 2. Revert to specific commit
git revert HEAD  # Revert last commit
# OR
git checkout COMMIT_HASH

# 3. Push reversion
git push origin main

# 4. CI/CD will auto-deploy previous version
```

#### Manual Rollback

```bash
# 1. Tag current version (before deploying)
git tag v1.0.0
git push origin v1.0.0

# 2. Later, rollback to tag
git checkout v1.0.0
docker compose up -d --build

# 3. Return to main when ready
git checkout main
```

#### Docker Image Rollback

```bash
# 1. List recent images
docker images | grep bmi

# 2. Re-tag old image as latest
docker tag sarowaralam/bmi-backend:main-abc123 sarowaralam/bmi-backend:latest

# 3. Restart with old image
docker compose up -d --no-build
```

### Zero-Downtime Deployment

The workflow uses `--no-deps` and `--force-recreate` flags:

```bash
# Recreate only application containers without affecting database
docker compose up -d --force-recreate --no-deps backend frontend
```

**Why Zero-Downtime?**
- Database container keeps running (no connection drop)
- Backend restarts quickly (~5s due to health check wait)
- Frontend serves cached content during brief backend restart
- Monitoring continues collecting metrics

---

## Troubleshooting

### Common Issues

#### Issue: Services showing "unhealthy"

**Symptoms:**
```bash
$ docker compose ps
NAME            STATUS
bmi-backend     Up (unhealthy)
bmi-frontend    Up (unhealthy)
```

**Diagnosis:**
```bash
# Check logs for errors
docker compose logs backend

# Check health endpoint
curl http://localhost:3000/health

# Inspect health check
docker inspect $(docker compose ps -q backend) | jq '.[0].State.Health'
```

**Solutions:**
1. **Wait 1-2 minutes** - Services need time to fully start
2. Check environment variables: `docker compose exec backend env`
3. Verify database connection: `docker compose exec postgres pg_isready`
4. Restart service: `docker compose restart backend`

#### Issue: Cannot access application from browser

**Symptoms:**
- `curl http://YOUR_EC2_IP` times out
- Browser shows "Connection refused"

**Diagnosis:**
```bash
# Check if frontend is running
docker compose ps frontend

# Check if port 80 is bound
sudo netstat -tulpn | grep :80

# Check from EC2
curl http://localhost
```

**Solutions:**
1. **Check Security Group**: Allow port 80 from 0.0.0.0/0
2. **Use Public IP**: Not private IP (10.x.x.x)
3. **Stop conflicting services**: `sudo systemctl stop apache2`
4. **Verify frontend logs**: `docker compose logs frontend`

#### Issue: Database connection errors

**Symptoms:**
```
Error: connect ECONNREFUSED
Error: password authentication failed
```

**Diagnosis:**
```bash
# Check if postgres is running
docker compose ps postgres

# Check logs
docker compose logs postgres

# Test connection from backend
docker compose exec backend ping postgres
docker compose exec backend nc -zv postgres 5432
```

**Solutions:**
1. Check `.env` file exists: `ls -la .env`
2. Verify password matches: `cat .env | grep POSTGRES_PASSWORD`
3. Recreate with environment: `docker compose up -d --force-recreate backend`
4. Check database is ready: `docker compose exec postgres pg_isready -U bmi_user`

#### Issue: Disk space full

**Symptoms:**
```
ERROR: no space left on device
Runner crashed: System.IO.IOException
```

**Diagnosis:**
```bash
# Check disk usage
df -h

# Check Docker usage
docker system df
```

**Solutions:**
```bash
# Clean Docker resources
docker system prune -af --volumes

# Clean old images
docker images | grep "<none>" | awk '{print $3}' | xargs docker rmi -f

# Clean logs
sudo find /var/lib/docker/containers -name "*.log" -exec truncate -s 0 {} \;

# Clean runner logs
rm -rf ~/actions-runner/_diag/*.log
```

#### Issue: Grafana shows "datasource not found"

**Symptoms:**
- Dashboards show "datasource loki was not found"
- Panels empty despite metrics/logs existing

**Diagnosis:**
```bash
# Check Grafana datasources
curl http://localhost:3001/api/datasources | jq

# Check datasource config
docker compose exec grafana cat /etc/grafana/provisioning/datasources/datasources.yml
```

**Solutions:**
1. **Restart Grafana**: `docker compose restart grafana`
2. **Check datasource UIDs** match dashboard JSON:
   - Datasources: `uid: prometheus`, `uid: loki`
   - Dashboards: `"datasource": {"type": "prometheus", "uid": "prometheus"}`
3. **Recreate Grafana volume**:
   ```bash
   docker compose down
   docker volume rm bmi-grafana-data
   docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
   ```

#### Issue: GitHub Actions runner offline

**Symptoms:**
- Runner shows "Offline" in GitHub
- Workflows queue but don't start

**Diagnosis:**
```bash
# Check runner service
cd ~/actions-runner
sudo ./svc.sh status

# Check logs
sudo journalctl -u actions.runner.* --since "10 minutes ago"
```

**Solutions:**
```bash
# Restart runner
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh start

# If still offline, reconfigure
./config.sh remove --token NEW_TOKEN
# Get new token from GitHub: Settings → Actions → Runners → New self-hosted runner
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token NEW_TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
```

### Logs & Debugging

#### Enable Debug Logging

**Backend:**

Edit `backend/src/server.js`:

```javascript
// Add at top
const DEBUG = process.env.DEBUG === 'true';

// Use throughout
if (DEBUG) console.log('Debug info:', data);
```

Set in `.env`:

```env
DEBUG=true
```

Restart:

```bash
docker compose up -d --force-recreate backend
docker compose logs -f backend
```

**Docker Compose:**

```bash
# Verbose output
docker compose --verbose up -d

# Debug specific service
docker compose logs -f --timestamps backend | tee backend-debug.log
```

#### Performance Profiling

**Backend API Response Time:**

```bash
# Add timing to requests
curl -w "\nTime: %{time_total}s\n" http://localhost:3000/api/measurements
```

**Database Query Performance:**

```sql
-- Connect to database
docker compose exec postgres psql -U bmi_user -d bmidb

-- Enable query timing
\timing

-- Analyze slow query
EXPLAIN ANALYZE SELECT * FROM measurements WHERE user_id = 1;

-- Check slow queries
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 10;
```

**Container Resource Usage:**

```bash
# Real-time stats
docker stats

# Historical metrics in Grafana
# Dashboard: Docker Container Monitoring
# Panel: CPU Usage, Memory Usage
```

---

## Security

### Security Best Practices

#### Implemented Security Measures

✅ **Container Security:**
- Non-root user in backend container (`nodejs` user)
- Minimal base images (Alpine Linux)
- No unnecessary packages installed
- Read-only root filesystems where possible

✅ **Network Security:**
- Segmented networks (backend, frontend, monitoring)
- Database not exposed to internet
- Backend API not exposed to internet
- Only port 80 externally accessible

✅ **Secrets Management:**
- Environment variables for sensitive data
- `.env` file in `.gitignore`
- No hardcoded credentials in code
- Docker secrets support (optional)

✅ **Application Security:**
- Input validation on frontend
- Parameterized SQL queries (prevents SQL injection)
- CORS configured for frontend only
- Health check endpoints don't expose sensitive data

✅ **Access Control:**
- PostgreSQL user with minimal privileges
- Grafana admin password change prompted
- SSH key-based EC2 access only
- Security Group restricting inbound traffic

#### Additional Security Hardening

**1. HTTPS with Let's Encrypt (Recommended for Production)**

Add Nginx + Certbot for SSL/TLS:

```yaml
# docker-compose.prod.yml
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - certs:/etc/nginx/certs
      
  letsencrypt:
    image: nginxproxy/acme-companion
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - certs:/etc/nginx/certs
    depends_on:
      - nginx-proxy
```

**2. Secrets Management with Docker Secrets**

```yaml
# docker-compose.secrets.yml
services:
  backend:
    secrets:
      - db_password
      
secrets:
  db_password:
    file: ./secrets/db_password.txt
```

**3. Rate Limiting**

Add to `frontend/nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

location /api/ {
    limit_req zone=api_limit burst=20 nodelay;
    proxy_pass http://backend:3000/api/;
}
```

**4. Security Headers**

Add to `frontend/nginx.conf`:

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
```

**5. Database Encryption at Rest**

Enable in `docker-compose.yml`:

```yaml
services:
  postgres:
    environment:
      - POSTGRES_INITDB_ARGS=--data-checksums
    command: 
      - postgres
      - -c
      - ssl=on
      - -c
      - ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
      - -c
      - ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
```

### Vulnerability Scanning

**Scan Docker Images:**

```bash
# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image bmi-backend:latest

# Using Docker Scout
docker scout cves bmi-backend:latest
```

**Scan for Secrets in Code:**

```bash
# Using gitleaks
docker run --rm -v $(pwd):/src zricethezav/gitleaks:latest \
  detect --source /src --verbose
```

### Compliance Checklist

- [ ] All credentials stored in `.env` (not hardcoded)
- [ ] `.env` file in `.gitignore` and never committed
- [ ] Strong passwords (16+ characters, mixed case, numbers, symbols)
- [ ] SSH keys used (not passwords) for EC2 access
- [ ] Security Group allows only necessary ports
- [ ] HTTPS enabled (if public-facing)
- [ ] Grafana admin password changed from default
- [ ] PostgreSQL accessible only within Docker network
- [ ] Regular backups scheduled and tested
- [ ] Logs reviewed periodically for anomalies
- [ ] Docker images updated regularly
- [ ] Vulnerability scans performed monthly

---

## Performance

### Performance Characteristics

**Resource Usage (Measured on t2.medium):**

| Component | CPU (idle) | CPU (load) | Memory | Disk |
|-----------|------------|------------|--------|------|
| Frontend | <1% | 5-10% | ~20MB | ~50MB |
| Backend | <1% | 10-20% | ~80MB | ~100MB |
| Postgres | <1% | 15-30% | ~50MB | ~200MB + data |
| Prometheus | 1-2% | 3-5% | ~200MB | ~500MB |
| Grafana | <1% | 2-4% | ~150MB | ~100MB |
| Loki | <1% | 2-3% | ~100MB | ~300MB |
| Promtail | <1% | 1-2% | ~50MB | ~10MB |
| cAdvisor | 1-2% | 2-3% | ~100MB | ~10MB |
| Node Exporter | <1% | <1% | ~20MB | ~10MB |
| Runner | 0% | 50%+ | ~500MB | ~500MB |
| **Total** | ~10% | Up to 100% | ~2.5-3GB | ~2-3GB |

**API Performance:**

| Endpoint | Avg Response | P95 | P99 |
|----------|--------------|-----|-----|
| `GET /health` | <10ms | 15ms | 20ms |
| `GET /api/measurements` | 20-50ms | 100ms | 200ms |
| `POST /api/measurements` | 30-80ms | 150ms | 250ms |
| Frontend (cached) | <50ms | 100ms | 150ms |

### Optimization Tips

#### 1. Database Optimization

**Enable Connection Pooling:**

Already configured in `backend/src/db.js`:

```javascript
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,            // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

**Add Indexes:**

```sql
-- Connect to database
docker compose exec postgres psql -U bmi_user -d bmidb

-- Add index on frequently queried columns
CREATE INDEX idx_measurements_user_id ON measurements(user_id);
CREATE INDEX idx_measurements_created_at ON measurements(created_at);

-- Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

**Configure PostgreSQL:**

Add to `docker-compose.yml`:

```yaml
services:
  postgres:
    command:
      - postgres
      - -c
      - shared_buffers=256MB
      - -c
      - effective_cache_size=1GB
      - -c
      - maintenance_work_mem=64MB
      - -c
      - checkpoint_completion_target=0.9
      - -c
      - wal_buffers=16MB
      - -c
      - default_statistics_target=100
      - -c
      - random_page_cost=1.1
      - -c
      - effective_io_concurrency=200
```

#### 2. Frontend Optimization

**Enable Gzip Compression:** (Already configured)

**Add Browser Caching:**

Add to `frontend/nginx.conf`:

```nginx
location /assets/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

**Minify JavaScript:**

Vite already minifies in production. Verify in `frontend/vite.config.js`:

```javascript
export default defineConfig({
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,  // Remove console.logs
      },
    },
  },
});
```

#### 3. Monitoring Optimization

**Reduce Prometheus Scrape Frequency:**

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 30s  # Increase from 15s
  evaluation_interval: 30s
```

**Reduce Loki Retention:**

Edit `monitoring/loki/loki-config.yml`:

```yaml
limits_config:
  retention_period: 168h  # 7 days (reduce if disk constrained)
```

**Limit Grafana Refresh:**

In Grafana dashboards, change refresh from 10s to 30s or 1m.

#### 4. Container Optimization

**Use .dockerignore:**

Already configured. Verify `backend/.dockerignore`:

```
node_modules/
npm-debug.log
.git/
.env
*.md
```

**Multi-stage Builds:** (Already using for frontend)

**Reduce Image Layers:**

Combine RUN commands in Dockerfiles:

```dockerfile
# Bad (3 layers)
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# Good (1 layer)
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Scaling Considerations

#### Vertical Scaling (Easier)

Upgrade EC2 instance:
- t2.medium → t2.large (8GB RAM, 2 vCPU)
- t2.large → t2.xlarge (16GB RAM, 4 vCPU)

**When to scale:**
- CPU consistently >70%
- Memory consistently >80%
- Swap usage increasing
- API response times degrading

#### Horizontal Scaling (Advanced)

For multi-instance deployment:

1. **Load Balancer:** AWS ALB distributing traffic
2. **Database:** RDS PostgreSQL (managed, HA)
3. **Sessions:** Redis for shared session storage
4. **Monitoring:** Centralized Prometheus + Thanos
5. **CI/CD:** Deploy to multiple instances

**Not covered in this repo** (out of scope for learning project).

---

## Contributing

### How to Contribute

We welcome contributions! Here's how:

1. **Fork the repository**
   ```bash
   # Click "Fork" button on GitHub
   git clone https://github.com/YOUR_USERNAME/3-tier-docker-compose-monitoring-ubuntu.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

3. **Make your changes**
   - Follow existing code style
   - Add tests if applicable
   - Update documentation

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add amazing feature"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

6. **Open a Pull Request**
   - Go to original repository
   - Click "New Pull Request"
   - Describe your changes clearly

### Contribution Guidelines

**Code Style:**
- Use consistent indentation (2 spaces for JavaScript/YAML, 4 for Python)
- Add comments for complex logic
- Follow existing naming conventions
- Keep functions small and focused

**Commit Messages:**
- Use conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- Be descriptive: `feat: Add health check endpoint for monitoring integration`
- Reference issues: `fix: Resolve database connection timeout (closes #123)`

**Pull Request Guidelines:**
- Clear title and description
- Link related issues
- Include screenshots for UI changes
- Ensure all tests pass (if applicable)
- Respond to code review feedback promptly

### Areas for Contribution

**Easy (Good First Issues):**
- Improve documentation
- Add more examples to README
- Fix typos
- Add helpful comments

**Medium:**
- Add new Grafana dashboards
- Improve error handling
- Add logging enhancements
- Optimize Docker images

**Advanced:**
- Add Kubernetes manifests
- Implement automated testing
- Add Terraform for AWS provisioning
- Create Helm charts

### Code of Conduct

- Be respectful and constructive
- Welcome newcomers
- Focus on what is best for the community
- Show empathy towards other community members

---

## Support

### Getting Help

**Documentation:**
- [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md) - Application deployment guide
- [PHASE2-MONITORING.md](PHASE2-MONITORING.md) - Monitoring setup guide
- [SETUP-GITHUB-RUNNER.md](SETUP-GITHUB-RUNNER.md) - CI/CD configuration
- [QUICKSTART-RUNNER.md](QUICKSTART-RUNNER.md) - Quick reference

**Troubleshooting:**
- Check [Troubleshooting](#troubleshooting) section above
- Review [Common Issues](#common-issues)
- Search [GitHub Issues](https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/issues)

**Community:**
- Open an [Issue](https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/issues/new)
- Start a [Discussion](https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/discussions)

### Reporting Issues

When reporting bugs, please include:

1. **Environment:**
   - EC2 instance type
   - Ubuntu version: `lsb_release -a`
   - Docker version: `docker --version`
   - Docker Compose version: `docker compose version`

2. **Steps to Reproduce:**
   - What command did you run?
   - What did you expect to happen?
   - What actually happened?

3. **Logs:**
   ```bash
   docker compose logs > all-logs.txt
   docker compose ps >> all-logs.txt
   ```
   Attach `all-logs.txt` to issue

4. **Screenshots:**
   - If UI-related, include browser console errors

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### MIT License Summary

✅ **Permissions:**
- Commercial use
- Modification
- Distribution
- Private use

❌ **Limitations:**
- Liability
- Warranty

**Attribution Required:** Include original copyright notice in copies.

---

## Roadmap

### Completed ✅

- [x] **Phase 1:** Three-tier application deployment
- [x] **Phase 2:** Comprehensive monitoring stack
- [x] **Phase 3:** Self-hosted CI/CD with GitHub Actions
- [x] Docker Compose orchestration
- [x] PostgreSQL with automated migrations
- [x] Prometheus metrics collection
- [x] Grafana dashboards
- [x] Loki log aggregation
- [x] Health checks for all services
- [x] Production-ready documentation

### Planned 📋

- [ ] **Phase 4:** HTTPS with Let's Encrypt
  - Automatic SSL certificate provisioning
  - Nginx reverse proxy configuration
  - HTTP to HTTPS redirect

- [ ] **Phase 5:** Kubernetes Migration
  - Helm charts
  - StatefulSets for database
  - HorizontalPodAutoscaler
  - Ingress configuration

- [ ] **Phase 6:** Advanced Observability
  - Distributed tracing (Jaeger/Tempo)
  - Application Performance Monitoring
  - Custom business metrics
  - Advanced alerting rules

- [ ] **Phase 7:** High Availability
  - Multi-AZ deployment
  - Database replication
  - Load balancing
  - Failover automation

### Future Enhancements 💡

- Automated testing (unit, integration, e2e)
- Infrastructure as Code (Terraform)
- Blue-green deployments
- Canary releases
- Cost optimization guides
- Performance benchmarking suite
- Security scanning automation
- Compliance reporting

---

## Acknowledgments

### Technologies Used

- **[Docker](https://www.docker.com/)** - Container platform
- **[Docker Compose](https://docs.docker.com/compose/)** - Multi-container orchestration
- **[PostgreSQL](https://www.postgresql.org/)** - Relational database
- **[Node.js](https://nodejs.org/)** - JavaScript runtime
- **[Express.js](https://expressjs.com/)** - Web framework
- **[React](https://react.dev/)** - Frontend library
- **[Nginx](https://nginx.org/)** - Web server & reverse proxy
- **[Prometheus](https://prometheus.io/)** - Monitoring system
- **[Grafana](https://grafana.com/)** - Visualization platform
- **[Loki](https://grafana.com/oss/loki/)** - Log aggregation
- **[GitHub Actions](https://github.com/features/actions)** - CI/CD automation
- **[AWS EC2](https://aws.amazon.com/ec2/)** - Cloud compute

### Inspiration

This project was created as a comprehensive learning resource for:
- DevOps engineers beginning their journey
- Teams transitioning to containerized applications
- Organizations implementing observability
- Anyone curious about production infrastructure patterns

### Contributors

Created and maintained by **Md. Sarowar Alam**

Special thanks to all contributors who have helped improve this project!

---

## Final Notes

### Project Philosophy

This repository embodies several key principles:

1. **Learning First:** Designed to teach, not just work
2. **Production Ready:** Real patterns used in production
3. **Well Documented:** Every decision explained
4. **Iterative Approach:** Build understanding through phases
5. **Best Practices:** Industry-standard tools and methods

### What Makes This Different?

- ✅ **Complete:** All 3 phases (app + monitoring + CI/CD)
- ✅ **Documented:** 5000+ lines of documentation
- ✅ **Self-Hosted:** No external dependencies (Docker Hub)
- ✅ **Production-Grade:** Security, monitoring, automation
- ✅ **Tested:** Deployed on real AWS infrastructure
- ✅ **Maintained:** Active support and updates

### Success Metrics

By completing all phases, you will have:
- Deployed a 3-tier containerized application
- Implemented comprehensive monitoring
- Automated your deployment pipeline
- Learned Docker, monitoring, and CI/CD
- Gained practical DevOps experience

**Total time investment:** 3-4 hours  
**Skills gained:** Priceless

---

**Ready to get started?** Follow [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md) for step-by-step instructions!

**Questions?** Open an [issue](https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/issues)!

**Happy deploying! 🚀**

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
