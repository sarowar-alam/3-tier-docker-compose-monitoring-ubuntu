# BMI Health Tracker - Dockerized Three-Tier Application

A production-ready BMI (Body Mass Index) and BMR (Basal Metabolic Rate) calculator with health tracking, fully containerized with Docker Compose for easy deployment on AWS EC2.

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/ec2/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│           AWS EC2 Ubuntu Instance           │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │       Docker Compose Stack           │  │
│  │                                      │  │
│  │  ┌──────────┐    ┌──────────┐      │  │
│  │  │ Frontend │    │ Backend  │      │  │
│  │  │  React   │◄───│ Node.js  │      │  │
│  │  │  + Nginx │    │ Express  │      │  │
│  │  └────┬─────┘    └────┬─────┘      │  │
│  │       │               │             │  │
│  │     Port 80      Port 3000          │  │
│  │       └───────┬───────┘             │  │
│  │               │                     │  │
│  │          ┌────▼─────┐               │  │
│  │          │PostgreSQL│               │  │
│  │          │   :5432  │               │  │
│  │          └──────────┘               │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Technology Stack

**Frontend:**
- React 18.2.0
- Vite 5.0 (build tool)
- Chart.js (data visualization)
- Nginx (static file server + reverse proxy)

**Backend:**
- Node.js 18 (Alpine Linux)
- Express.js 4.18
- PostgreSQL client (pg)
- Health check endpoint

**Database:**
- PostgreSQL 14 (Alpine Linux)
- Automated migrations on startup
- Persistent volume storage

---

## 🚀 Quick Start

### Prerequisites
- AWS EC2 Ubuntu instance (t2.small minimum, t2.medium recommended)
- Docker and Docker Compose installed
- Security Group: Ports 22 (SSH), 80 (HTTP) open

### Deploy in 5 Minutes

```bash
# 1. Clone repository
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 2. Configure environment
cp .env.example .env
nano .env  # Set POSTGRES_PASSWORD and FRONTEND_URL

# 3. Build and start
docker compose build
docker compose up -d

# 4. Verify
docker compose ps
curl http://localhost:3000/health

# 5. Access from browser
# Navigate to: http://YOUR_EC2_PUBLIC_IP
```

---

## 📚 Deployment Phases

This project uses a phased approach for learning and automation:

### Phase 1: Manual Docker Deployment ✅
**Status:** Ready to deploy  
**Guide:** [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md)  
**Duration:** ~1-2 hours

Learn Docker fundamentals by manually deploying:
- Dockerize three-tier application
- Configure Docker Compose orchestration
- Deploy to AWS EC2 Ubuntu
- Understanding networking and volumes
- Database migrations and persistence

**Files involved:**
- `docker-compose.yml` - Main application stack
- `backend/Dockerfile` - Backend container
- `frontend/Dockerfile` - Frontend container
- `database/init-scripts/` - DB initialization

### Phase 2: Monitoring Stack ✅
**Status:** Ready to deploy  
**Guide:** [PHASE2-MONITORING.md](PHASE2-MONITORING.md)  
**Duration:** ~30-45 minutes

Add comprehensive observability (6 additional containers):
- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization dashboards
- **Loki** - Log aggregation system
- **Promtail** - Log collector agent
- **cAdvisor** - Container metrics exporter
- **Node Exporter** - System metrics exporter

**Files involved:**
- `docker-compose.monitoring.yml` - Monitoring stack
- `monitoring/` - Configuration files
- Pre-configured Grafana dashboards

### Phase 3: CI/CD Automation ✅
**Status:** Ready to deploy  
**Guide:** [PHASE3-CICD.md](PHASE3-CICD.md)  
**Duration:** ~1 hour setup

Automate deployment pipeline with GitHub Actions:
- **Build workflow** - Automated Docker image builds
- **Deploy workflow** - Automated EC2 deployments
- **Docker Hub registry** - Pre-built image storage
- **Zero-downtime deployments** - Rolling updates
- **Git-based rollback** - Instant version control

**Files involved:**
- `.github/workflows/build-push.yml` - CI pipeline
- `.github/workflows/deploy-ec2.yml` - CD pipeline
- `docker-compose.prod.yml` - Production overrides

---

## 🚀 Quick Start by Phase

### Deploy Phase 1 (Application Only)
```bash
# On EC2
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu
cp .env.example .env
nano .env  # Configure passwords and URLs
docker compose up -d
```

### Add Phase 2 (Monitoring)
```bash
# On EC2 (after Phase 1 is running)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d
# Access Grafana: http://YOUR_EC2_IP:3001
```

