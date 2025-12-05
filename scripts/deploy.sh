#!/bin/bash
set -e

# Update and install Docker
sudo yum update -y >/dev/null 2>&1
sudo yum install -y docker git >/dev/null 2>&1
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -aG docker ec2-user

# Install Docker Compose v2
sudo curl -s -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose version
docker-compose --version

# Clone repository
rm -rf ~/5-service-jenkins-pipeline
git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git ~/5-service-jenkins-pipeline
cd ~/5-service-jenkins-pipeline

# Deploy services
docker-compose down 2>/dev/null || true
docker-compose up -d

echo "[OK] Services deployed on EC2"
