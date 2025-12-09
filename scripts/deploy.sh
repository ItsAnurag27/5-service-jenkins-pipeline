#!/bin/bash
set -e

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Installing Docker..."
sudo yum update -y 2>&1 | tail -5 || true
# Use --allowerasing to fix curl conflict
sudo yum install -y --allowerasing docker git curl 2>&1 | tail -10 || {
  log "[WARNING] Initial install had issues, retrying..."
  sudo yum install -y docker git 2>&1 | tail -10 || true
}

log "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

log "Adding ec2-user to docker group..."
sudo usermod -aG docker ec2-user
sudo chmod 666 /var/run/docker.sock

log "Waiting for Docker daemon to be ready..."
sleep 3

log "Cloning Docker repository..."
cd ~ || exit 1
rm -rf 5-service-jenkins-pipeline 2>/dev/null || true
git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git

cd ~/5-service-jenkins-pipeline || exit 1

export DOCKER_REPO="service-pipeline"

log "Building Docker images on EC2..."
docker-compose build --no-cache

log "Deploying Docker services with docker-compose..."
docker-compose down 2>/dev/null || true
docker-compose up -d

log "[SUCCESS] All services deployed on EC2"