### Enable Phase 3 (CI/CD)
```bash
# One-time setup:
# 1. Create Docker Hub account & repositories
# 2. Add 5 GitHub Secrets (see PHASE3-CICD.md)
# 3. Push code to main branch

# Then every deployment:
git commit -m "your changes"
git push origin main
# Wait ~8 minutes - automatic deployment!

---

## 📖 Documentation

### For Deployment
- **[PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md)** - Complete step-by-step EC2 deployment guide
- **[.env.example](.env.example)** - Environment variables template

### Project Structure
```
3-tier-docker-compose-monitoring-ubuntu/
├── backend/
│   ├── Dockerfile              # Backend container definition
│   ├── .dockerignore          # Files to exclude from image
│   ├── package.json           # Node.js dependencies
│   ├── src/
│   │   ├── server.js          # Express server
│   │   ├── db.js              # PostgreSQL connection
│   │   ├── routes.js          # API routes
│   │   └── calculations.js    # BMI/BMR calculations
│   └── migrations/            # Original SQL migrations
├── frontend/
│   ├── Dockerfile             # Frontend container definition
│   ├── .dockerignore         # Files to exclude from image
│   ├── nginx.conf            # Nginx configuration
│   ├── package.json          # React dependencies
│   └── src/
│       ├── App.jsx           # Main React component
│       ├── api.js            # Axios HTTP client
│       └── components/       # React components
├── database/
│   └── init-scripts/         # Auto-run on container startup
│       ├── 01-init.sql       # Create database & user
│       ├── 02-create-measurements.sql  # Create tables
│       └── 03-add-measurement-date.sql # Add columns
├── docker-compose.yml        # Main orchestration file
├── .env.example              # Environment template
├── .gitignore               # Git ignore rules
└── PHASE1-DEPLOYMENT.md     # Deployment guide
```

---

## 🔐 Environment Configuration

Create `.env` file from template and configure:

```env
# Database credentials
POSTGRES_USER=bmi_user
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=bmidb

