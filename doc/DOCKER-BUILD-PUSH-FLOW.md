# 📊 Docker Build & Push Process - Complete Flow

## 🎯 Overview

Your pipeline now:
1. ✅ **Builds** custom Docker images from Dockerfiles
2. ✅ **Tags** images with build numbers
3. ✅ **Pushes** to Docker Hub registry
4. ✅ **Deploys** to EC2 automatically

---

## 📁 Project Structure (Updated)

```
project-root/
├── services/                          ← NEW: Custom Dockerfiles
│   ├── nginx/
│   │   └── Dockerfile                (builds from nginx:alpine + custom HTML)
│   ├── httpd/
│   │   └── Dockerfile                (builds from httpd:2.4-alpine + custom HTML)
│   ├── caddy/
│   │   └── Dockerfile                (builds from caddy:2-alpine + Caddyfile)
│   ├── traefik/
│   │   └── Dockerfile                (builds from traefik:latest)
│   └── app/
│       └── Dockerfile                (builds from python:3.11-alpine)
│
├── html/                              ← Static content
│   ├── nginx/index.html
│   ├── httpd/index.html
│   └── caddy/index.html
│
├── app/
│   └── index.html
│
├── docker-compose.yml                 ← UPDATED: uses build context
├── Jenkinsfile                        ← UPDATED: push logic
├── .env                              ← UPDATED: DOCKER_REPO variable
├── .gitignore
├── README.md
├── DOCKER-PUSH-GUIDE.md              ← NEW: Complete guide
└── 📚 Other docs
```

---

## 🐳 Dockerfile Structure

### nginx/Dockerfile
```dockerfile
FROM nginx:alpine
COPY html/nginx /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK ...
CMD ["nginx", "-g", "daemon off;"]
```

**Result:** Custom Nginx image with your HTML

### httpd/Dockerfile
```dockerfile
FROM httpd:2.4-alpine
COPY html/httpd /usr/local/apache2/htdocs
EXPOSE 80
HEALTHCHECK ...
CMD ["httpd-foreground"]
```

**Result:** Custom Apache image with your HTML

### app/Dockerfile
```dockerfile
FROM python:3.11-alpine
COPY app /app
WORKDIR /app
EXPOSE 3000
HEALTHCHECK ...
CMD ["python", "-m", "http.server", "3000"]
```

**Result:** Custom Python app image

---

