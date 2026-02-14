# Phase 2: Add Monitoring Stack with Docker Compose

Welcome to Phase 2! Your three-tier application is now running on EC2. In this phase, you'll add comprehensive monitoring and logging to observe your application's health, performance, and troubleshoot issues.

## What You'll Add

A complete observability stack with 6 new containers:

```
┌─────────────────────────────────────────────┐
│           AWS EC2 Ubuntu Instance           │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │     Application Stack (Phase 1)      │  │
│  │  Frontend → Backend → PostgreSQL     │  │
│  └──────────────────────────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │     Monitoring Stack (Phase 2)       │  │
│  │                                      │  │
│  │  ┌──────────┐  ┌──────────┐        │  │
│  │  │ Grafana  │◄─│Prometheus│        │  │
│  │  │  :3001   │◄─│   :9090  │        │  │
│  │  └─────▲────┘  └─────▲────┘        │  │
│  │        │             │              │  │
│  │  ┌─────┴────┐  ┌─────┴─────┐      │  │
│  │  │   Loki   │  │  cAdvisor │      │  │
│  │  │  :3100   │  │   :8080   │      │  │
│  │  └─────▲────┘  └───────────┘      │  │
│  │        │                           │  │
│  │  ┌─────┴────┐  ┌─────────────┐    │  │
│  │  │ Promtail │  │Node Exporter│    │  │
│  │  └──────────┘  └─────────────┘    │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Components Explained

**Prometheus** - Collects and stores metrics from:
- Backend health endpoint
- Container metrics (cAdvisor)
- Host system metrics (Node Exporter)

**Grafana** - Visualizes metrics with dashboards:
- Container CPU, memory, network usage
- Application logs in real-time
- System health overview

**Loki** - Aggregates logs from all Docker containers

**Promtail** - Collects logs from Docker and sends to Loki

**cAdvisor** - Exposes container resource usage metrics

**Node Exporter** - Exposes host system metrics (CPU, disk, memory)

---

## Prerequisites

✅ **Phase 1 Completed** - Application is running and healthy
✅ **EC2 Instance** - Recommend t2.medium (2 vCPU, 4GB RAM) minimum
✅ **SSH Access** - Connected to your EC2 instance

---

## Step 1: Verify Phase 1 is Running

Connect to your EC2 and check application status:

```bash
ssh -i "your-key.pem" ubuntu@YOUR_EC2_PUBLIC_IP

cd ~/3-tier-docker-compose-monitoring-ubuntu

# Check application is running
docker compose ps
```

**Expected output (all healthy):**
```
NAME             STATUS
bmi-postgres     Up (healthy)
bmi-backend      Up (healthy)
bmi-frontend     Up (healthy)
```

If not healthy, check logs:
```bash
docker compose logs -f
```

---

## Step 2: Pull Latest Code (Includes Monitoring Files)

Monitoring files are already in your repository:

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main
```

**New files added:**
```
monitoring/
├── prometheus/
│   └── prometheus.yml          # Metrics scraping config
├── loki/
│   └── loki-config.yml        # Log aggregation config
├── promtail/
│   └── promtail-config.yml    # Log collection config
└── grafana/
    ├── provisioning/
    │   ├── datasources/
    │   │   └── datasources.yml # Auto-configure data sources
    │   └── dashboards/
    │       └── dashboards.yml  # Auto-load dashboards
    └── dashboards/
        ├── docker-monitoring.json    # Container metrics
        └── application-logs.json     # Log viewer

docker-compose.monitoring.yml   # Monitoring stack definition
scripts/
└── start-with-monitoring.sh    # Helper script to start everything
```

Verify files exist:
```bash
ls -la monitoring/
ls -la docker-compose.monitoring.yml
```

---

## Step 3: Update EC2 Security Group

Add port 3001 for Grafana access.

### Via AWS Console:

1. Go to **EC2 Console** → **Security Groups**
2. Find your instance's security group
3. Click **Edit inbound rules**
4. Click **Add rule**
   - **Type:** Custom TCP
   - **Port:** 3001
   - **Source:** My IP (safer) or 0.0.0.0/0 (public access)
   - **Description:** Grafana Dashboard
5. Optional: Add port 9090 for Prometheus (only from your IP)
6. Click **Save rules**

### Via AWS CLI:

```bash
# Get your security group ID
SECURITY_GROUP_ID=$(aws ec2 describe-instances \
  --instance-ids YOUR_INSTANCE_ID \
  --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
  --output text)

# Add Grafana port
aws ec2 authorize-security-group-ingress \
  --group-id $SECURITY_GROUP_ID \
  --protocol tcp \
  --port 3001 \
  --cidr YOUR_IP/32  # Replace with your IP
```

---

## Step 4: Start Monitoring Stack

### Option A: Start Everything at Once (Recommended)

Use the helper script:

```bash
bash scripts/start-with-monitoring.sh
```

This script:
- Starts main application (if not running)
- Starts monitoring stack
- Shows status and access URLs

### Option B: Start Monitoring Manually

Start monitoring stack alongside your app:

```bash
# Application should already be running from Phase 1
docker compose ps

# Start monitoring stack
docker compose -f docker-compose.monitoring.yml up -d
```