# Application settings
NODE_ENV=production
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP
```

⚠️ **Security Note:** Never commit `.env` to git! It's already in `.gitignore`.

---

## 🐳 Docker Compose Services

### PostgreSQL (Database)
- **Image:** `postgres:14-alpine`
- **Container:** `bmi-postgres`
- **Internal Port:** 5432
- **Volume:** `postgres-data` (persistent)
- **Health Check:** `pg_isready` every 10s
- **Auto-runs:** SQL init scripts on first startup

### Backend (API)
- **Build:** `./backend/Dockerfile`
- **Container:** `bmi-backend`
- **Internal Port:** 3000
- **Depends On:** postgres (waits for healthy status)
- **Health Check:** `/health` endpoint every 30s
- **Environment:** DATABASE_URL, NODE_ENV, FRONTEND_URL

### Frontend (Web UI)
- **Build:** `./frontend/Dockerfile`
- **Container:** `bmi-frontend`
- **External Port:** 80 (mapped to host)
- **Depends On:** backend (waits for healthy status)
- **Health Check:** Root endpoint every 30s
- **Nginx:** Serves static files + proxies `/api/*` to backend

---

## 🛠️ Common Commands

### Service Management
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View status
docker compose ps

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f backend

# Restart services
docker compose restart

# Rebuild and restart
docker compose up -d --build
```

### Database Access
```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U bmi_user -d bmidb

# List tables
docker compose exec postgres psql -U bmi_user -d bmidb -c "\dt"

# View measurements
docker compose exec postgres psql -U bmi_user -d bmidb -c "SELECT * FROM measurements LIMIT 5;"
```

### Backups
```bash
# Backup database
docker compose exec postgres pg_dump -U bmi_user bmidb > backup_$(date +%Y%m%d).sql

# Restore database
cat backup.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb
```

---

## 🔍 Health Checks

All services have built-in health checks:

```bash
# Check all service health
docker compose ps

# Test backend health endpoint
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","timestamp":"2026-02-14T..."}
```

---

## 🌐 Networking

Two isolated networks for security:

- **backend-network:** postgres ↔ backend only
- **frontend-network:** backend ↔ frontend only

Frontend cannot directly access database (must go through backend API).

---

## 💾 Data Persistence

Database data persists in Docker volume:
- **Volume Name:** `bmi-postgres-data`
- **Type:** Local driver
- **Persistence:** Survives container restarts and rebuilds

```bash
# View volumes
docker volume ls

# Inspect volume
docker volume inspect bmi-postgres-data
```

---

## 🚨 Troubleshooting

### Services showing "unhealthy"
```bash
# Check logs for errors
docker compose logs backend

# Wait for services to fully start (can take 1-2 minutes)
docker compose ps
```

### Cannot access from browser
1. Check EC2 Security Group allows port 80 from 0.0.0.0/0
2. Use EC2 **public IP**, not private IP
3. Verify frontend is running: `curl http://localhost`

### Database connection errors
```bash
# Verify environment variables
cat .env

# Check database is ready
docker compose exec postgres pg_isready -U bmi_user -d bmidb

# Restart backend
docker compose restart backend
```

### Port 80 already in use
```bash
# Check what's using port 80
sudo lsof -i :80

# Stop Apache/Nginx if installed
sudo systemctl stop apache2
sudo systemctl disable apache2
```

For more troubleshooting, see [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md#troubleshooting).

---

## 📊 Features

- **BMI Calculation:** Calculate Body Mass Index with category classification
- **BMR Calculation:** Basal Metabolic Rate using Mifflin-St Jeor equation
- **Calorie Estimation:** Daily calorie needs based on activity level
- **Data Persistence:** Store and retrieve measurement history
- **Trend Visualization:** Chart.js graphs showing health trends over time
- **Responsive UI:** Works on desktop and mobile browsers
- **RESTful API:** Backend API for measurement CRUD operations
- **Health Monitoring:** Built-in health check endpoints

---

## 🔒 Security

- Non-root containers (backend runs as nodejs user)
- Environment-based secrets (never hardcoded)
- Network isolation (segmented backend/frontend)
- Nginx security headers
- PostgreSQL user with minimal privileges
- JSON file logging (10MB rotation)

---

## 📈 Performance

- **Small footprint:** Alpine Linux base images (~500MB total)
- **Fast startup:** Health checks ensure readiness
- **Connection pooling:** PostgreSQL pool (max 20 connections)
- **Nginx caching:** Static assets cached with far-future expires
- **Gzip compression:** Enabled for text assets

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

## 🎯 Roadmap

- [x] **Phase 1:** Docker Compose deployment ✅
- [x] **Phase 2:** Monitoring stack (Prometheus, Grafana, Loki) ✅
- [x] **Phase 3:** CI/CD with GitHub Actions ✅
- [ ] **Phase 4:** HTTPS with Let's Encrypt (optional)
- [ ] **Phase 5:** Horizontal scaling with Docker Swarm (optional)
- [ ] **Phase 6:** Kubernetes migration (advanced)

## 📊 Complete Feature Matrix

| Feature | Phase 1 | Phase 2 | Phase 3 |
|---------|---------|---------|---------|
| **Application** |
| Frontend (React) | ✅ | ✅ | ✅ |
| Backend (Node.js) | ✅ | ✅ | ✅ |
| Database (PostgreSQL) | ✅ | ✅ | ✅ |
| Health checks | ✅ | ✅ | ✅ |
| Data persistence | ✅ | ✅ | ✅ |
| **Monitoring** |
| Metrics (Prometheus) | - | ✅ | ✅ |
| Dashboards (Grafana) | - | ✅ | ✅ |
| Logs (Loki) | - | ✅ | ✅ |
| Container metrics | - | ✅ | ✅ |
| System metrics | - | ✅ | ✅ |
| **Automation** |
| Manual deployment | ✅ | ✅ | - |
| Automated builds | - | - | ✅ |
| Automated deploys | - | - | ✅ |
| Docker Hub registry | - | - | ✅ |
| Zero-downtime updates | - | - | ✅ |
| Git-based rollback | - | - | ✅ |

## 🕒 Time Investment

| Phase | Setup Time | Complexity | Value |
|-------|-----------|------------|-------|
| Phase 1 | 1-2 hours | Beginner | High - Working app |
| Phase 2 | 30-45 min | Intermediate | High - Full visibility |
| Phase 3 | 1 hour | Intermediate | Very High - Automation |
| **Total** | **3-4 hours** | - | **Production-ready!** |

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/issues)
- **Documentation:** See `PHASE1-DEPLOYMENT.md` for detailed guide
- **Logs:** `docker compose logs -f` for debugging

---

## 🙏 Acknowledgments

- React team for amazing frontend framework
- Express.js for simple backend API
- PostgreSQL for reliable database
- Docker for containerization platform
- Nginx for high-performance web server

---

**Ready to deploy?** Follow [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md) for step-by-step instructions! 🚀

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
