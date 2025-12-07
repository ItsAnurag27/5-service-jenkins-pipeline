# 🐳 Docker Hub Push Guide

## Step 1: Create Docker Hub Account

1. Go to https://hub.docker.com/
2. Click **Sign Up**
3. Fill in your details and create account
4. Verify your email
5. Go to **Account Settings → Security → Access Tokens**
6. Click **New Access Token**
7. Name it: `jenkins-token`
8. Copy the token (you'll need this)

---

## Step 2: Set Docker Hub Credentials in Jenkins

### Option A: Via Jenkins UI (Recommended)

1. Go to **Jenkins Dashboard**
2. Click **Manage Jenkins → Manage Credentials**
3. Click **System → Global credentials → Add Credentials**

#### For Docker Hub:

**Credential Type:** Username with password

```
Username:   your-docker-hub-username
Password:   (your access token or password)
ID:         docker-hub-creds ⭐
Description: Docker Hub Credentials
```

Click **Create**

#### For EC2 SSH Key:

**Credential Type:** SSH Username with private key

```
Username:        ec2-user
Private Key:     (paste .pem file content)
ID:              jenkins-key ⭐
Description:     EC2 SSH Key
```

Click **Create**

#### For EC2 IP:

**Credential Type:** Secret text

```
Secret:      your-ec2-public-ip (e.g., 54.123.45.67)
ID:          ec2-ip ⭐
Description: EC2 Public IP Address
```

Click **Create**

---

## Step 3: Configure Docker Locally (Manual Testing)

Before pushing via Jenkins, test locally:

```bash
# Login to Docker Hub
docker login
# Enter username and password/token

# Build images
docker-compose build

# Tag images
docker tag service-pipeline_nginx:latest your-docker-username/service-pipeline:nginx-latest
docker tag service-pipeline_httpd:latest your-docker-username/service-pipeline:httpd-latest
docker tag service-pipeline_caddy:latest your-docker-username/service-pipeline:caddy-latest
docker tag service-pipeline_traefik:latest your-docker-username/service-pipeline:traefik-latest
docker tag service-pipeline_app:latest your-docker-username/service-pipeline:app-latest

# Push to Docker Hub
docker push your-docker-username/service-pipeline:nginx-latest
docker push your-docker-username/service-pipeline:httpd-latest
docker push your-docker-username/service-pipeline:caddy-latest
docker push your-docker-username/service-pipeline:traefik-latest
docker push your-docker-username/service-pipeline:app-latest

# Logout
docker logout
```

---

## Step 4: Update .env File

Edit `.env` in your repository:

```env
# Docker Hub Configuration
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-access-token
DOCKER_REPO=${DOCKER_USERNAME}/service-pipeline
```

⚠️ **Never commit .env to GitHub!** It's in `.gitignore`

---

## Step 5: How Jenkins Pipeline Builds & Pushes

### Stage: Build Images

```bash
docker-compose build
```

This runs all Dockerfiles:
- `services/nginx/Dockerfile` → builds nginx service
- `services/httpd/Dockerfile` → builds httpd service
- `services/caddy/Dockerfile` → builds caddy service
- `services/traefik/Dockerfile` → builds traefik service
- `services/app/Dockerfile` → builds app service

**Creates images:**
- `your-docker-username/service-pipeline:nginx`
- `your-docker-username/service-pipeline:httpd`
- `your-docker-username/service-pipeline:caddy`
- `your-docker-username/service-pipeline:traefik`
- `your-docker-username/service-pipeline:app`

### Stage: Tag Images

```bash
docker tag service-pipeline_nginx service-pipeline:nginx-1
docker tag service-pipeline_nginx service-pipeline:nginx-latest
# ... repeats for all services
```

**Creates tags:**
- `nginx-1`, `nginx-latest`
- `httpd-1`, `httpd-latest`
- `caddy-1`, `caddy-latest`
- `traefik-1`, `traefik-latest`
- `app-1`, `app-latest`

### Stage: Push to Docker Hub

```bash
# Login
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

# Push all images with all tags (20 images total)
docker push service-pipeline:nginx-1
docker push service-pipeline:nginx-latest
docker push service-pipeline:httpd-1
docker push service-pipeline:httpd-latest
# ... and so on

# Logout
docker logout
```

---

## Step 6: Create Jenkins Pipeline Job

1. Go to **Jenkins Dashboard**
2. Click **New Item**
3. Enter name: `service-pipeline-deploy`
4. Select **Pipeline**
5. Click **OK**

### Configuration:

**General:**
- Check: "GitHub project"
- Project URL: `https://github.com/ItsAnurag27/5-service-jenkins-pipeline`

**Build Triggers:**
- Check: "GitHub hook trigger for GITScm polling"

**Pipeline:**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
  - Repository URL: `https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git`
  - Branch: `*/master`
  - Script Path: `Jenkinsfile`

Click **Save**

---

## Step 7: Run Your First Build

1. Click **Build Now**
2. Watch the console output:

```
📥 Checking out code from GitHub...
🔍 Verifying environment...
🔨 Building Docker images...
   Building service-pipeline_nginx
   Building service-pipeline_httpd
   Building service-pipeline_caddy
   Building service-pipeline_traefik
   Building service-pipeline_app

🏷️  Tagging images...
   Created 10 tags (5 services × 2 tags each)

📤 Pushing images to Docker Hub...
   Pushing nginx:1, nginx:latest
   Pushing httpd:1, httpd:latest
   Pushing caddy:1, caddy:latest
   Pushing traefik:1, traefik:latest
   Pushing app:1, app:latest

🚀 Deploying to EC2...
   SCP: docker-compose.yml → EC2
   SSH: docker-compose pull → EC2
   SSH: docker-compose up -d → EC2

✅ Verifying deployment...
   Testing endpoints...
   http://localhost:9080 → 200 ✓
   http://localhost:9081 → 200 ✓
   http://localhost:9082 → 200 ✓
   http://localhost:3000 → 200 ✓
   http://localhost:9088 → 200 ✓

🧹 Cleaning up...
   Removed old images

========================================
✅ DEPLOYMENT SUCCESSFUL
========================================
```

---

## Verify Images on Docker Hub

1. Go to https://hub.docker.com
2. Login with your credentials
3. Search for `your-docker-username/service-pipeline`
4. You should see all 5 services with tags:
   - `nginx-1`, `nginx-latest`
   - `httpd-1`, `httpd-latest`
   - `caddy-1`, `caddy-latest`
   - `traefik-1`, `traefik-latest`
   - `app-1`, `app-latest`

---

## 🔄 How to Re-Deploy

After making changes to code:

```bash
# Commit and push to GitHub
git add .
git commit -m "Update service configurations"
git push origin master
```

Then either:

**Option 1: Manual Build**
- Go to Jenkins → Click **Build Now**

**Option 2: Auto-Build (GitHub Webhook)**
- Push automatically triggers Jenkins build
- Build pushes to Docker Hub
- Docker Hub pulls on EC2
- Services updated automatically

---

## 📊 Build Number & Versioning

Each Jenkins build gets a number:

| Build # | Nginx Tag | Build Status |
|---------|-----------|--------------|
| 1 | `nginx-1` | ✅ Passed |
| 2 | `nginx-2` | ✅ Passed |
| 3 | `nginx-3` | ✅ Passed |

Latest tag always points to newest build:
- `nginx-latest` → `nginx-3`

Rollback to previous build:
```bash
docker pull your-docker-username/service-pipeline:nginx-2
docker-compose pull
docker-compose up -d
```

---

## 🛠️ Troubleshooting

### Build fails at "Build Images"?

**Problem:** Dockerfile syntax error
**Solution:** 
```bash
docker build -f services/nginx/Dockerfile -t test .
```

### Images not pushed to Docker Hub?

**Problem:** Wrong credentials
**Solution:**
```bash
docker login -u your-username -p your-password
# Verify login succeeded
docker push your-username/service-pipeline:test
```

### EC2 not pulling latest images?

**Problem:** Pull might be using old image from cache
**Solution:**
```bash
docker pull --no-cache your-username/service-pipeline:nginx-latest
```

### Port conflicts on local machine?

**Problem:** Port already in use
**Solution:** Update docker-compose.yml
```yaml
ports:
  - "8080:80"  # Changed from 9080
```

---

## 📚 Quick Reference

```bash
# Local build & test
docker-compose build
docker-compose up -d
curl http://localhost:9080

# Push manually
docker login
docker tag service-pipeline_nginx your-user/service-pipeline:nginx-latest
docker push your-user/service-pipeline:nginx-latest

# On EC2
docker pull your-user/service-pipeline:nginx-latest
docker-compose down
docker-compose up -d
```

---

## ✨ What You've Accomplished

✅ Created 5 Docker services with custom Dockerfiles
✅ Built images locally with docker-compose
✅ Tagged images with build numbers and latest
✅ Pushed to Docker Hub registry
✅ Configured Jenkins pipeline for CI/CD
✅ Automated deployment to EC2
✅ Setup Docker Hub credentials in Jenkins

**Next Steps:**
1. Create Docker Hub account & token
2. Add 3 credentials to Jenkins
3. Create pipeline job
4. Push to GitHub
5. Click "Build Now" in Jenkins
6. Watch your services deploy! 🚀
