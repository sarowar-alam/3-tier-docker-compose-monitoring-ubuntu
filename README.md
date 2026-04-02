# BMI Health Tracker — Production Three-Tier Application

> A fully containerised, production-ready health tracking application with automated deployments, real-time monitoring, and complete observability. Deployed on AWS EC2 with Docker Compose, monitored with Prometheus / Grafana / Loki, and automated with a self-hosted GitHub Actions runner.

[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![AWS](https://img.shields.io/badge/AWS-EC2-FF9900?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/ec2/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Grafana](https://img.shields.io/badge/Grafana-Loki%20%7C%20Prometheus-E6522C?logo=grafana&logoColor=white)](https://grafana.com/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Phase 1 — Application Deployment](#phase-1--application-deployment)
- [Phase 2 — Monitoring Stack](#phase-2--monitoring-stack)
- [Phase 3 — CI/CD with Self-Hosted Runner](#phase-3--cicd-with-self-hosted-runner)
- [Configuration Reference](#configuration-reference)
- [API Reference](#api-reference)
- [Development Guide](#development-guide)
- [Operations Runbook](#operations-runbook)
- [Monitoring & Dashboards](#monitoring--dashboards)
- [Deployment Workflows](#deployment-workflows)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Performance](#performance)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

---

## Overview

### What This Repo Is

The BMI Health Tracker is a **reference implementation** of production DevOps patterns:

- **Three-tier application** — React frontend, Node.js/Express backend, PostgreSQL database
- **Full observability stack** — container metrics (cAdvisor), host metrics (node-exporter), log aggregation (Loki / Promtail), dashboards (Grafana)
- **Self-hosted CI/CD** — a GitHub Actions runner installed as a systemd service on the EC2 instance; every push to `main` triggers a local build and rolling deploy with no external registries

### What the Application Does

| Feature | Detail |
|---------|--------|
| BMI calculation | Weight / Height² with WHO category |
| BMR calculation | Mifflin-St Jeor equation |
| Daily calorie estimate | BMR × activity multiplier |
| History tracking | Persisted to PostgreSQL |
| Trend visualisation | Chart.js 30-day BMI trend |

### When to Use This Repo

| Scenario | Fit |
|----------|-----|
| Learning Docker Compose orchestration | ✅ |
| Learning Prometheus / Grafana / Loki | ✅ |
| Learning GitHub Actions self-hosted runners | ✅ |
| Production multi-tenant SaaS | ❌ (use Kubernetes instead) |

---

## Architecture

### Container Map

```
┌───────────────────────────────────────────────────────────────────────────┐
│  AWS EC2  ubuntu@ip-*  (t2.medium — 4 GB RAM, 2 vCPU)                     │
│                                                                           │
│  ┌──────────────────────────────── Phase 1 ───────────────────────────┐   │
│  │                                                                    │   │
│  │  ┌──────────────────┐   /api/*   ┌──────────────────┐              │   │
│  │  │  bmi-frontend    │ ─────────► │  bmi-backend     │              │   │
│  │  │  React + Nginx   │            │  Node.js Express │              │   │
│  │  │  :80 (public)    │            │  :3000 (internal)│              │   │
│  │  └──────────────────┘            └────────┬─────────┘              │   │
│  │                                           │ postgres://            │   │
│  │                                  ┌────────▼─────────┐              │   │
│  │                                  │  bmi-postgres    │              │   │
│  │                                  │  PostgreSQL 14   │              │   │
│  │                                  │  :5432 (internal)│              │   │
│  │                                  └──────────────────┘              │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌──────────────────────────────── Phase 2 ───────────────────────────┐   │
│  │                                                                    │   │
│  │  ┌──────────────┐  scrape  ┌──────────────┐  scrape                │   │
│  │  │  prometheus  │ ◄─────── │   cadvisor   │  (container metrics)   │   │
│  │  │  :9090       │          └──────────────┘                        │   │
│  │  │  (public)    │  scrape  ┌──────────────┐                        │   │
│  │  │              │ ◄─────── │node-exporter │  (host metrics)        │   │
│  │  └──────┬───────┘          └──────────────┘                        │   │
│  │         │ datasource                                               │   │
│  │  ┌──────▼───────┐          ┌──────────────┐  push logs             │   │
│  │  │   grafana    │ ◄─────── │    loki      │ ◄──── promtail         │   │
│  │  │  :3001       │ datasrc  │  :3100       │       (docker sock)    │   │
│  │  │  (public)    │          │  (internal)  │                        │   │
│  │  └──────────────┘          └──────────────┘                        │   │
│  └────────────────────────────────────────────────────────────────────┘   │
│                                                                           │
│  ┌──────────────────────────────── Phase 3 ───────────────────────────┐   │
│  │                                                                    │   │
│  │  GitHub ──webhook──► actions-runner (systemd)                      │   │
│  │                           │                                        │   │
│  │                     git pull + docker compose build + deploy       │   │
│  └────────────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────────┘
```

### Network Isolation

| Network | Members | Purpose |
|---------|---------|---------|
| `bmi-backend-network` | postgres, backend | DB ↔ API only |
| `bmi-frontend-network` | backend, frontend | API ↔ Nginx only |
| `monitoring-network` | prometheus, grafana, loki, promtail, cadvisor, node-exporter | All monitoring tools |

The database is never on the same network as the frontend. Port 5432 is never published to the host.

### Design Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Orchestrator | Docker Compose | Single host, simpler than k8s for this scale |
| CI runner | Self-hosted on EC2 | Builds run locally — no Docker Hub, no SSH secrets, 2–3 min deploys |
| Log collection | Promtail → Loki | GitOps native; label-based querying; native Grafana integration |
| Metrics | Prometheus + cAdvisor + node-exporter | Standard OSS stack; 400+ container and host metrics |
| DB migrations | SQL init scripts in `database/init-scripts/` | Declarative, idempotent, run once on first container start |

---

## Technology Stack

### Application

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | React | 18 |
| | Vite | 5 |
| | Chart.js | 4 |
| | Nginx | 1.25-alpine |
| Backend | Node.js | 18-alpine |
| | Express | 4.18 |
| | node-postgres (pg) | 8.11 |
| Database | PostgreSQL | 14-alpine |

### Monitoring

| Tool | Version | Role |
|------|---------|------|
| Prometheus | latest | Metrics TSDB — scrapes cadvisor + node-exporter |
| cAdvisor | latest | Per-container CPU / memory / network |
| node-exporter | latest | Host CPU / memory / disk / network |
| Grafana | latest | Dashboards (3 pre-provisioned) |
| Loki | latest | Log storage |
| Promtail | latest | Log shipper (docker_sd_configs) |

### Infrastructure

| Component | Detail |
|-----------|--------|
| Cloud | AWS EC2 — Ubuntu 22.04 LTS |
| Instance | t2.medium (4 GB RAM, 2 vCPU) — minimum for all 9 containers + runner |
| Storage | 30 GB EBS gp3 |
| CI/CD | GitHub Actions — self-hosted runner (systemd service on EC2) |

---

## Prerequisites

### Required Accounts

- **AWS** — EC2 access and ability to configure Security Groups
- **GitHub** — repository access with permission to configure Actions runners

### EC2 Security Group — Required Inbound Rules

| Port | Source | Service |
|------|--------|---------|
| 22 | Your IP | SSH |
| 80 | 0.0.0.0/0 | Frontend (HTTP) |
| 3001 | Your IP | Grafana |
| 9090 | Your IP | Prometheus |

> Port 3000 (backend), 5432 (postgres), 3100 (loki), 8080 (cadvisor), 9100 (node-exporter) are **not** published to the host. They are internal Docker network only.

### Local Machine

- SSH client + your EC2 `.pem` key file
- Git 2.40+
- Any text editor

### EC2 Instance Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 3 GB | **4 GB (t2.medium)** |
| vCPU | 1 | 2 |
| Disk | 20 GB | 30 GB |
| OS | Ubuntu 20.04 | Ubuntu 22.04 LTS |

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml              # Single CI/CD workflow (self-hosted runner)
│
├── backend/
│   ├── Dockerfile
│   ├── ecosystem.config.js         # PM2 config — logs to /proc/1/fd/1+2 for Docker capture
│   ├── package.json
│   └── src/
│       ├── server.js               # Express entry point, /health endpoint
│       ├── db.js                   # pg connection pool (max 20)
│       ├── routes.js               # /api/measurements CRUD + /api/measurements/trends
│       └── calculations.js         # BMI / BMR / calorie maths
│
├── frontend/
│   ├── Dockerfile                  # Multi-stage: Vite build → Nginx serve
│   ├── nginx.conf                  # Proxy /api/* → backend:3000
│   ├── vite.config.js
│   └── src/
│       ├── App.jsx
│       ├── api.js                  # Axios client — relative URLs via Nginx proxy
│       └── components/
│           ├── MeasurementForm.jsx
│           └── TrendChart.jsx
│
├── database/
│   ├── setup-database.sh
│   └── (init scripts run via docker-entrypoint-initdb.d)
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml          # Scrape: prometheus, node-exporter, cadvisor
│   ├── grafana/
│   │   ├── dashboards/
│   │   │   ├── docker-monitoring.json   # 23 panels: container + host metrics
│   │   │   ├── docker-logs.json         # 8 panels: all-container log streams
│   │   │   └── application-logs.json    # 3 panels: bmi-* containers only
│   │   └── provisioning/
│   │       ├── dashboards/dashboards.yml
│   │       └── datasources/datasources.yml
│   ├── loki/
│   │   └── loki-config.yml
│   └── promtail/
│       └── promtail-config.yml     # docker_sd_configs, labels: container_name, service
│
├── scripts/
│   ├── setup-docker.sh             # Install Docker + Compose on Ubuntu
│   ├── setup-github-runner.sh      # Interactive runner registration
│   ├── health-check.sh             # Verify all service endpoints
│   └── get-public-ip.sh
│
├── docker-compose.yml              # Phase 1: postgres + backend + frontend
├── docker-compose.monitoring.yml   # Phase 2: prometheus + grafana + loki + promtail + cadvisor + node-exporter
├── docker-compose.prod.yml         # Optional production overrides
├── .env.example                    # Template for required environment variables
│
├── PHASE1-DEPLOYMENT.md            # Step-by-step Phase 1 guide
├── PHASE2-MONITORING.md            # Step-by-step Phase 2 guide
├── PHASE3-CICD.md                  # Step-by-step Phase 3 guide (runner setup)
├── SETUP-GITHUB-RUNNER.md          # Runner reference
└── QUICKSTART-RUNNER.md            # Runner quick reference
```

### Key File Reference

| File | Edit When |
|------|-----------|
| `docker-compose.yml` | Adding services, changing ports, environment |
| `docker-compose.monitoring.yml` | Changing monitoring topology |
| `.env` | Rotating passwords, changing the EC2 IP |
| `.github/workflows/deploy.yml` | Changing CI/CD steps or triggers |
| `backend/src/routes.js` | Adding / changing API endpoints |
| `backend/src/calculations.js` | Changing BMI/BMR formulae |
| `frontend/nginx.conf` | Changing proxy rules, adding caching headers |
| `monitoring/prometheus/prometheus.yml` | Adding scrape targets |
| `monitoring/grafana/dashboards/*.json` | Updating Grafana panels |
| `monitoring/promtail/promtail-config.yml` | Changing log labels or pipeline stages |

---

## Quick Start

**Estimated time: 15 minutes** (assuming Docker is installed)

```bash
# 1. SSH into EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# 2. Clone
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# 3. Configure environment
cp .env.example .env
nano .env
# Set POSTGRES_PASSWORD and FRONTEND_URL (your EC2 public IP)

# 4. Run everything (Phase 1 + 2)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build

# 5. Wait ~30 seconds for health checks to pass
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

**Access points after startup:**

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | `http://YOUR_EC2_IP` | — |
| Grafana | `http://YOUR_EC2_IP:3001` | admin / admin |
| Prometheus | `http://YOUR_EC2_IP:9090` | — |

---

## Phase 1 — Application Deployment

**Detailed guide:** [PHASE1-DEPLOYMENT.md](PHASE1-DEPLOYMENT.md)

### Step 1 — Install Docker

```bash
chmod +x scripts/setup-docker.sh
./scripts/setup-docker.sh

# Verify
docker --version          # 25.0+
docker compose version    # 2.24+
```

### Step 2 — Configure Environment

```bash
cp .env.example .env
nano .env
```

`.env` must contain:

```env
POSTGRES_USER=bmi_user
POSTGRES_PASSWORD=YourSecurePassword123!    # Change this
POSTGRES_DB=bmidb
NODE_ENV=production
FRONTEND_URL=http://YOUR_EC2_PUBLIC_IP      # Replace with actual IP
```

> `.env` is in `.gitignore`. Never commit it. The `POSTGRES_PASSWORD` is **required** — startup fails without it.

### Step 3 — Deploy

```bash
docker compose up -d --build

# Watch startup
docker compose logs -f
```

**Expected startup order:** postgres (healthy) → backend (healthy) → frontend (healthy)

### Step 4 — Validate

```bash
# All three containers should show (healthy)
docker compose ps

# Backend is up
curl http://localhost/health          # {"status":"ok","environment":"production"}

# API responds
curl http://localhost/api/measurements   # {"rows":[...]}

# Frontend serves HTML
curl -s http://localhost | head -5
```

> **Note on /health:** The health endpoint is served through Nginx on port 80 (not port 3000 directly). Port 3000 is internal to the Docker network.

### Database Initialisation

On first start, PostgreSQL auto-runs all `*.sql` files in `database/init-scripts/` via `docker-entrypoint-initdb.d`. This creates the `measurements` table and all required columns. This only runs once — if the volume already exists, init scripts are skipped.

To force re-initialise:

```bash
docker compose down -v    # DELETES all data
docker compose up -d
```

---

## Phase 2 — Monitoring Stack

**Detailed guide:** [PHASE2-MONITORING.md](PHASE2-MONITORING.md)

### Deploy Monitoring

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# 9 containers should be running
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

### Validate

```bash
# Prometheus is healthy
curl http://localhost:9090/-/healthy

# Prometheus scrape targets — all should show state: "up"
curl -s http://localhost:9090/api/v1/targets | \
  python3 -c "import sys,json; [print(t['labels']['job'], t['health']) for t in json.load(sys.stdin)['data']['activeTargets']]"

# Grafana responds
curl -s http://localhost:3001/api/health | python3 -m json.tool
```

### Pre-Provisioned Dashboards

Three dashboards are automatically provisioned via `monitoring/grafana/provisioning/` on Grafana startup. No manual import required.

#### docker-monitoring.json — 23 panels, 6 rows

| Row | Panels |
|-----|--------|
| Overview | Running containers (stat), Host CPU % (stat), Host Memory % (stat), Max Disk % (stat) |
| Container CPU & Memory | CPU % timeseries (per container), Memory working set timeseries |
| Container Network I/O | Network RX bytes/s, Network TX bytes/s |
| Host CPU | Stacked CPU by mode (user/system/iowait/steal), CPU gauge |
| Host Memory & Load | Memory breakdown (used/buffers/cached/free), Load average 1m/5m/15m |
| Disk & Network I/O | Disk read/write bytes/s, Host network RX/TX (excluding lo/docker/veth) |
| Disk Space | Bar gauge % by mountpoint, Used vs Free timeseries |

**Prometheus data sources:**

```promql
# Container CPU %
sum(rate(container_cpu_usage_seconds_total{name=~"bmi-backend|bmi-frontend|..."}[5m])) by (name) * 100

# Container memory (working set)
container_memory_working_set_bytes{name=~"..."}

# Host CPU %
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Host memory used
node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes
```

#### docker-logs.json — 8 panels

All 9 containers are queried with explicit label selectors (no wildcards — Loki requires indexed labels):

```logql
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres|/cadvisor|/grafana|/loki|/node-exporter|/prometheus|/promtail"}
```

Panels include: all-container log stream, log rate graph, error-only filter, and per-service streams.

#### application-logs.json — 3 panels

Scoped to the three application containers:

```logql
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"}
```

### How Logs Flow

```
Docker container stdout/stderr
        ↓
/var/lib/docker/containers/<id>/*-json.log
        ↓
Promtail (docker_sd_configs on /var/run/docker.sock)
  → labels: container_name, service, stream
        ↓
Loki (http://loki:3100/loki/api/v1/push)
        ↓
Grafana (Loki datasource uid: loki)
```

> **Important:** For logs to appear, the process inside the container must write to **stdout/stderr**, not to files. See the PM2 configuration note below.

### PM2 and Docker Logging

The backend uses PM2 (`ecosystem.config.js`). PM2 by default writes to `./logs/*.log` files inside the container, which Docker cannot capture. The file is configured to redirect to Docker stdout/stderr:

```javascript
// ecosystem.config.js
error_file: '/proc/1/fd/2',     // → Docker stderr
out_file:   '/proc/1/fd/1',     // → Docker stdout
log_file:   '/dev/null',
```

If you see no backend logs in Grafana, verify this setting is in place, then rebuild:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build backend
docker logs bmi-backend    # Should show startup messages
```

### PostgreSQL Log Visibility

PostgreSQL is configured with verbose logging so database activity appears in the Grafana logs panel. The `command:` block in `docker-compose.yml` passes these flags:

```
log_connections=on           → logs every new connection
log_disconnections=on        → logs every disconnect
log_statement=mod            → logs INSERT / UPDATE / DELETE / DDL
log_min_duration_statement=500  → logs any query > 500 ms
log_min_messages=warning     → logs warnings and above
```

### Loki Health Status

Loki may show `(unhealthy)` in `docker ps -a`. This is a known false positive caused by the default healthcheck timing. Loki is functional — verify with:

```bash
curl http://localhost:3100/ready    # Should return "ready"
curl http://localhost:3100/metrics  # Should return Prometheus metrics
```

---

## Phase 3 — CI/CD with Self-Hosted Runner

**Detailed guide:** [PHASE3-CICD.md](PHASE3-CICD.md)

### Why Self-Hosted

| | GitHub Cloud Runner | Self-Hosted (EC2) |
|---|---|---|
| Repo access | Needs SSH secrets | Direct — it's the same machine |
| Docker builds | Requires Docker Hub push/pull | Local build only |
| Deploy time | ~7–10 min | **~2–3 min** |
| Cost | Uses free minutes quota | Free (your EC2) |
| External dependencies | Docker Hub account | None |

### Install the Runner

**Step 1** — Register on GitHub

1. Go to your repository → **Settings** → **Actions** → **Runners**
2. Click **New self-hosted runner**
3. Select: **Linux** / **x64**
4. Keep the page open — you will copy commands from it

**Step 2** — Install on EC2

```bash
# On EC2
mkdir -p ~/actions-runner && cd ~/actions-runner

# Download (copy the exact URL and hash from GitHub's page — version changes)
curl -o actions-runner-linux-x64.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.x.x/actions-runner-linux-x64-2.x.x.tar.gz

tar xzf ./actions-runner-linux-x64.tar.gz

# Configure — copy the full ./config.sh line from GitHub's page (includes your one-time token)
./config.sh --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN
# Accept all defaults: Enter through runner group, runner name, and _work folder
```

**Step 3** — Install as a systemd service (auto-starts on reboot)

```bash
cd ~/actions-runner
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
sudo ./svc.sh status     # Should show: active (running)
```

**Step 4** — Add ubuntu to docker group

```bash
sudo usermod -aG docker ubuntu
newgrp docker
docker ps    # Should work without sudo
```

**Step 5** — Verify online

GitHub → **Settings** → **Actions** → **Runners** → your runner should show **Idle** ✅

> If it shows **Offline** after configuration:
> ```bash
> sudo systemctl restart actions.runner.*
> sudo systemctl status  actions.runner.*
> ```

### The Workflow File

**Location:** `.github/workflows/deploy.yml`

**Triggers:**
- Push to `main` branch → automatic
- Manual dispatch → GitHub Actions → Run workflow

**Runner:** `runs-on: self-hosted`  — runs **on your EC2**, not GitHub's cloud

**Steps executed on EC2:**

1. `actions/checkout@v4` — checks out code into `~/actions-runner/_work/`
2. Pull latest code into `/home/ubuntu/3-tier-docker-compose-monitoring-ubuntu`
3. `docker compose build --no-cache` — builds backend and frontend images locally
4. `docker compose up -d --force-recreate --no-deps backend frontend` — rolling restart of app containers
5. Ensure monitoring stack is running
6. Health checks — backend (`curl /health`), frontend (`curl localhost`), Grafana, Prometheus
7. `docker compose ps` — final container status
8. `docker image prune -af --filter "until=24h"` — clean old images
9. Deployment summary with public IP and service URLs

**Deploy a change:**

```bash
# On your local machine
git add .
git commit -m "feat: your change"
git push origin main

# Watch progress
# https://github.com/YOUR_USERNAME/YOUR_REPO/actions
```

---

## Configuration Reference

### .env Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `POSTGRES_USER` | Yes | `bmi_user` | PostgreSQL username |
| `POSTGRES_PASSWORD` | **Yes** | — | PostgreSQL password (no default) |
| `POSTGRES_DB` | Yes | `bmidb` | Database name |
| `NODE_ENV` | Yes | `production` | Node environment |
| `FRONTEND_URL` | Yes | `http://localhost` | EC2 public IP — used in CORS |

### Prometheus Scrape Targets

Defined in `monitoring/prometheus/prometheus.yml`:

| Job | Target | Metrics |
|-----|--------|---------|
| `prometheus` | `localhost:9090` | Prometheus self-metrics |
| `node-exporter` | `node-exporter:9100` | Host CPU / memory / disk / network |
| `cadvisor` | `cadvisor:8080` | Per-container CPU / memory / network |

> The backend does **not** have a Prometheus `/metrics` endpoint. App-layer metrics are available only through cAdvisor container-level data.

To add a new scrape target, edit `monitoring/prometheus/prometheus.yml` and restart Prometheus:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart prometheus
```

### Grafana Provisioning

Grafana auto-loads on startup via bind mounts:

| Path in container | Local path | Controls |
|-------------------|-----------|---------|
| `/etc/grafana/provisioning` | `monitoring/grafana/provisioning/` | Datasource + dashboard config |
| `/var/lib/grafana/dashboards` | `monitoring/grafana/dashboards/` | Dashboard JSON files |

`updateIntervalSeconds: 10` in `dashboards.yml` means any change to a `*.json` dashboard file is picked up within 10 seconds — **no Grafana restart needed**.

### Loki Labels

Promtail tags every log line with:

| Label | Example value | Source |
|-------|--------------|--------|
| `container_name` | `/bmi-backend` | `__meta_docker_container_name` |
| `service` | `backend` | `com.docker.compose.service` label |
| `stream` | `stdout` | Docker JSON log field |

Use `container_name` in LogQL queries. The leading `/` is part of the value:

```logql
{container_name="/bmi-backend"}
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"}
```

---

## API Reference

Base URL: `http://YOUR_EC2_IP/api` (proxied through Nginx on port 80)

### POST /api/measurements

Create a new measurement.

**Request body:**

```json
{
  "weightKg": 70,
  "heightCm": 175,
  "age": 30,
  "sex": "male",
  "activity": "moderate",
  "measurementDate": "2026-04-02"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `weightKg` | number | ✅ | Positive |
| `heightCm` | number | ✅ | Positive |
| `age` | number | ✅ | Positive |
| `sex` | string | ✅ | `"male"` or `"female"` |
| `activity` | string | No | `"sedentary"`, `"light"`, `"moderate"`, `"active"`, `"very_active"` |
| `measurementDate` | string | No | ISO date, defaults to today |

**Response 201:**

```json
{
  "measurement": {
    "id": 4,
    "weight_kg": "70.00",
    "height_cm": "175.00",
    "age": 30,
    "sex": "male",
    "activity_level": "moderate",
    "bmi": "22.9",
    "bmi_category": "Normal",
    "bmr": 1649,
    "daily_calories": 2556,
    "measurement_date": "2026-04-02T00:00:00.000Z",
    "created_at": "2026-04-02T04:12:07.114Z"
  }
}
```

**Example:**

```bash
curl -X POST http://YOUR_EC2_IP/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":70,"heightCm":175,"age":30,"sex":"male","activity":"moderate"}'
```

### GET /api/measurements

Return all measurements ordered by date descending.

```bash
curl http://YOUR_EC2_IP/api/measurements
```

**Response 200:**

```json
{ "rows": [ { ...measurement... }, ... ] }
```

### GET /api/measurements/trends

Return 30-day daily average BMI.

```bash
curl http://YOUR_EC2_IP/api/measurements/trends
```

**Response 200:**

```json
{ "rows": [ { "day": "2026-04-02T00:00:00.000Z", "avg_bmi": "22.9" } ] }
```

### GET /health

Application health check (served via Nginx on port 80).

```bash
curl http://YOUR_EC2_IP/health
```

**Response 200:**

```json
{ "status": "ok", "environment": "production" }
```

---

## Development Guide

### Local Development

```bash
# Clone
git clone https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu.git
cd 3-tier-docker-compose-monitoring-ubuntu

# Configure
cp .env.example .env
# Set FRONTEND_URL=http://localhost in .env

# Build and start
docker compose up -d --build

# Tail logs
docker compose logs -f
```

### Changing the Backend

1. Edit files in `backend/src/`
2. Rebuild and redeploy:

```bash
docker compose up -d --build backend
docker compose logs -f backend
```

3. Test:

```bash
curl http://localhost/api/measurements
curl -X POST http://localhost/api/measurements \
  -H "Content-Type: application/json" \
  -d '{"weightKg":65,"heightCm":170,"age":25,"sex":"female","activity":"light"}'
```

### Changing the Frontend

1. Edit files in `frontend/src/`
2. Rebuild:

```bash
docker compose up -d --build frontend
# Visit http://localhost in browser
```

### Adding a Database Column

1. Create a new SQL file in `database/init-scripts/` (e.g. `04-add-notes.sql`):

```sql
ALTER TABLE measurements ADD COLUMN IF NOT EXISTS notes TEXT;
```

2. For **new deployments** — the file runs automatically on `docker compose up`.

3. For **existing deployments** — run the migration manually:

```bash
docker compose exec postgres psql -U bmi_user -d bmidb \
  -c "ALTER TABLE measurements ADD COLUMN IF NOT EXISTS notes TEXT;"
```

### Debugging

```bash
# Shell into a container
docker compose exec backend sh
docker compose exec postgres sh

# Check environment variables
docker compose exec backend env | grep -E 'NODE|DATABASE|PORT'

# Test DB connectivity from backend
docker compose exec backend ping postgres
docker compose exec backend nc -zv postgres 5432

# psql shell
docker compose exec postgres psql -U bmi_user -d bmidb

# List tables
\dt

# Describe table
\d measurements

# Check specific rows
SELECT * FROM measurements ORDER BY created_at DESC LIMIT 5;
```

---

## Operations Runbook

### Start / Stop / Restart

```bash
# Start everything (app + monitoring)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Graceful stop (keeps volumes)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down

# Restart a single service
docker compose restart backend

# Restart with rebuild
docker compose up -d --build backend
```

### Force-recreate Without Rebuild

```bash
# Restart app containers without touching database or monitoring
docker compose up -d --force-recreate --no-deps backend frontend
```

### Update Running Stack from Git

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml ps
```

### Full Teardown and Rebuild

```bash
# Stop + remove containers (data is safe in volumes)
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down

# Rebuild images and start
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
```

### Teardown Including Data (⚠️ deletes database)

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml down --volumes
```

### Database Backup

```bash
# Dump to file
docker compose exec postgres pg_dump -U bmi_user bmidb \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed dump
docker compose exec postgres pg_dump -U bmi_user bmidb \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Database Restore

```bash
# From plain SQL
cat backup.sql | docker compose exec -T postgres psql -U bmi_user -d bmidb

# From compressed
gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U bmi_user -d bmidb
```

### View Logs

```bash
# All containers, follow
docker compose logs -f

# Single container
docker compose logs -f backend

# Last 200 lines
docker compose logs --tail=200 backend

# Filter errors (bash only)
docker compose logs backend 2>&1 | grep -i error
```

### Disk Space

```bash
# Host disk
df -h

# Docker objects
docker system df

# Clean unused images and build cache (safe — won't touch running containers)
docker image prune -af --filter "until=24h"
docker builder prune -af

# Nuclear clean (removes ALL unused docker objects)
docker system prune -af
```

### GitHub Actions Runner

```bash
# Check runner status
cd ~/actions-runner
sudo ./svc.sh status

# Start / stop
sudo ./svc.sh start
sudo ./svc.sh stop

# View runner logs
sudo journalctl -u actions.runner.* --since "30 minutes ago" -f

# Re-register runner (if token expired)
cd ~/actions-runner
./config.sh remove --token OLD_TOKEN
# Get new token from GitHub: Settings → Actions → Runners → New self-hosted runner
./config.sh --url https://github.com/USERNAME/REPO --token NEW_TOKEN
sudo ./svc.sh install ubuntu
sudo ./svc.sh start
```

### Health Check Script

```bash
chmod +x scripts/health-check.sh
./scripts/health-check.sh
```

---

## Monitoring & Dashboards

### Access

| URL | Service | Login |
|-----|---------|-------|
| `http://YOUR_EC2_IP:3001` | Grafana | admin / admin (change on first login) |
| `http://YOUR_EC2_IP:9090` | Prometheus | none |

### Add a Custom Grafana Dashboard

1. Build the dashboard in the Grafana UI
2. Export it: Dashboard **Settings** → **JSON Model** → copy
3. Save as `monitoring/grafana/dashboards/my-dashboard.json`
4. Grafana auto-loads it within 10 seconds (no restart)

### Add a Prometheus Scrape Target

Edit `monitoring/prometheus/prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9999']
    metrics_path: '/metrics'
    scrape_interval: 15s
```

Then:

```bash
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml restart prometheus
```

### Useful PromQL Queries

```promql
# Container memory working set (bytes)
container_memory_working_set_bytes{name=~"bmi-.*"}

# Container CPU % per container
sum(rate(container_cpu_usage_seconds_total{name=~"bmi-.*"}[5m])) by (name) * 100

# Host total CPU %
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Host memory used %
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Disk usage % per mountpoint
(1 - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay|squashfs"} /
     node_filesystem_size_bytes{fstype!~"tmpfs|overlay|squashfs"}) * 100

# Network receive rate (bytes/s)
rate(container_network_receive_bytes_total{name=~"bmi-.*"}[5m])
```

### Useful LogQL Queries

```logql
# All app containers
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"}

# Errors only
{container_name=~"/bmi-backend|/bmi-frontend|/bmi-postgres"} |~ "(?i)error|exception|fail|fatal|panic"

# Backend only
{container_name="/bmi-backend"}

# HTTP requests in frontend logs
{container_name="/bmi-frontend"} |~ "(?i)GET|POST|PUT|DELETE"

# Log rate graph
sum by (container_name) (count_over_time({container_name=~"/bmi-.*"}[1m]))
```

---

## Deployment Workflows

### Automated (Normal Path)

```
git push origin main
        ↓
GitHub webhook → self-hosted runner on EC2
        ↓
git pull → docker compose build → docker compose up --force-recreate
        ↓
Health checks (backend + frontend + Grafana + Prometheus)
        ↓
docker image prune
        ↓
Deployment summary logged to GitHub Actions
```

Monitor at: `https://github.com/YOUR_USERNAME/YOUR_REPO/actions`

### Manual Deploy

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main
docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d --build
```

### Rollback

**Option 1 — Git revert (triggers CI/CD):**

```bash
git revert HEAD
git push origin main
# CI/CD redeploys previous version
```

**Option 2 — Manual on EC2:**

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git log --oneline -10
git checkout <previous-commit-hash>
docker compose up -d --build
```

**Option 3 — Tag before deploying:**

```bash
# Before a deploy
git tag v1.2.0
git push origin v1.2.0

# Rollback
git checkout v1.2.0
docker compose up -d --build
```

### Skip CI/CD for a Commit

```bash
git commit -m "docs: update README [skip ci]"
```

---

## Troubleshooting

### Container shows (unhealthy)

```bash
# See what the health check actually returned
docker inspect bmi-backend | grep -A 20 '"Health"'

# Check logs
docker compose logs --tail=50 backend

# Manually trigger health check
curl http://localhost/health
```

**Most common cause:** backend fails to connect to PostgreSQL on first start. Wait 30–60 s for postgres to fully initialise, then:

```bash
docker compose restart backend
```

### Cannot access the application from the browser

1. Verify the EC2 Security Group allows port 80 from `0.0.0.0/0`
2. Confirm you are using the **public** IP (not `10.x.x.x`)
3. Check frontend is running: `docker compose ps bmi-frontend`
4. Check port binding: `sudo ss -tlpn | grep :80`

### Database connection errors (ECONNREFUSED / authentication failed)

```bash
# Is postgres running?
docker compose ps bmi-postgres

# Can the backend reach it?
docker compose exec backend ping postgres

# Is the password correct?
docker compose exec postgres pg_isready -U bmi_user -d bmidb

# Check env vars loaded into backend
docker compose exec backend env | grep DATABASE
```

### No logs in Grafana (backend or postgres)

**Backend:** Confirm `ecosystem.config.js` redirects to `/proc/1/fd/1` and `/proc/1/fd/2`, then rebuild.

```bash
docker compose up -d --build backend
docker logs bmi-backend  # Must show startup messages
```

**Postgres:** Confirm `command:` block with `-c log_statement=mod` is in `docker-compose.yml`, then recreate:

```bash
docker compose up -d --force-recreate postgres
docker logs bmi-postgres  # Must show connection log lines
```

### Grafana shows "datasource not found"

```bash
# Verify datasource UIDs
docker compose exec grafana cat /etc/grafana/provisioning/datasources/datasources.yml

# Restart Grafana to re-apply provisioning
docker compose restart grafana
```

### Loki shows (unhealthy)

This is a false positive. Verify Loki is actually working:

```bash
curl http://localhost:3100/ready    # → "ready"
```

If it returns `ready`, the container is functional; the Docker healthcheck is misconfigured. Check Grafana → Explore → Loki datasource — if it queries successfully, ignore the status.

### Runner shows Offline in GitHub

```bash
cd ~/actions-runner
sudo systemctl status actions.runner.*   # Is it running?
sudo ./svc.sh restart                    # Restart it
```

If it still shows offline after restart, the registration token may have expired. Re-register:

```bash
./config.sh remove --token $(cat .runner | python3 -c "import sys,json;print(json.load(sys.stdin)['clientId'])" 2>/dev/null || echo "YOUR_OLD_TOKEN")
# Get new token from GitHub → Settings → Actions → Runners → New self-hosted runner
./config.sh --url https://github.com/USERNAME/REPO --token NEW_TOKEN
sudo ./svc.sh install ubuntu && sudo ./svc.sh start
```

### Disk full during CI/CD build

```bash
df -h                                             # Check usage
docker system df                                  # Check Docker usage
docker image prune -af --filter "until=24h"       # Remove old images
docker builder prune -af                          # Remove build cache
```

---

## Security

### What Is Already Protected

| Area | Control |
|------|---------|
| Database port | Not published to host; only reachable on `bmi-backend-network` |
| Backend port | Not published to host; only reachable via Nginx proxy |
| Credentials | In `.env` (gitignored); never hardcoded |
| SQL injection | Parameterised queries (`$1`, `$2`, ...) in all database calls |
| CORS | Restricted to `FRONTEND_URL` in production |
| Container networking | Three isolated networks; frontend cannot reach database directly |
| Container image | Alpine base images (minimal attack surface) |

### Recommended Hardening for Production

**1. Change Grafana admin password** on first login (Grafana will prompt you).

**2. HTTPS** — add Nginx + Certbot:

```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

**3. Rate limiting** — add to `frontend/nginx.conf`:

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
location /api/ {
    limit_req zone=api burst=20 nodelay;
    proxy_pass http://backend:3000/api/;
}
```

**4. Security headers** — add to `frontend/nginx.conf`:

```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
```

**5. Image vulnerability scanning:**

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image bmi-backend:latest
```

### Security Checklist

- [ ] `POSTGRES_PASSWORD` is strong and unique
- [ ] `.env` is never committed (verify with `git status`)
- [ ] Grafana password changed from `admin`
- [ ] Security Group restricts Grafana (3001) and Prometheus (9090) to your IP only
- [ ] SSH uses key auth only (no password auth on EC2)
- [ ] Regular `docker image prune` to remove old layers
- [ ] HTTPS enabled if publicly accessible

---

## Performance

### Measured Resource Usage (t2.medium at idle)

| Container | CPU | RAM |
|-----------|-----|-----|
| bmi-frontend | <1% | ~20 MB |
| bmi-backend | <1% | ~80 MB |
| bmi-postgres | <1% | ~50 MB |
| prometheus | 1–2% | ~200 MB |
| grafana | <1% | ~150 MB |
| loki | <1% | ~100 MB |
| promtail | <1% | ~50 MB |
| cadvisor | 1–2% | ~100 MB |
| node-exporter | <1% | ~20 MB |
| **Total** | **~7%** | **~770 MB** |

During a CI/CD build, the runner can use 50–100% CPU for 30–60 s while building Docker images.

### Tuning Tips

**PostgreSQL connection pool** is set to `max: 20` in `backend/src/db.js`. For a t2.medium running a single-backend-instance app, 20 is more than adequate.

**Prometheus retention** is capped at 15 days / 10 GB in `docker-compose.monitoring.yml`. Reduce if disk is constrained:

```yaml
command:
  - --storage.tsdb.retention.time=7d
  - --storage.tsdb.retention.size=5GB
```

**Loki retention** — edit `monitoring/loki/loki-config.yml`:

```yaml
limits_config:
  retention_period: 168h    # 7 days
```

**Grafana dashboard refresh** — change from 15 s to 30 s or 1 m in panel settings to reduce Prometheus query load.

---

## Roadmap

| Status | Item |
|--------|------|
| ✅ | Three-tier application (React / Node / PostgreSQL) |
| ✅ | Docker Compose orchestration (3 services) |
| ✅ | Monitoring stack (Prometheus / Grafana / Loki) |
| ✅ | Self-hosted GitHub Actions CI/CD |
| ✅ | Pre-provisioned Grafana dashboards (23 panels) |
| ✅ | Zero-downtime rolling deploys |
| 📋 | HTTPS with Let's Encrypt |
| 📋 | Automated unit + integration tests in CI |
| 📋 | Kubernetes migration (Helm charts) |
| 📋 | Multi-AZ with RDS (PostgreSQL HA) |
| 📋 | Distributed tracing (Tempo) |
| 📋 | Terraform for EC2 provisioning |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit with conventional format: `feat:`, `fix:`, `docs:`, `refactor:`
4. Push and open a Pull Request

**Contribution areas:**
- Additional Grafana dashboards
- Improved error handling
- Automated test coverage
- Kubernetes manifests
- Terraform modules

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