---

## Step 5: Verify Monitoring Services

### Check Container Status

```bash
# View all monitoring containers
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

### View Logs

```bash
# All monitoring logs
docker compose -f docker-compose.monitoring.yml logs -f

# Specific service
docker compose -f docker-compose.monitoring.yml logs -f grafana
```

---

## Step 6: Access Grafana Dashboard

### Open Grafana in Browser

```
http://YOUR_EC2_PUBLIC_IP:3001
```

**Default Login:**
- Username: `admin`
- Password: `admin`

**First time login:**
1. You'll be prompted to change password
2. Choose a strong password or click "Skip" for demo purposes

---

## Step 7: Explore Pre-configured Dashboards

Dashboards are auto-loaded! No manual import needed.

### Available Dashboards:

1. **Docker Container Monitoring**
   - Navigate: Dashboards → Browse → "Docker Container Monitoring"
   - Shows: CPU usage, memory usage, network I/O per container
   - Graphs: Real-time metrics for bmi-frontend, bmi-backend, bmi-postgres

2. **Application Logs**
   - Navigate: Dashboards → Browse → "Application Logs"
   - Shows: Live logs from all containers
   - Features:
     - Filter by container
     - Search for errors
     - Time-based log browsing

### Exploring Dashboards:

**Container CPU Usage:**
- See which container uses most CPU
- Identify performance bottlenecks
- Track trends over time

**Memory Usage:**
- Monitor memory consumption
- Set alerts if approaching limits
- Detect memory leaks

**Network I/O:**
- Track incoming/outgoing traffic
- Identify network-heavy operations
- Debug connectivity issues

**Logs Panel:**
- Real-time log streaming
- Search with regex patterns
- Filter by severity (error, warn, info)

---

## Step 8: Query Logs with Loki

### Via Grafana Explore:

1. Click **Explore** (compass icon) in left sidebar
2. Select **Loki** as data source
3. Try these queries:

**View all application logs:**
```logql
{container_name=~"bmi-.*"}
```

**View backend logs only:**
```logql
{container_name="bmi-backend"}
```

**Search for errors:**
```logql
{container_name=~"bmi-.*"} |~ "(?i)error|exception|fail"
```

**Count log rate:**
```logql
sum(rate({container_name=~"bmi-.*"}[1m])) by (container_name)
```

**Filter by time range:**
- Use time picker in top-right
- Select last 15 minutes, 1 hour, 24 hours, etc.

### LogQL Query Examples:

```logql
# PostgreSQL connection logs
{container_name="bmi-postgres"} |~ "connection"

# Backend API requests
{container_name="bmi-backend"} |= "POST" or "GET"

# Recent errors (last 5 minutes)
{container_name=~"bmi-.*"} |~ "error" [5m]

# Nginx access logs
{container_name="bmi-frontend"} |= "GET"
```

---

## Step 9: Access Prometheus (Optional)

### Direct Prometheus Access:

```
http://YOUR_EC2_PUBLIC_IP:9090
```

**Use Cases:**
- Write custom PromQL queries
- Check scrape targets status
- View raw metrics
- Set up custom alerts

### Useful Prometheus Queries:

**Container memory usage:**
```promql
container_memory_usage_bytes{name=~"bmi-.*"}
```

**Container CPU usage rate:**
```promql
rate(container_cpu_usage_seconds_total{name=~"bmi-.*"}[5m]) * 100
```

**Backend uptime:**
```promql
up{job="backend"}
```

**System memory free:**
```promql
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

---

## Step 10: Customize Dashboards (Optional)

### Create Custom Dashboard:

1. In Grafana, click **+ → Dashboard**
2. Click **Add visualization**
3. Select **Prometheus** data source
4. Enter PromQL query (e.g., `container_memory_usage_bytes`)
5. Configure visualization type (Graph, Gauge, Stat)
6. Click **Save dashboard**

### Import Community Dashboards:

