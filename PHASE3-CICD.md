# Phase 3: CI/CD Automation with GitHub Actions

Welcome to Phase 3! Your application is running with full monitoring. Now let's automate the deployment pipeline so every code push triggers automated builds and deployments.

## What You'll Automate

```
┌──────────────────────────────────────────────────┐
│           CI/CD Pipeline Flow                    │
│                                                  │
│  1. Developer pushes code to GitHub              │
│              ↓                                   │
│  2. GitHub Actions triggers                      │
│              ↓                                   │
│  3. Build Docker images                          │
│              ↓                                   │
│  4. Push images to Docker Hub                    │
│              ↓                                   │
│  5. SSH to EC2                                   │
│              ↓                                   │
│  6. Pull latest images                           │
│              ↓                                   │
│  7. Rolling restart (zero downtime)              │
│              ↓                                   │
│  8. Health check verification                    │
│              ↓                                   │
│  9. Deployment complete! ✅                      │
└──────────────────────────────────────────────────┘
```

### Benefits:

✅ **Consistency** - Same process every time
✅ **Speed** - 5-minute deployments instead of manual steps
✅ **Rollback** - Git-based version control
✅ **Pre-built images** - Faster EC2 restarts
✅ **No manual SSH** - Push code, rest is automatic

---

## Prerequisites