## 🔄 Build & Push Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CHECKOUT                                                 │
│    git clone your-repo from GitHub                          │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. VERIFY                                                   │
│    docker --version                                         │
│    docker-compose --version                                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. BUILD IMAGES (Using Dockerfiles)                        │
│    docker-compose build                                    │
│                                                             │
│    Builds:                                                  │
│    • service-pipeline_nginx ← services/nginx/Dockerfile    │
│    • service-pipeline_httpd ← services/httpd/Dockerfile    │
│    • service-pipeline_caddy ← services/caddy/Dockerfile    │
│    • service-pipeline_traefik ← services/traefik/Dockerfile│
│    • service-pipeline_app ← services/app/Dockerfile        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. TAG IMAGES (Build #)                                     │
│    docker tag nginx your-user/service-pipeline:nginx-1     │
│    docker tag nginx your-user/service-pipeline:nginx-latest│
│    ... (repeats for all 5 services)                        │
│                                                             │
│    Creates: 10 tags (5 services × 2 tags each)            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. DOCKER LOGIN (to Docker Hub)                             │
│    docker login -u your-username --password-stdin          │
│    Using: DOCKER_HUB_CREDS (from Jenkins credentials)     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. PUSH TO DOCKER HUB                                       │
│    docker push your-user/service-pipeline:nginx-1          │
│    docker push your-user/service-pipeline:nginx-latest     │
│    ... (repeats for all 5 services × 2 tags)              │
│                                                             │
│    Pushes: 10 images to Docker Hub registry                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 7. DOCKER LOGOUT                                            │
│    docker logout                                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 8. DEPLOY TO EC2                                            │
│    ssh → Copy docker-compose.yml                           │
│    ssh → Copy .env                                          │
│    ssh → docker-compose pull (pulls from Docker Hub)       │
│    ssh → docker-compose down (stop old containers)         │
│    ssh → docker-compose up -d (start new containers)       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 9. VERIFY DEPLOYMENT                                        │
│    curl http://EC2:9080 → Nginx                           │
│    curl http://EC2:9081 → Apache                          │
│    curl http://EC2:9082 → Caddy                           │
│    curl http://EC2:3000 → App                             │
│    curl http://EC2:9088 → Traefik                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 10. CLEANUP (Local Images)                                  │
│     docker image prune -f --filter "until=24h"             │
└─────────────────────────────────────────────────────────────┘
                          ↓
                    ✅ SUCCESS ✅
```

---

## 📊 Image Versioning Example

### Build #1:
```
your-user/service-pipeline:nginx-1
your-user/service-pipeline:nginx-latest ← points to 1
```

### Build #2:
```
your-user/service-pipeline:nginx-1
your-user/service-pipeline:nginx-2
your-user/service-pipeline:nginx-latest ← points to 2
```

### Build #3:
```
your-user/service-pipeline:nginx-1
your-user/service-pipeline:nginx-2
your-user/service-pipeline:nginx-3
your-user/service-pipeline:nginx-latest ← points to 3
```

**Benefit:** Always deploy latest while keeping history of builds

---

## 🔐 Credentials Required

| Credential | Type | Jenkins ID | Content |
|-----------|------|-----------|---------|
| Docker Hub | Username + Password | `docker-hub-creds` | Username & Access Token |
| EC2 SSH | SSH Username + Key | `jenkins-key` | ec2-user & .pem content |
| EC2 IP | Secret Text | `ec2-ip` | Public IP address |

---

## 📝 Environment Variables Used

```groovy
DOCKER_USERNAME      // from docker-hub-creds
DOCKER_PASSWORD      // from docker-hub-creds
DOCKER_REPO          // your-user/service-pipeline
IMAGE_TAG            // ${BUILD_NUMBER} (1, 2, 3...)
EC2_IP               // from ec2-ip credential
EC2_USER             // ec2-user
EC2_KEY              // from jenkins-key credential
```

---

## 🚀 Complete Setup Checklist

### Before Jenkins Build:

- [ ] Docker Hub account created
- [ ] Access token generated
- [ ] 3 Jenkins credentials configured
- [ ] Pipeline job created in Jenkins
- [ ] GitHub repository contains:
  - [ ] Jenkinsfile
  - [ ] docker-compose.yml
  - [ ] services/*/Dockerfile (5 Dockerfiles)
  - [ ] html/*/index.html (3 HTML files)
  - [ ] app/index.html
- [ ] EC2 instance running
- [ ] Docker & Docker Compose installed on EC2
- [ ] SSH key accessible from Jenkins

### Jenkins Build Steps:

1. Click **Build Now**
2. Watch console output
3. All stages should show ✓ (Green)
4. After ~5-10 minutes, build completes
5. Services deployed to EC2

---

## 🧪 Manual Test Sequence

### On Your Local Machine:

```bash
# 1. Build locally
docker-compose build

# 2. Verify images created
docker images | grep service-pipeline

# 3. Run locally
docker-compose up -d

# 4. Test endpoints
curl http://localhost:9080   # Should show Nginx page
curl http://localhost:9081   # Should show Apache page
curl http://localhost:9082   # Should show Caddy page
curl http://localhost:3000   # Should show App page
curl http://localhost:9088   # Should show Traefik dashboard

# 5. View logs
docker-compose logs -f nginx
docker-compose logs -f app

# 6. Stop
docker-compose down
```

### Via Jenkins:

1. Click **Build Now**
2. Jenkins does all above automatically
3. Plus: Pushes to Docker Hub
4. Plus: Deploys to EC2

---

## 📈 What Happens in Jenkins

| Stage | Command | Output |
|-------|---------|--------|
| Checkout | `git clone` | Code downloaded |
| Verify | `docker --version` | Docker 20.10.x |
| Build | `docker-compose build` | 5 images built |
| Tag | `docker tag ...` | 10 tags created |
| Push | `docker push ...` | 10 images → Docker Hub |
| Deploy | `ssh ... docker-compose` | Services on EC2 |
| Verify | `curl http://...` | HTTP 200 ✓ |
| Cleanup | `docker prune` | Old images removed |

---

## 🎁 What You Get

✅ **Automated CI/CD Pipeline**
- Code push → Automatic build
- Custom Docker images built from Dockerfiles
- Images pushed to Docker Hub registry
- Automatically deployed to EC2

✅ **Version Control**
- Each build numbered (1, 2, 3...)
- Latest tag always points to newest build
- Easy rollback to previous versions

✅ **Scalability**
- Add more services by adding Dockerfiles
- Pipeline automatically handles them
- All services pushed and deployed together

✅ **Production Ready**
- Health checks on all services
- Automatic restart on failure
- Centralized logging
- Load balancing via Traefik

---

## 🔗 Next Steps

1. **Read:** DOCKER-PUSH-GUIDE.md
2. **Create:** Docker Hub account + token
3. **Setup:** 3 Jenkins credentials
4. **Create:** Pipeline job in Jenkins
5. **Test:** Local build with `docker-compose build`
6. **Deploy:** Click "Build Now" in Jenkins
7. **Verify:** Check Docker Hub registry
8. **Monitor:** Check EC2 services running

---

## 📞 Troubleshooting Reference

| Issue | Likely Cause | Fix |
|-------|------------|-----|
| Build fails: "No such file or directory" | Dockerfile path wrong | Check services/*/Dockerfile exists |
| Push fails: "401 Unauthorized" | Wrong credentials | Verify docker-hub-creds in Jenkins |
| EC2 deploy fails: "Permission denied" | Wrong SSH key | Check ec2-ssh-key credential |
| Images not pulling on EC2 | Network issue | SSH to EC2, try `docker pull` manually |
| Port conflict | Service already running | Stop existing containers |

---

## 📚 Documentation Files

- **README.md** - Project overview
- **DOCKER-PUSH-GUIDE.md** - Complete Docker Hub push guide
- **Jenkinsfile** - Pipeline definition
- **docker-compose.yml** - Service orchestration
- **services/*/Dockerfile** - Custom images

---

**You're all set to build and push Docker images! 🚀**

Next: Follow DOCKER-PUSH-GUIDE.md for step-by-step instructions