1. Go to **Dashboards → Import**
2. Enter dashboard ID from [grafana.com/dashboards](https://grafana.com/grafana/dashboards/)
3. Popular IDs:
   - **893** - Docker and system monitoring
   - **1860** - Node Exporter Full
   - **14282** - cAdvisor dashboard
4. Click **Load** → Select Prometheus data source → **Import**

---

## Common Commands Reference

### Managing Monitoring Stack

```bash
# Start monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Stop monitoring
docker compose -f docker-compose.monitoring.yml down

# Restart monitoring
docker compose -f docker-compose.monitoring.yml restart

# View logs
docker compose -f docker-compose.monitoring.yml logs -f [service]

# Rebuild monitoring services
docker compose -f docker-compose.monitoring.yml up -d --build
```

### Combined Application + Monitoring

```bash
# Start both
bash scripts/start-with-monitoring.sh

# Stop both
docker compose down
docker compose -f docker-compose.monitoring.yml down

# View all containers
docker ps

# View all logs
docker compose logs -f && \
docker compose -f docker-compose.monitoring.yml logs -f
```

---

## Troubleshooting

### Issue: Grafana shows "No data"

**Solution:**
1. Check Prometheus is scraping targets:
   - Go to `http://YOUR_EC2_IP:9090/targets`
   - All targets should show "UP"
2. Verify data sources in Grafana:
   - Settings → Data Sources
   - Test connection to Prometheus and Loki

### Issue: Can't access Grafana on port 3001

**Check Security Group:**
```bash
# Verify port is open
sudo netstat -tulpn | grep 3001
```

**Check Grafana container:**
```bash
docker compose -f docker-compose.monitoring.yml logs grafana
```

### Issue: High memory usage on EC2

**Check resource usage:**
```bash
docker stats

# If running on t2.small, upgrade to t2.medium:
# - Monitoring stack needs ~2GB RAM
# - Application needs ~1GB RAM
```

**Reduce retention if needed:**
Edit `monitoring/prometheus/prometheus.yml`:
```yaml
storage:
  tsdb:
    retention.time: 7d  # Reduce from 15d
```

### Issue: Prometheus not scraping backend

**Check backend is accessible:**
```bash
curl http://backend:3000/health

# If fails, check backend container is on monitoring network
docker network inspect bmi-backend-network
```

### Issue: Loki shows no logs

**Check Promtail is collecting:**
```bash
docker compose -f docker-compose.monitoring.yml logs promtail

# Verify Docker socket is mounted
docker compose -f docker-compose.monitoring.yml exec promtail ls -la /var/lib/docker/containers
```

---

## Performance Optimization

### Reduce Scrape Frequency (Lower Resource Usage)

Edit `monitoring/prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 30s  # Change from 15s
  evaluation_interval: 30s
```

Restart Prometheus:
```bash
docker compose -f docker-compose.monitoring.yml restart prometheus
```

### Limit Log Retention

Edit `monitoring/loki/loki-config.yml`:
```yaml
limits_config:
  retention_period: 72h  # 3 days instead of 7
```

Restart Loki:
```bash
docker compose -f docker-compose.monitoring.yml restart loki
```

---

## Data Persistence

Monitoring data is stored in Docker volumes:

```bash
# View monitoring volumes
docker volume ls | grep bmi

# Volumes created:
# - bmi-prometheus-data (metrics)
# - bmi-loki-data (logs)
# - bmi-grafana-data (dashboards & settings)
```

**Backup volumes** (optional):
```bash
# Backup Grafana dashboards
docker run --rm \
  -v bmi-grafana-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/grafana-backup.tar.gz -C /data .
```

---

## Monitoring Best Practices

### 1. Set Up Alerts (Advanced)

Create alert rules in Prometheus for:
- High CPU usage (> 80%)
- High memory usage (> 90%)
- Container restarts
- Backend health check failures

### 2. Regular Review

Check dashboards daily for:
- Unusual CPU/memory spikes
- Error log patterns
- Slow response times

### 3. Capacity Planning

Monitor trends over weeks:
- Peak usage times
- Growth in data/traffic
- Resource saturation points

### 4. Log Retention

Balance storage vs. observability:
- Keep 7 days for troubleshooting
- Archive important events
- Clean up old data regularly

---

## Resource Requirements

### Updated EC2 Requirements:

**Minimum:** t2.medium (2 vCPU, 4GB RAM)
- Application: ~1GB RAM
- Monitoring: ~2-3GB RAM

**Recommended:** t2.large (2 vCPU, 8GB RAM)
- Allows for traffic spikes
- Comfortable monitoring overhead
- Room for temporary workloads

### Disk Space:

- Prometheus metrics: ~500MB per day
- Loki logs: ~200MB per day  
- Recommend: 30GB+ storage

---

## What You've Accomplished

✅ **Deployed full observability stack** - 6 monitoring containers
✅ **Real-time metrics** - CPU, memory, network for all containers
✅ **Centralized logging** - All application logs in one place
✅ **Visual dashboards** - Pre-configured Grafana dashboards
✅ **Query interface** - LogQL for log analysis
✅ **Performance monitoring** - Host and container metrics

---

## Next Steps

🎉 **Phase 2 Complete!** You can now monitor your application in real-time.

**Ready for Phase 3?**
- Automate deployments with GitHub Actions
- Build Docker images in CI/CD
- Push to Docker Hub registry
- Deploy to EC2 automatically on git push

📚 **Next Guide:** `PHASE3-CICD.md`

---

## Quick Reference

### Access URLs:
```
Application:  http://YOUR_EC2_IP
Grafana:      http://YOUR_EC2_IP:3001 (admin/admin)
Prometheus:   http://YOUR_EC2_IP:9090
```

### Key Commands:
```bash
# Start monitoring
docker compose -f docker-compose.monitoring.yml up -d

# Check status
docker compose -f docker-compose.monitoring.yml ps

# View logs
docker compose -f docker-compose.monitoring.yml logs -f grafana

# Stop monitoring
docker compose -f docker-compose.monitoring.yml down
```

### Useful Queries:
```logql
# All app logs
{container_name=~"bmi-.*"}

# Search errors
{container_name=~"bmi-.*"} |~ "error"

# Backend only
{container_name="bmi-backend"}
```

---

**Happy Monitoring! 📊**
