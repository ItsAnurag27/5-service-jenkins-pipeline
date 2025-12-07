# 📋 Jenkins Pipeline Creation - Complete Step-by-Step Guide

## 🎯 Overview

Your Jenkins pipeline automates:
1. Code checkout from GitHub
2. Docker image building
3. Image tagging and pushing to Docker Hub
4. Deployment to AWS EC2
5. Service verification
6. Cleanup and reporting

---

## ⏳ Prerequisites (Before Creating Pipeline)

✅ Jenkins server running (http://jenkins-url:8080)
✅ GitHub account with repository created
✅ Docker Hub account created
✅ AWS EC2 instance running
✅ 3 credentials created in Jenkins (see below)

---

## 🔐 Step 1: Create 3 Jenkins Credentials

### 1.1 Navigate to Credentials Page

```
Jenkins Dashboard 
  → Manage Jenkins 
    → Manage Credentials 
      → System 
        → Global credentials (unrestricted)
```

### 1.2 Create Credential #1: Docker Hub

Click **"Add Credentials"** button

| Field | Value |
|-------|-------|
| **Kind** | Username with password |
| **Username** | your-docker-hub-username |
| **Password** | your-docker-hub-password |
| **ID** | `docker-hub-creds` ⭐ (MUST match Jenkinsfile) |
| **Description** | Docker Hub Login Credentials |

**Click "Create"**

### 1.3 Create Credential #2: EC2 SSH Key

Click **"Add Credentials"** button again

| Field | Value |
|-------|-------|
| **Kind** | SSH Username with private key |
| **Username** | `ec2-user` |
| **Private Key** | (Paste content of your .pem file) |
| **Passphrase** | (Leave empty if no passphrase) |
| **ID** | `ec2-ssh-key` ⭐ (MUST match Jenkinsfile) |
| **Description** | EC2 Instance SSH Key |

**Click "Create"**

### 1.4 Create Credential #3: EC2 IP Address

Click **"Add Credentials"** button again

| Field | Value |
|-------|-------|
| **Kind** | Secret text |
| **Secret** | `54.123.45.67` (Your EC2 public IP) |
| **ID** | `ec2-ip` ⭐ (MUST match Jenkinsfile) |
| **Description** | EC2 Public IP Address |

**Click "Create"**

### ✅ Credentials Checklist

After creation, you should see:

```
✓ docker-hub-creds (Username with password)
✓ ec2-ssh-key (SSH Username with private key)
✓ ec2-ip (Secret text)
```

---

## 🏗️ Step 2: Create Pipeline Job

### 2.1 Create New Job

Click **"New Item"** on Jenkins Dashboard

### 2.2 Configure Job

```
Item name: service-pipeline-deploy
Type: Pipeline
```

Click **"OK"**

### 2.3 Configure General Settings

Under **"General"** section:

```
☑ Check: Build Discarder
  ├─ Strategy: Log Rotation
  ├─ Days to keep builds: -1
  ├─ Max # of builds: 10
  └─ Artifact days/builds: -1

☑ Check: Timeout
  ├─ Abort if stuck: ✓
  ├─ Strategy: Absolute
  └─ Timeout: 60 minutes

☑ Check: Timestamps in console
```

### 2.4 Configure Build Triggers

Under **"Build Triggers"** section:

```
☑ GitHub hook trigger for GITScm polling
   (Enables auto-build on GitHub push)
```

### 2.5 Configure Pipeline

Under **"Pipeline"** section:

```
Definition: Pipeline script from SCM

SCM: Git
├─ Repository URL: https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git
├─ Credentials: (Leave as is for public repo)
├─ Branch Specifier: */main
├─ Repository browser: (GitHub)
├─ Project URL: https://github.com/ItsAnurag27/5-service-jenkins-pipeline
└─ Script Path: Jenkinsfile
```

### 2.6 Save Job

Click **"Save"** button at bottom

---

## 🔧 Step 3: Understand Jenkinsfile Structure

### 3.1 Jenkinsfile Overview

Your `Jenkinsfile` has this structure:

```groovy
pipeline {
    agent any                           // Run on any available agent
    
    options { ... }                     // Global pipeline options
    
    environment {                       // Environment variables
        DOCKER_HUB_CREDS = credentials('docker-hub-creds')
        DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        ...
    }
    
    stages {                            // 8 stages
        stage('Checkout') { ... }
        stage('Verify') { ... }
        stage('Build Images') { ... }
        stage('Tag Images') { ... }
        stage('Push to Docker Hub') { ... }
        stage('Deploy to EC2') { ... }
        stage('Verify Deployment') { ... }
        stage('Cleanup') { ... }
    }
    
    post {                              // After all stages
        success { ... }
        failure { ... }
    }
}
```

### 3.2 Pipeline Variables

Credentials are automatically injected:

```groovy
environment {
    // From 'docker-hub-creds' credential
    DOCKER_HUB_CREDS = credentials('docker-hub-creds')
    DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"     // Username
    DOCKER_PASSWORD = "${DOCKER_HUB_CREDS_PSW}"     // Password
    
    // From 'ec2-ip' credential
    EC2_IP = credentials('ec2-ip')                   // IP Address
    
    // From 'ec2-ssh-key' credential
    EC2_KEY = credentials('ec2-ssh-key')             // Private key
    
    // From Jenkins
    IMAGE_TAG = "${BUILD_NUMBER}"                    // Build #1, #2, etc.
    
    // Computed
    DOCKER_REPO = "${DOCKER_USERNAME}/service-pipeline"
}
```

---

## 🚀 Stage Explanation

### 🔄 Stage 1: Checkout

**Purpose:** Get code from GitHub

```groovy
stage('Checkout') {
    steps {
        checkout scm
    }
}
```

**What happens:**
- Git clones your repository
- Checks out the `Jenkinsfile`
- Downloads `docker-compose.yml`, `.env`, `html/`, `app/`

**Output:** Files available in Jenkins workspace

---

### ✅ Stage 2: Verify

**Purpose:** Ensure Docker tools are installed

```groovy
stage('Verify') {
    steps {
        sh 'docker --version'
        sh 'docker-compose --version'
    }
}
```

**What happens:**
- Checks if Docker is installed
- Checks if Docker Compose is installed
- Fails if either is missing

**Output:** Docker version numbers in console

---

### 🔨 Stage 3: Build Images

**Purpose:** Build Docker images for all 5 services

```groovy
stage('Build Images') {
    steps {
        sh 'docker-compose build'
    }
}
```

**What happens:**
- Reads `docker-compose.yml`
- Builds all 5 services:
  - nginx:alpine
  - httpd:2.4-alpine
  - caddy:2-alpine
  - traefik:latest
  - python:3.11-alpine

**Output:** Images stored locally on Jenkins server

---

### 🏷️ Stage 4: Tag Images

**Purpose:** Add meaningful tags with build number

```groovy
stage('Tag Images') {
    steps {
        sh '''
            docker tag nginx:alpine ${DOCKER_REPO}:nginx-${IMAGE_TAG}
            docker tag nginx:alpine ${DOCKER_REPO}:nginx-latest
            docker tag httpd:2.4-alpine ${DOCKER_REPO}:httpd-${IMAGE_TAG}
            docker tag httpd:2.4-alpine ${DOCKER_REPO}:httpd-latest
            ...
        '''
    }
}
```

**What happens:**
- Tags each image with build number (e.g., `user/service-pipeline:nginx-5`)
- Also tags with `latest` for quick reference
- 10 images created (5 services × 2 tags)

**Example tags:**
```
your-username/service-pipeline:nginx-5
your-username/service-pipeline:nginx-latest
your-username/service-pipeline:httpd-5
your-username/service-pipeline:httpd-latest
...
```

---

### 📤 Stage 5: Push to Docker Hub

**Purpose:** Upload images to Docker Hub registry

```groovy
stage('Push to Docker Hub') {
    steps {
        sh '''
            echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
            docker push ${DOCKER_REPO}:nginx-${IMAGE_TAG}
            docker push ${DOCKER_REPO}:nginx-latest
            ...
            docker logout
        '''
    }
}
```

**What happens:**
1. Logs into Docker Hub using credentials
2. Pushes all 10 tagged images
3. Logs out for security
4. Images now available at: `docker pull your-username/service-pipeline:nginx-5`

**Output:** Upload progress for each image

---

### 🚀 Stage 6: Deploy to EC2

**Purpose:** SSH to EC2 and run services

```groovy
stage('Deploy to EC2') {
    steps {
        sh '''
            scp -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                docker-compose.yml ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
            scp -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                .env ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
            scp -i ${EC2_KEY} -o StrictHostKeyChecking=no -r \
                html/ ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
            
            ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                ${EC2_USER}@${EC2_IP} \
                "cd /home/ec2-user/app && docker-compose pull && docker-compose up -d"
        '''
    }
}
```

**What happens:**
1. **SCP** (Secure Copy) transfers files to EC2:
   - `docker-compose.yml`
   - `.env`
   - `html/` directory
   - `app/` directory

2. **SSH** connects to EC2 and executes:
   - `docker-compose pull` - Download images from Docker Hub
   - `docker-compose down` - Stop old services
   - `docker-compose up -d` - Start all 5 services in background

**Result:** All services running on EC2

---

### ✅ Stage 7: Verify Deployment

**Purpose:** Test that all services are accessible

```groovy
stage('Verify Deployment') {
    steps {
        sh '''
            ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                ${EC2_USER}@${EC2_IP} "docker-compose ps"
            
            echo "Testing service endpoints..."
            ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no \
                ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:9080"
            ...
        '''
    }
}
```

**What happens:**
1. Shows all running containers
2. Tests HTTP endpoints:
   - `http://EC2_IP:9080` (Nginx) - expects 200
   - `http://EC2_IP:9081` (Apache) - expects 200
   - `http://EC2_IP:9082` (Caddy) - expects 200
   - `http://EC2_IP:3000` (App) - expects 200
   - `http://EC2_IP:9088` (Traefik) - expects 200

**Output:** HTTP status codes (200 = success)

---

### 🧹 Stage 8: Cleanup

**Purpose:** Remove old Docker images to save space

```groovy
stage('Cleanup') {
    steps {
        sh '''
            docker image prune -f --filter "until=24h"
        '''
    }
}
```

**What happens:**
- Removes Docker images older than 24 hours
- Keeps recent builds for rollback capability
- Frees up disk space on Jenkins server

---

## 📊 Full Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    BUILD TRIGGER                             │
│  You click "Build Now" or GitHub push webhook triggers       │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 1: CHECKOUT                                            │
│ • Clone from GitHub                                          │
│ • Get Jenkinsfile, docker-compose.yml, code                │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 2: VERIFY                                              │
│ • Check docker --version                                     │
│ • Check docker-compose --version                             │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 3: BUILD IMAGES                                        │
│ • docker-compose build                                       │
│ • Creates: nginx, httpd, caddy, traefik, app               │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 4: TAG IMAGES                                          │
│ • Tag with: service-build#5 and service-latest              │
│ • Example: your-user/service:nginx-5, nginx-latest          │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 5: PUSH TO DOCKER HUB                                 │
│ • docker login                                               │
│ • Push all 10 images to registry                            │
│ • docker logout                                              │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 6: DEPLOY TO EC2                                       │
│ • SCP files: docker-compose.yml, .env, html/, app/         │
│ • SSH: docker-compose pull                                   │
│ • SSH: docker-compose up -d                                  │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 7: VERIFY DEPLOYMENT                                  │
│ • SSH: docker-compose ps                                     │
│ • Test all service URLs (9080, 9081, 9082, 3000, 9088)      │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ Stage 8: CLEANUP                                             │
│ • Remove images > 24 hours old                              │
│ • Free up disk space                                         │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│                    POST ACTIONS                              │
│  Success: Display service URLs                              │
│  Failure: Send error notification                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎬 Step 4: Run Your First Build

### 4.1 Trigger Build

**Option A: Manual Trigger**
```
Jenkins Dashboard 
  → service-pipeline-deploy 
    → Build Now
```

**Option B: GitHub Webhook (Auto-trigger)**
```
Just push to GitHub:
git push origin master

// Pipeline auto-triggers!
```

### 4.2 Monitor Build

Click **"Build #1"** → **"Console Output"**

You'll see real-time logs:

```
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /var/jenkins_home/workspace/service-pipeline-deploy
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] checkout
...
```

### 4.3 Build Status

Build will show as:
- 🔵 **Blue ball** = Success ✅
- ❌ **Red ball** = Failed
- 🟡 **Yellow ball** = Building/In Progress

---

## 🧪 After Successful Build

### You Can Access All Services:

```
Nginx:   http://YOUR_EC2_IP:9080
Apache:  http://YOUR_EC2_IP:9081
Caddy:   http://YOUR_EC2_IP:9082
App:     http://YOUR_EC2_IP:3000
Traefik: http://YOUR_EC2_IP:9088
```

### Check EC2 Services:

```bash
# SSH to EC2
ssh -i your-key.pem ec2-user@YOUR_EC2_IP

# View running services
docker-compose ps

# View logs
docker-compose logs -f nginx
```

---

## 🐛 Troubleshooting

### Problem: Build Fails at "Checkout"

**Cause:** GitHub repository not found

**Fix:**
```
• Verify repository URL in Jenkins job
• Check if repository is public
• Or use SSH URL instead of HTTPS
```

### Problem: Build Fails at "Verify"

**Cause:** Docker not installed on Jenkins

**Fix:**
```
• SSH to Jenkins server
• Install Docker: sudo apt-get install docker.io
• Add jenkins user to docker group: sudo usermod -aG docker jenkins
• Restart Jenkins
```

### Problem: Build Fails at "Push to Docker Hub"

**Cause:** Wrong Docker Hub credentials

**Fix:**
```
• Go to Jenkins → Manage Credentials
• Edit 'docker-hub-creds'
• Re-enter correct username/password
• Resave
```

### Problem: Build Fails at "Deploy to EC2"

**Cause:** SSH key or EC2 IP wrong

**Fix:**
```
• Verify EC2 IP in Jenkins credentials
• Check .pem file is correct
• Ensure EC2 security group allows port 22
• Test SSH manually: ssh -i key.pem ec2-user@IP
```

### Problem: Services Not Accessible After Deploy

**Cause:** Security group rules missing

**Fix:**
```
EC2 Security Group must allow:
• Port 9080 (Nginx)
• Port 9081 (Apache)
• Port 9082 (Caddy)
• Port 3000 (App)
• Port 9088 (Traefik)
```

---

## ✨ Advanced Features

### 1. Build Parameters

Add build parameters for customization:

```
Jenkins Job → Configure 
  → Build Triggers 
    → Add Parameter
```

```
String parameter: EC2_IP_OVERRIDE
String parameter: BUILD_TAG
```

### 2. Email Notifications

Configure Jenkins to email on build success/failure:

```
Jenkins Configure System 
  → E-mail Notification
    → Add SMTP server
```

### 3. GitHub Status Updates

Show build status on GitHub:

```
Install: GitHub plugin
Jenkins: Add GitHub token
Result: Green ✓ or Red ✗ on commit
```

### 4. Slack Notifications

Post build results to Slack:

```
Install: Slack plugin
Configure: Slack workspace token
Result: Notifications in Slack channel
```

---

## 📝 Quick Reference

| Component | Value |
|-----------|-------|
| **Job Name** | service-pipeline-deploy |
| **Type** | Pipeline |
| **Jenkinsfile** | Script from SCM |
| **Repository** | GitHub (your repo) |
| **Branch** | */main |
| **Credentials** | 3 required |
| **Stages** | 8 |
| **Estimated Time** | 5-10 minutes per build |

---

## ✅ Setup Checklist

- [ ] 3 Jenkins credentials created
- [ ] Pipeline job "service-pipeline-deploy" created
- [ ] Job configured to pull from GitHub
- [ ] Jenkinsfile selected as script path
- [ ] Build trigger configured
- [ ] First manual build run successfully
- [ ] All services accessible from EC2
- [ ] GitHub webhook configured (optional)

---

Done! Your Jenkins pipeline is ready to deploy! 🚀
