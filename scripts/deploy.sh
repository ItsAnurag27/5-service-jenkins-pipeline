#!/bin/bash
set -e  # ✅ Exit on error

# Logging function
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Update and install Docker
log "Installing Docker..."
sudo yum update -y >/dev/null 2>&1
sudo yum install -y docker git curl >/dev/null 2>&1

log "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
log "Adding ec2-user to docker group..."
sudo usermod -aG docker ec2-user
sudo chmod 666 /var/run/docker.sock
newgrp docker

# Install Docker Compose v2
log "Installing Docker Compose..."
sudo curl -s -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
log "Verifying Docker Compose..."
docker-compose --version

# Clone repository
log "Cloning Docker repository..."
cd ~ || exit 1
rm -rf 5-service-jenkins-pipeline 2>/dev/null || true
git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git

cd ~/5-service-jenkins-pipeline || exit 1

# Export DOCKER_REPO for docker-compose
export DOCKER_REPO="service-pipeline"

# Deploy services
log "Deploying Docker services with docker-compose..."
docker-compose down 2>/dev/null || true
docker-compose up -d

# Verify services
log "Verifying services..."
docker ps

log "[SUCCESS] All services deployed on EC2 (44.215.75.53)"