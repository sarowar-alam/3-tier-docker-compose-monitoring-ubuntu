# Self-Hosted GitHub Runner Setup

This guide sets up a GitHub Actions self-hosted runner on your EC2 instance for automated CI/CD.

## Why Self-Hosted Runner?

✅ **No Docker Hub needed** - Build and deploy locally  
✅ **Faster deployments** - No image push/pull over internet  
✅ **More secure** - No SSH keys in GitHub secrets  
✅ **Cost effective** - Use your existing EC2 resources  
✅ **Simpler workflow** - Direct access to Docker on EC2

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  Developer                                          │
│     │                                               │
│     │ git push                                      │
│     ↓                                               │
│  GitHub Repository                                  │
│     │                                               │
│     │ webhook trigger                               │
│     ↓                                               │
│  ┌──────────────────────────────────────────┐      │
│  │  AWS EC2 Instance (65.0.133.186)        │      │
│  │                                          │      │
│  │  ┌────────────────────────────────────┐ │      │
│  │  │  GitHub Actions Runner (Service)   │ │      │
│  │  │                                    │ │      │
│  │  │  1. Receives job from GitHub      │ │      │
│  │  │  2. Pulls latest code             │ │      │
│  │  │  3. Builds Docker images locally  │ │      │
│  │  │  4. Restarts containers           │ │      │
│  │  │  5. Reports back to GitHub        │ │      │
│  │  └────────────────────────────────────┘ │      │
│  │                                          │      │
│  │  Docker Containers:                     │      │
│  │  - bmi-backend                          │      │
│  │  - bmi-frontend                         │      │
│  │  - bmi-postgres                         │      │
│  │  - prometheus, grafana, loki...        │      │
│  └──────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────┘
```

---

## Prerequisites

- ✅ EC2 instance running (Phase 1 complete)
- ✅ Monitoring stack active (Phase 2 complete)
- ✅ GitHub repository access
- ⚠️ **No Docker Hub account needed!**
- ⚠️ **No SSH keys in GitHub secrets needed!**

---

## Step 1: Generate SSH Keys on EC2 (For Admin Access)

**Purpose:** Create keys for your own SSH access to EC2 (optional, for security).

Run these commands **on your EC2 instance**:

```bash
# SSH to your EC2
# Then run:

cd ~
ssh-keygen -t rsa -b 4096 -C "github-actions@ec2" -f ~/.ssh/github_runner_key -N ""

# View public key
cat ~/.ssh/github_runner_key.pub

# Add to authorized_keys (for your own access)
cat ~/.ssh/github_runner_key.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Download private key to your Windows machine (optional)
# From Windows:
scp ubuntu@65.0.133.186:~/.ssh/github_runner_key C:\Users\YourName\.ssh\
```

**Note:** This step is optional and only for your own secure access. The GitHub runner will use local Docker access, not SSH.

---

## Step 2: Install GitHub Runner on EC2

### 2.1 Run Setup Script

**On your EC2 instance:**

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
chmod +x scripts/setup-github-runner.sh
./scripts/setup-github-runner.sh
```

### 2.2 Get GitHub Runner Token

1. Go to: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners/new
2. Select **Linux** and **x64**
3. **COPY THE TOKEN** shown (starts with `A...`)

**Example:**
```
A23456789ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrs
```

### 2.3 Configure Runner

**On EC2:**

```bash
cd ~/actions-runner

./config.sh --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu \
    --token YOUR_TOKEN_FROM_STEP_2.2
```

**Answer prompts:**

| Prompt | Answer |
|--------|--------|
| Runner name | `ec2-ubuntu-runner` |
| Runner group | (Press Enter for default) |
| Labels | `self-hosted,Linux,X64,aws-ec2` |
| Work folder | (Press Enter for default: `_work`) |

### 2.4 Install as Service

**On EC2:**

```bash
cd ~/actions-runner

# Install service (runs in background)
sudo ./svc.sh install

# Start service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status
```

**Expected output:**
```
● actions.runner.sarowar-alam-3-tier-docker-compose-monitoring-ubuntu.ec2-ubuntu-runner.service
   Active: active (running)
```

### 2.5 Verify in GitHub

1. Go to: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners
2. You should see: **ec2-ubuntu-runner** 🟢 Idle

---

## Step 3: Update GitHub Actions Workflows

Now update workflows to use the self-hosted runner instead of GitHub-hosted runners.

### 3.1 Update Build Workflow

The workflow will now:
- Run on your EC2 instance
- Build images locally
- No need to push to Docker Hub
- Restart containers directly

### 3.2 Update Deploy Workflow

Simplified workflow:
- No SSH needed (runs locally)
- No image pull needed (already built)
- Just restart containers

---

## Step 4: Test the Pipeline

### 4.1 Make Test Commit

**On your Windows machine:**

```powershell
cd "c:\CLOUD\OneDrive - Hogarth Worldwide\Documents\Ostad\Batch-08\module-10\3-tier-app-docker-compose"

# Make test change
echo "# Self-hosted runner test" > RUNNER-TEST.md

git add .
git commit -m "test: Self-hosted runner deployment"
git push origin main
```

### 4.2 Watch Job Execute

1. Go to: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/actions
2. See workflow running on **ec2-ubuntu-runner**
3. Watch real-time logs

