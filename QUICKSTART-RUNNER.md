# Quick Start: Self-Hosted GitHub Runner

Follow these steps to set up CI/CD with self-hosted runner on your EC2.

## Step 1: SSH to Your EC2

```powershell
ssh ubuntu@65.0.133.186
```

## Step 2: Pull Latest Code

```bash
cd ~/3-tier-docker-compose-monitoring-ubuntu
git pull origin main
```

## Step 3: Run Runner Setup Script

```bash
chmod +x scripts/setup-github-runner.sh
./scripts/setup-github-runner.sh
```

**Wait for download to complete (~2 minutes)**

## Step 4: Get GitHub Runner Token

1. Open in browser: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners/new

2. Select: **Linux** and **x64**

3. **COPY THE TOKEN** (long string starting with 'A')

## Step 5: Configure Runner

**On EC2:**

```bash
cd ~/actions-runner

./config.sh --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu --token YOUR_TOKEN_HERE
```

**When prompted, enter:**
- Runner name: `ec2-ubuntu-runner`
- Runner group: **(press Enter)**
- Labels: `self-hosted,Linux,X64,aws-ec2`
- Work folder: **(press Enter)**

## Step 6: Install as Service

```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

**Expected:** `Active: active (running)`

## Step 7: Verify in GitHub

Go to: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/settings/actions/runners

You should see: **ec2-ubuntu-runner** 🟢 **Idle**

## Step 8: Test the Pipeline

**On your Windows machine:**

```powershell
cd "c:\CLOUD\OneDrive - Hogarth Worldwide\Documents\Ostad\Batch-08\module-10\3-tier-app-docker-compose"

# Make test change
echo "# CI/CD with self-hosted runner" > RUNNER-READY.md

git add .
git commit -m "test: Self-hosted runner first deployment"
git push origin main
```

## Step 9: Watch Deployment

1. Go to: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/actions

2. Click on **Build and Deploy with Self-Hosted Runner**

3. Watch it execute on **ec2-ubuntu-runner**

**Expected flow (~3 minutes):**
```
✓ Checkout code
✓ Navigate to project directory
✓ Build and restart application
✓ Health check
✓ Show container status
✓ Cleanup old images
✓ Deployment summary
```

## Step 10: Verify Application

**Check your application:**
- Frontend: http://65.0.133.186 ✅
- Grafana: http://65.0.133.186:3001 ✅
- Backend: Working via frontend ✅

---

## What Just Happened?

When you pushed to GitHub:
1. GitHub webhook triggered runner on your EC2
2. Runner pulled your code locally
3. Built Docker images on EC2 (fast, uses cache)
4. Restarted only backend/frontend (zero downtime)
5. Ran health checks
6. Reported success back to GitHub

**No Docker Hub needed!** ✅
**No SSH secrets!** ✅
**Faster deployments!** ✅

---

## Troubleshooting

### Runner not showing in GitHub?

```bash
cd ~/actions-runner
sudo ./svc.sh status
# If not running:
sudo ./svc.sh start
```

### Permission denied errors?

```bash
sudo usermod -aG docker ubuntu
sudo ./svc.sh restart
```

### Runner offline?

```bash
cd ~/actions-runner
./config.sh remove --token NEW_TOKEN
# Get new token from GitHub
./config.sh --url https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu --token NEW_TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
```

---

## Daily Usage

**Normal workflow:**
```powershell
# Make changes to code
code backend/src/server.js

# Commit and push
git add .
git commit -m "feat: Add new feature"
git push origin main

# GitHub Actions automatically deploys! ✅
```

**Monitor deployment:**
- GitHub Actions: https://github.com/sarowar-alam/3-tier-docker-compose-monitoring-ubuntu/actions
- EC2 Logs: `ssh ubuntu@65.0.133.186 "sudo journalctl -u actions.runner.* -f"`

---

**Phase 3 Complete! 🎉**

Your full stack is now:
- ✅ Application running (Phase 1)
- ✅ Monitoring active (Phase 2)
- ✅ CI/CD automated (Phase 3)

**From now on:** Just push code and watch it deploy automatically!
