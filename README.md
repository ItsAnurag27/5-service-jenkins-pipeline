# 5-Service Jenkins Pipeline 🚀

Complete Docker microservices stack with CI/CD automation using Jenkins, deployed to AWS EC2.

## 📋 Project Structure

```
├── docker-compose.yml          # Service orchestration
├── Jenkinsfile                 # CI/CD pipeline definition
├── .env                        # Environment configuration
├── README.md                   # This file
├── app/
│   └── index.html             # Welcome page (Port 3000)
├── html/
│   ├── nginx/index.html       # Nginx service (Port 9080)
│   ├── httpd/index.html       # Apache service (Port 9081)
│   └── caddy/index.html       # Caddy service (Port 9082)
└── 📚 Documentation
    ├── JENKINS-START-HERE.md
    ├── JENKINS-SETUP-STEPS.md
    ├── JENKINS-QUICK-SETUP.md
    └── JENKINS-COMPLETE-GUIDE.md
```

## 🐳 Services

| Service | Port | Image | Description |
|---------|------|-------|-------------|
| Nginx | 9080 | `nginx:alpine` | High-performance web server |
| Apache | 9081 | `httpd:2.4-alpine` | Classic HTTP server |
| Caddy | 9082 | `caddy:2-alpine` | Modern web server with auto-HTTPS |
| Traefik | 9088 | `traefik:latest` | Reverse proxy & load balancer |
| App | 3000 | `python:3.11-alpine` | Python application service |

## 🚀 Quick Start

### Local Testing

```bash
# Start all services
docker-compose up -d

# View services
docker-compose ps

# Access services
http://localhost:9080   # Nginx
http://localhost:9081   # Apache
http://localhost:9082   # Caddy
http://localhost:3000   # App
http://localhost:9088   # Traefik Dashboard

# View logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down
```

### Jenkins Deployment

1. Create 3 credentials in Jenkins:
   - `docker-hub-creds`: Docker Hub username/password
   - `ec2-ssh-key`: EC2 SSH private key
   - `ec2-ip`: EC2 public IP address

2. Create Pipeline Job:
   - Name: `service-pipeline-deploy`
   - Pipeline: Script from SCM
   - Repository: This GitHub repo
   - Script Path: `Jenkinsfile`

3. Click **Build Now**

## 📚 Documentation

- **JENKINS-START-HERE.md** - 5-minute quick reference
- **JENKINS-SETUP-STEPS.md** - Detailed 8-step guide
- **JENKINS-COMPLETE-GUIDE.md** - Full documentation
- **JENKINS-QUICK-SETUP.md** - Quick checklist

## 🔑 Required Credentials

```
docker-hub-creds (Username with password)
├── Username: your-docker-hub-username
└── Password: your-docker-hub-password

ec2-ssh-key (SSH Username with private key)
├── Username: ec2-user
└── Private Key: (content of .pem file)

ec2-ip (Secret text)
└── Secret: your-ec2-public-ip
```

## ⚙️ Environment Variables

Edit `.env` file:

```bash
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password
EC2_IP=your-ec2-public-ip
EC2_USER=ec2-user
```

## 🔄 CI/CD Pipeline Stages

1. **Checkout** - Clone code from GitHub
2. **Verify** - Check Docker & Docker Compose
3. **Build Images** - Build all Docker images
4. **Tag Images** - Tag with build number
5. **Push to Docker Hub** - Push images to registry
6. **Deploy to EC2** - Deploy via SSH
7. **Verify Deployment** - Test endpoints
8. **Cleanup** - Remove old images

## 📍 Access After Deployment

After successful Jenkins build:

```
http://EC2_IP:9080   # Nginx
http://EC2_IP:9081   # Apache
http://EC2_IP:9082   # Caddy
http://EC2_IP:3000   # App with Welcome Page
http://EC2_IP:9088   # Traefik Dashboard
```

## 🛡️ EC2 Security Group Rules

Required inbound rules:

| Protocol | Port | Source |
|----------|------|--------|
| TCP | 22 | Jenkins IP |
| TCP | 80 | 0.0.0.0/0 |
| TCP | 443 | 0.0.0.0/0 |
| TCP | 3000 | 0.0.0.0/0 |
| TCP | 9080-9090 | 0.0.0.0/0 |

## 🔧 Troubleshooting

**Port already in use?**
```bash
# Change in docker-compose.yml
# e.g., "9080:80" to "8080:80"
```

**Container not starting?**
```bash
docker-compose logs [service-name]
```

**Permission denied for Docker?**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## 📞 Support

For detailed setup instructions, see:
- JENKINS-SETUP-STEPS.md
- JENKINS-COMPLETE-GUIDE.md

## 📄 License

This project is open source and available under the MIT License.

---

**Repository:** https://github.com/ItsAnurag27/5-service-jenkins-pipeline

**Created:** November 28, 2025