**Expected flow:**
```
✓ Checkout code
✓ Build backend image (local)
✓ Build frontend image (local)
✓ Restart containers
✓ Health checks
✓ Complete!
```

### 4.3 View Runner Logs on EC2

**On EC2:**

```bash
# View runner service logs
sudo journalctl -u actions.runner.*.ec2-ubuntu-runner -f

# View worker logs
cd ~/actions-runner
tail -f _diag/Worker_*.log
```

---

## Security Configuration

### Required Ports (Security Group)

Your EC2 security group should allow:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 80 | TCP | 0.0.0.0/0 | Frontend |
| 3001 | TCP | Your IP | Grafana |
| 9090 | TCP | Your IP | Prometheus |

**No additional ports needed for GitHub runner!**

### Runner Permissions

The runner service runs as `ubuntu` user and has access to:
- Docker daemon (via docker group)
- Project directory (`~/3-tier-docker-compose-monitoring-ubuntu`)
- No root access needed for deployments

---

## Workflow Comparison

### Old Approach (GitHub-hosted + Docker Hub):

```yaml
runs-on: ubuntu-latest
steps:
  - Checkout code
  - Login to Docker Hub
  - Build images
  - Push to Docker Hub      # Upload (~200MB, 2 min)
  - SSH to EC2
  - Pull from Docker Hub    # Download (~200MB, 2 min)
  - Restart containers
```

**Total time:** ~7-10 minutes

### New Approach (Self-hosted):

```yaml
runs-on: self-hosted
steps:
  - Checkout code
  - Build images locally    # Already has cache
  - Restart containers
```

**Total time:** ~2-3 minutes ✅

---

## Troubleshooting

### Runner not showing in GitHub

**Check service status:**
```bash
sudo systemctl status actions.runner.*.ec2-ubuntu-runner
```

**Restart service:**
```bash
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Job fails: Permission denied

**Add ubuntu to docker group:**
```bash
sudo usermod -aG docker ubuntu
# Restart runner
sudo ./svc.sh stop
sudo ./svc.sh start
```

### Disk space issues

**Clean Docker:**
```bash
docker system prune -af
docker volume prune -f
```

### Runner offline after reboot

**Enable auto-start:**
```bash
sudo systemctl enable actions.runner.*.ec2-ubuntu-runner
```

---

## Monitoring the Runner

### Check Runner Status

**On EC2:**
```bash
# Service status
sudo ./svc.sh status

# Recent logs
sudo journalctl -u actions.runner.*.ec2-ubuntu-runner --since "10 minutes ago"

# Disk usage
df -h
```

### GitHub Dashboard

View runner activity:
```
https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners
```

**Metrics:**
- Online/Offline status
- Jobs completed
- Current job (if running)

---

## Maintenance

### Update Runner

**GitHub will notify when updates available:**

```bash
cd ~/actions-runner
sudo ./svc.sh stop
./config.sh remove --token YOUR_NEW_TOKEN
# Re-download and configure with new version
sudo ./svc.sh install
sudo ./svc.sh start
```

### Remove Runner

**To remove completely:**

```bash
cd ~/actions-runner
sudo ./svc.sh stop
sudo ./svc.sh uninstall
./config.sh remove --token YOUR_TOKEN
cd ~
rm -rf actions-runner
```

---

## Cost Savings

### With Self-Hosted Runner:

- ❌ No Docker Hub Pro needed ($7/month saved)
- ❌ No GitHub Actions minutes consumed (2000/month free unused)
- ✅ Use existing EC2 resources
- ✅ Faster builds (local cache)
- ✅ No internet bandwidth for image push/pull

### EC2 Resource Usage:

- **CPU:** Minimal during idle, ~50% during builds
- **Memory:** ~1GB for runner process
- **Disk:** ~2GB for runner, images built in place
- **Network:** Only GitHub API calls

---

## Advanced Configuration

### Multiple Runners (Parallel Jobs)

Add more runners for concurrent deployments:

```bash
# Runner 2
mkdir ~/actions-runner-2
cd ~/actions-runner-2
# Configure with different name: ec2-ubuntu-runner-2
```

### Runner Labels

Use custom labels to target specific runners:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, production, aws-ec2]
```

### Environment Variables

Set runner-specific environment:

```bash
# Edit ~/.bashrc
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
```

---

## Success Checklist

- [ ] Runner installed on EC2
- [ ] Runner showing as 🟢 Idle in GitHub
- [ ] Test workflow runs successfully
- [ ] Images build locally
- [ ] Containers restart automatically
- [ ] Application accessible after deployment
- [ ] Monitoring dashboards remain functional
- [ ] Runner service starts on reboot

---

## Next Steps

With self-hosted runner configured:

1. **Update workflows** - Use `runs-on: self-hosted`
2. **Remove Docker Hub** - No longer needed
3. **Remove SSH secrets** - No longer needed
4. **Test deployment** - Push code and watch

Your CI/CD is now:
- ✅ Faster (local builds)
- ✅ Simpler (no external registry)
- ✅ More secure (no secrets needed)
- ✅ Cost-effective (free)

---

**Ready to update the workflows?** Let me know and I'll modify the GitHub Actions YAML files!

---

## 🧑‍💻 Author

*Md. Sarowar Alam*  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: https://www.linkedin.com/in/sarowar/

---