✅ **Phase 1 & 2 Completed** - App running with monitoring
✅ **GitHub Repository** - `https://github.com/sarowar-alam/3-tier-docker-compose-ubuntu.git`
✅ **Docker Hub Account** - Free account (we'll create)
✅ **EC2 SSH Access** - Your private key

---

## Architecture Overview

### Before Phase 3 (Manual):
```
Developer → Git Push → GitHub
Developer → SSH to EC2 → Manual docker compose commands
```

### After Phase 3 (Automated):
```
Developer → Git Push → GitHub → Actions Build → Docker Hub
                                      ↓
                                   Deploy to EC2
```

---

## Step 1: Create Docker Hub Account & Repositories

### 1.1 Sign Up for Docker Hub

1. Go to [hub.docker.com](https://hub.docker.com/signup)
2. Sign up with email (free account)
3. Verify email address
4. Log in to Docker Hub

### 1.2 Create Repositories

Create two public repositories:

**For Backend:**
1. Click **Create Repository**
2. Name: `bmi-backend`
3. Visibility: **Public** (free unlimited pulls)
4. Description: "BMI Health Tracker - Backend API"
5. Click **Create**

**For Frontend:**
1. Click **Create Repository**
2. Name: `bmi-frontend`
3. Visibility: **Public**
4. Description: "BMI Health Tracker - Frontend React App"
5. Click **Create**

Your repositories will be:
- `YOUR_DOCKERHUB_USERNAME/bmi-backend`
- `YOUR_DOCKERHUB_USERNAME/bmi-frontend`

### 1.3 Create Access Token

1. Click your username → **Account Settings**
2. Click **Security** tab
3. Click **New Access Token**
4. Description: `GitHub Actions CI/CD`
5. Access permissions: **Read, Write, Delete**
6. Click **Generate**
7. **COPY THE TOKEN** - You won't see it again!
   - Store safely (you'll add to GitHub Secrets)

---

## Step 2: Configure GitHub Secrets

GitHub Secrets store sensitive credentials securely.

### 2.1 Access GitHub Repository Settings

1. Go to your GitHub repository:
   ```
   https://github.com/sarowar-alam/3-tier-docker-compose-ubuntu
   ```
2. Click **Settings** tab
3. In left sidebar: **Secrets and variables** → **Actions**
4. Click **New repository secret**

### 2.2 Add Secrets

Add these **5 secrets** one by one:

#### Secret 1: DOCKERHUB_USERNAME
- Name: `DOCKERHUB_USERNAME`
- Value: Your Docker Hub username (e.g., `sarowaralam`)
- Click **Add secret**

#### Secret 2: DOCKERHUB_TOKEN
- Name: `DOCKERHUB_TOKEN`
- Value: Paste the access token from Step 1.3
- Click **Add secret**

#### Secret 3: EC2_HOST
- Name: `EC2_HOST`
- Value: Your EC2 public IP address (e.g., `54.123.45.67`)
- Click **Add secret**

#### Secret 4: EC2_USER
- Name: `EC2_USER`
- Value: `ubuntu` (default EC2 Ubuntu user)
- Click **Add secret**

#### Secret 5: EC2_SSH_KEY
- Name: `EC2_SSH_KEY`
- Value: Your private SSH key content
- **How to get it:**

**On Windows (PowerShell):**
```powershell
Get-Content "C:\path\to\your-key.pem" | clip
# Now paste from clipboard
```

**On Linux/Mac:**
```bash
cat ~/.ssh/your-key.pem
# Copy entire output including -----BEGIN and -----END lines
```

- Paste entire key including:
  ```
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA...
  ...entire key content...
  -----END RSA PRIVATE KEY-----
  ```
- Click **Add secret**

### 2.3 Verify All Secrets

You should now have 5 secrets:
- ✅ DOCKERHUB_USERNAME
- ✅ DOCKERHUB_TOKEN
- ✅ EC2_HOST
- ✅ EC2_USER
- ✅ EC2_SSH_KEY

**Security Note:** Secrets are encrypted and never displayed after creation.

---

## Step 3: Understanding the Workflows

Your repository already has two GitHub Actions workflows:

### Workflow 1: Build and Push (`build-push.yml`)

**Location:** `.github/workflows/build-push.yml`

**Triggers:**
- Every push to `main` branch
- Manual trigger (workflow_dispatch)

**What it does:**
1. Checks out code
2. Sets up Docker Buildx
3. Logs into Docker Hub
4. Builds backend image (multi-stage)
5. Tags image with `latest` and `main-<commit-sha>`
6. Pushes to Docker Hub
7. Repeats for frontend image

**Result:** Pre-built images ready for EC2 to pull

### Workflow 2: Deploy to EC2 (`deploy-ec2.yml`)

**Location:** `.github/workflows/deploy-ec2.yml`

**Triggers:**
- After build-push workflow completes successfully
- Manual trigger (workflow_dispatch)

**What it does:**
1. SSH into your EC2 instance
2. Pulls latest code from GitHub
3. Pulls latest Docker images from Docker Hub
4. Restarts containers with new images
5. Waits for health checks
6. Verifies deployment
7. Cleans up old images

**Result:** Updated application running on EC2

---

## Step 4: Test the CI/CD Pipeline

### 4.1 Make a Small Change

Let's test with a small README change:

**On your Windows machine:**
```powershell
cd "c:\CLOUD\OneDrive - Hogarth Worldwide\Documents\Ostad\Batch-08\module-10\3-tier-app-docker-compose"

# Edit README.md or make a small change
echo "# CI/CD Test" >> test.txt

git add .
git commit -m "test: CI/CD pipeline test"
git push origin main
```

### 4.2 Watch GitHub Actions

1. Go to your GitHub repository
2. Click **Actions** tab
3. You'll see the workflow running:
   - **Build and Push Docker Images** (running)

4. Click on the workflow run to see details
5. Watch both jobs:
   - **build-backend** (3-5 minutes)
   - **build-frontend** (3-5 minutes)

**Success indicators:**
- ✅ Green checkmarks on all steps
- ✅ "All Docker images built and pushed successfully!" message

### 4.3 Verify Images on Docker Hub

1. Go to Docker Hub: `hub.docker.com`
2. Check your repositories:
   - `YOUR_USERNAME/bmi-backend` - should show `latest` tag
   - `YOUR_USERNAME/bmi-frontend` - should show `latest` tag

### 4.4 Manually Trigger Deployment

Since this is the first time, manually trigger deployment:

1. In GitHub → **Actions** tab
2. Click **Deploy to AWS EC2** workflow
3. Click **Run workflow** button
4. Keep default: `production`
5. Click **Run workflow**

**Watch deployment:**
- Takes 2-3 minutes
- SSH to EC2
- Pulls code and images
- Restarts containers
- Health checks

**Success indicators:**
- ✅ "Deployment completed successfully!"
- ✅ Application URL displayed

### 4.5 Verify on EC2

SSH to your EC2 and verify:

```bash
ssh -i "your-key.pem" ubuntu@YOUR_EC2_IP

cd ~/3-tier-docker-compose-ubuntu

# Check latest commit
git log -1

# Check containers are using new images
docker compose ps

# Check images from Docker Hub
docker images | grep bmi-

# Expected: YOUR_USERNAME/bmi-backend and bmi-frontend
```

### 4.6 Test Application

Access application in browser:
```
http://YOUR_EC2_IP
```

Should work exactly as before!

---

## Step 5: Full CI/CD Test (End-to-End)

Now let's make a real code change and watch full automation:

### 5.1 Make Code Change

Edit backend health endpoint to include more info:

**On Windows machine:**
Edit `backend/src/server.js`:

Find the health endpoint:
```javascript
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});
```

Change to:
```javascript
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.1.0',
    environment: process.env.NODE_ENV
  });
});
```

### 5.2 Commit and Push

```powershell
git add backend/src/server.js
git commit -m "feat: add version info to health endpoint"
git push origin main
```

### 5.3 Watch Entire Pipeline

**In GitHub Actions:**

1. **Build and Push** workflow starts automatically
   - Builds backend with your changes
   - Builds frontend (no changes, uses cache)
   - Pushes both to Docker Hub
   - ~5 minutes

2. **Deploy to EC2** workflow starts after build succeeds
   - Connects to EC2
   - Pulls new images
   - Rolling restart
   - Health checks
   - ~3 minutes

**Total time: ~8 minutes from push to deployed!**

### 5.4 Verify Changes Deployed

Test updated health endpoint:

```bash
curl http://YOUR_EC2_IP:3000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-14T12:34:56.789Z",
  "version": "1.1.0",
  "environment": "production"
}
```

✅ Your change is live!

---

## Step 6: Understanding Production Deployments

### Using docker-compose.prod.yml

Your repository includes `docker-compose.prod.yml` for production-specific settings:

**What it does:**
- Uses pre-built images from Docker Hub (no building on EC2)
- Sets resource limits (CPU, memory)
- Always restart policy
- Production logging settings

**To use manually on EC2:**
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Rolling Updates (Zero Downtime)

The workflow uses:
```bash
docker compose up -d --no-deps --build
```

This:
1. Pulls new images
2. Starts new containers
3. Waits for health checks ✅
4. Only then stops old containers
5. **Result:** No downtime!

---

## Step 7: Rollback Strategy

### If Deployment Fails

**Option 1: Rollback via Git**

```powershell
# On your machine
git log --oneline  # See commit history

# Revert to previous commit
git revert HEAD
git push origin main

# CI/CD automatically deploys previous version
```

**Option 2: Manual Rollback on EC2**

```bash
# SSH to EC2
ssh -i "key.pem" ubuntu@YOUR_EC2_IP
cd ~/3-tier-docker-compose-ubuntu

# Go back to previous commit
git log --oneline
git checkout <previous-commit-hash>

# Pull old images
docker compose pull

# Restart with old images
docker compose up -d
```

**Option 3: Tag-based Deployment**

Images are tagged with commit SHA. Use specific version:

```bash
# On EC2
DOCKERHUB_USERNAME=your_username docker compose pull
docker compose up -d
```

---

## Step 8: Monitoring CI/CD

### GitHub Actions Logs

View build/deploy details:
1. GitHub → Actions tab
2. Click workflow run
3. Click job (build-backend, build-frontend, deploy)
4. Expand steps to see output

**Useful for:**
- Debugging build failures
- Seeing deploy progress
- Checking error messages

### Slack/Email Notifications (Optional)

Add notifications to workflows:

Edit `.github/workflows/deploy-ec2.yml`, add at end:

```yaml
      - name: Notify Success
        if: success()
        run: |
          echo "✅ Deployment successful!"
          # Add Slack webhook or email notification here
```

### Deployment History

Track deployments:
- GitHub Actions → All workflow runs
- Each run shows: timestamp, commit, duration, status

---

## Common Workflows & Commands

### Trigger Manual Build

```bash
# Via GitHub UI:
Actions → Build and Push → Run workflow

# Via GitHub CLI:
gh workflow run build-push.yml
```

### Deploy Specific Branch

Edit `deploy-ec2.yml` to deploy from `develop` branch for staging.

### Build Without Deploy

Set deploy workflow to `workflow_dispatch` only (remove `workflow_run` trigger).

### Skip CI/CD

Add to commit message:
```bash
git commit -m "docs: update README [skip ci]"
```

---

## Troubleshooting

### Issue: Build fails with "permission denied"

**Cause:** Docker Hub credentials incorrect

**Solution:**
1. Verify DOCKERHUB_TOKEN is valid
2. Check token has Write permissions
3. Re-create token if expired

### Issue: Deploy fails with "SSH connection refused"

**Cause:** EC2_SSH_KEY or EC2_HOST incorrect

**Solution:**
```bash
# Test SSH key locally
ssh -i key.pem ubuntu@YOUR_EC2_IP

# Verify GitHub secrets match your actual credentials
```

### Issue: "Docker images not found on Docker Hub"

**Cause:** Build workflow didn't complete

**Solution:**
1. Check Actions tab for build errors
2. Ensure build completed successfully before deploying
3. Manually trigger build workflow

### Issue: Deployment succeeds but old code running

**Cause:** EC2 not pulling latest images

**Solution on EC2:**
```bash
# Force pull latest
docker compose pull

# Check image digest matches Docker Hub
docker images --digests | grep bmi-

# Restart
docker compose up -d --force-recreate
```

### Issue: Build takes too long (>15 minutes)

**Cause:** No cache, rebuilding everything

**Solution:**
- First build is slow (~10 min)
- Subsequent builds use cache (~3-5 min)
- Check Buildx cache in workflow

---

## Cost Optimization

### Free Tiers:

✅ **GitHub Actions:** 2,000 minutes/month (free)
✅ **Docker Hub:** Unlimited public repositories (free)
✅ **EC2:** Covered by your existing instance

### Reduce Build Time:

**Use Docker layer caching:**
- Already configured in workflows
- Reuses unchanged layers
- 50-70% faster builds

**Build only changed services:**
Edit workflow to detect changes:
```yaml
- name: Build backend
  if: contains(github.event.head_commit.modified, 'backend/')
```

---

## Best Practices

### 1. Branching Strategy

**Development workflow:**
```
feature-branch → PR → main → auto-deploy
```

**Before merging:**
- Code review
- Tests pass
- Preview deployment (optional)

### 2. Version Tagging

Tag releases:
```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Triggers specific image tag: `v1.0.0`

### 3. Environment Variables

Never hardcode secrets:
- Use GitHub Secrets
- Use EC2 `.env` file
- Rotate credentials regularly

### 4. Monitoring Deployments

After each deployment:
- Check Grafana dashboards
- Monitor error logs in Loki
- Verify health endpoints

### 5. Automated Testing (Future)

Add test step before deploy:
```yaml
- name: Run Tests
  run: |
    docker compose run backend npm test
```

---

## Advanced: Multi-Environment Setup

### Stage: Create Staging Environment

1. **Launch second EC2** for staging
2. **Add secrets:**
   - `EC2_HOST_STAGING`
   - `EC2_SSH_KEY_STAGING`
3. **Create workflow:** `deploy-staging.yml`
4. **Deploy to staging first**, then production

**Workflow:**
```
Push → Build → Deploy Staging → Test → Deploy Production
```

---

## Security Best Practices

### 1. Rotate Credentials Regularly

- Change Docker Hub token every 90 days
- Rotate EC2 SSH keys
- Update GitHub secrets when rotated

### 2. Use Least Privilege

- Docker Hub token: only necessary permissions
- EC2 IAM role: minimal required access
- GitHub: protect main branch (require PR)

### 3. Scan Images for Vulnerabilities

Add to workflow:
```yaml
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: your-image:latest
```

### 4. Audit Logs

Review regularly:
- GitHub Actions logs
- Docker Hub access logs
- EC2 CloudTrail logs

---

## Comparing: VM vs Docker Deployment

### Traditional VM Deployment:

```
Developer → Manual SSH → Manual commands
         → Install dependencies
         → Copy files
         → Restart services
         → Hope it works! 🤞

Time: 30-60 minutes
Consistency: Variable
Rollback: Manual, error-prone
```

### Docker CI/CD Deployment:

```
Developer → Git Push → Automated everything!

Time: 5-8 minutes
Consistency: Identical every time
Rollback: One command or one commit
Scale: Same process for 1 or 100 servers
```

### Benefits Realized:

| Metric | Before | After (Docker CI/CD) |
|--------|--------|---------------------|
| Deploy time | 30-60 min | 5-8 min |
| Manual steps | 20+ | 1 (git push) |
| Rollback time | 30+ min | 2 min |
| Error rate | High | Near zero |
| Team scaling | One person | Entire team |

---

## What You've Accomplished

🎉 **Phase 3 Complete!**

✅ **Docker Hub registry** - Pre-built images ready to deploy
✅ **GitHub Actions CI** - Automatic image builds on every push
✅ **GitHub Actions CD** - Automatic EC2 deployments
✅ **Zero-downtime deploys** - Rolling updates with health checks
✅ **Git-based rollback** - Revert commits to rollback
✅ **Full automation** - Push code → deployed in 8 minutes

---

## Final Architecture

```
┌────────────────────────────────────────────┐
│  Developer Workflow                        │
│                                            │
│  1. Write code locally                     │
│  2. git commit -m "new feature"            │
│  3. git push origin main                   │
│     ↓                                      │
│  4. ☕ Get coffee                          │
│     ↓                                      │
│  5. ✅ New feature live!                   │
└────────────────────────────────────────────┘

┌────────────────────────────────────────────┐
│  Automated Pipeline                        │
│                                            │
│  GitHub → Actions → Build → Docker Hub     │
│                       ↓                    │
│                    Deploy → EC2            │
│                       ↓                    │
│                  Health Check              │
│                       ↓                    │
│                    Success! ✅             │
└────────────────────────────────────────────┘
```

---

## Next Steps (Optional Enhancements)

### 1. Add Automated Tests
- Unit tests in workflow
- Integration tests before deploy
- E2E tests after deploy

### 2. Add Alerts
- Slack notifications on deploy
- Email on failure
- Discord/Teams webhooks

### 3. Blue-Green Deployments
- Run two environments
- Switch traffic after verification
- Instant rollback capability

### 4. Kubernetes Migration
- Docker Compose to Kubernetes
- Auto-scaling
- Multi-region deployment

### 5. Infrastructure as Code
- Terraform for EC2 provisioning
- Version-controlled infrastructure
- Consistent dev/staging/prod

---

## Quick Reference

### Manual Deploy (for testing):
```bash
# On EC2
cd ~/3-tier-docker-compose-ubuntu
git pull origin main
docker compose pull
docker compose up -d
```

### Trigger CI/CD:
```bash
# On your machine
git add .
git commit -m "your message"
git push origin main
# Wait 8 minutes, changes are live!
```

### Rollback:
```bash
git revert HEAD
git push origin main
# CI/CD deploys previous version
```

### Check Status:
- GitHub Actions: View build/deploy progress
- Docker Hub: Verify latest images
- EC2: `docker compose ps`
- App: `curl http://YOUR_IP:3000/health`

---

## Support & Resources

**GitHub Actions Docs:** [docs.github.com/actions](https://docs.github.com/en/actions)
**Docker Hub:** [hub.docker.com](https://hub.docker.com)
**Workflow Examples:** [github.com/actions/starter-workflows](https://github.com/actions/starter-workflows)

---

## Congratulations! 🎉

You've built a **complete production-grade** deployment pipeline:

✅ Dockerized three-tier application
✅ Full observability (Prometheus, Grafana, Loki)
✅ Automated CI/CD with GitHub Actions
✅ Zero-downtime deployments
✅ Industry-standard DevOps practices

**You're now ready for production! 🚀**
