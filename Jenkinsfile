pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    environment {
        DOCKER_REPO = "service-pipeline"
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_USER = "ec2-user"
        EC2_IP = "34.227.107.245"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying environment...'
                powershell 'docker --version'
                powershell 'docker-compose --version'
            }
        }

        stage('Build Images') {
            steps {
                echo 'Building Docker images...'
                powershell 'docker-compose build'
            }
        }

        stage('Tag Images') {
            steps {
                echo 'Tagging images...'
                powershell '''
                    $repo = $env:DOCKER_REPO
                    $tag = $env:IMAGE_TAG
                    
                    # Original 5 services
                    docker tag "${repo}:nginx" "${repo}:nginx-${tag}"
                    docker tag "${repo}:nginx" "${repo}:nginx-latest"
                    docker tag "${repo}:httpd" "${repo}:httpd-${tag}"
                    docker tag "${repo}:httpd" "${repo}:httpd-latest"
                    docker tag "${repo}:busybox" "${repo}:busybox-${tag}"
                    docker tag "${repo}:busybox" "${repo}:busybox-latest"
                    docker tag "${repo}:memcached" "${repo}:memcached-${tag}"
                    docker tag "${repo}:memcached" "${repo}:memcached-latest"
                    docker tag "${repo}:app" "${repo}:app-${tag}"
                    docker tag "${repo}:app" "${repo}:app-latest"
                    
                    # New 15 services
                    docker tag "${repo}:alpine" "${repo}:alpine-${tag}"
                    docker tag "${repo}:alpine" "${repo}:alpine-latest"
                    docker tag "${repo}:redis" "${repo}:redis-${tag}"
                    docker tag "${repo}:redis" "${repo}:redis-latest"
                    docker tag "${repo}:postgres" "${repo}:postgres-${tag}"
                    docker tag "${repo}:postgres" "${repo}:postgres-latest"
                    docker tag "${repo}:mongo" "${repo}:mongo-${tag}"
                    docker tag "${repo}:mongo" "${repo}:mongo-latest"
                    docker tag "${repo}:mysql" "${repo}:mysql-${tag}"
                    docker tag "${repo}:mysql" "${repo}:mysql-latest"
                    docker tag "${repo}:rabbitmq" "${repo}:rabbitmq-${tag}"
                    docker tag "${repo}:rabbitmq" "${repo}:rabbitmq-latest"
                    docker tag "${repo}:elasticsearch" "${repo}:elasticsearch-${tag}"
                    docker tag "${repo}:elasticsearch" "${repo}:elasticsearch-latest"
                    docker tag "${repo}:grafana" "${repo}:grafana-${tag}"
                    docker tag "${repo}:grafana" "${repo}:grafana-latest"
                    docker tag "${repo}:prometheus" "${repo}:prometheus-${tag}"
                    docker tag "${repo}:prometheus" "${repo}:prometheus-latest"
                    docker tag "${repo}:jenkins" "${repo}:jenkins-${tag}"
                    docker tag "${repo}:jenkins" "${repo}:jenkins-latest"
                    docker tag "${repo}:gitlab" "${repo}:gitlab-${tag}"
                    docker tag "${repo}:gitlab" "${repo}:gitlab-latest"
                    docker tag "${repo}:docker-registry" "${repo}:docker-registry-${tag}"
                    docker tag "${repo}:docker-registry" "${repo}:docker-registry-latest"
                    docker tag "${repo}:portainer" "${repo}:portainer-${tag}"
                    docker tag "${repo}:portainer" "${repo}:portainer-latest"
                    docker tag "${repo}:vault" "${repo}:vault-${tag}"
                    docker tag "${repo}:vault" "${repo}:vault-latest"
                    docker tag "${repo}:etcd" "${repo}:etcd-${tag}"
                    docker tag "${repo}:etcd" "${repo}:etcd-latest"
                '''
            }
        }

        stage('Push to EC2') {
            steps {
                echo 'Verifying SSH connection to EC2...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            
                            Write-Host "[*] Fixing SSH key permissions..."
                            try {
                                # Remove all inherited permissions
                                icacls "$sshKey" /inheritance:r 2>&1 | Out-Null
                                # Grant full control to SYSTEM only
                                icacls "$sshKey" /grant:r "SYSTEM`:`(F`)" 2>&1 | Out-Null
                                # Grant full control to Administrators only
                                icacls "$sshKey" /grant:r "Administrators`:`(F`)" 2>&1 | Out-Null
                                Write-Host "[OK] SSH key permissions fixed"
                            } catch {
                                Write-Host "[WARNING] Could not fix permissions: $_"
                            }
                            
                            Write-Host "[*] Testing SSH connection to EC2..."
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 "$ec2User@$ec2Ip" "echo 'SSH connection successful'; uname -a"
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "[OK] SSH connection to EC2 verified"
                            } else {
                                Write-Host "[ERROR] Failed to connect to EC2 (exit code: $LASTEXITCODE)"
                                exit 1
                            }
                        '''
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up old images...'
                powershell 'docker image prune -f --filter "until=24h"'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo 'Deploying services to EC2...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            
                            Write-Host "[*] Fixing SSH key permissions..."
                            icacls "$sshKey" /inheritance:r 2>&1 | Out-Null
                            icacls "$sshKey" /grant:r "SYSTEM`:`(F`)" 2>&1 | Out-Null
                            icacls "$sshKey" /grant:r "Administrators`:`(F`)" 2>&1 | Out-Null
                            Write-Host "[OK] SSH key permissions fixed"
                            
                            Write-Host "[*] Deploying to EC2 at $ec2Ip..."
                            
                            # Create deployment script file with LF line endings only
                            $deployScript = @"
#!/bin/bash
set -e

# Update and install Docker
sudo yum update -y >/dev/null 2>&1
sudo yum install -y docker git >/dev/null 2>&1
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group and apply immediately
sudo usermod -aG docker ec2-user

# Install Docker Compose v2
sudo curl -s -L "https://github.com/docker/compose/releases/latest/download/docker-compose-`$(uname -s)-`$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker Compose version
docker-compose --version

# Clone repository
rm -rf ~/5-service-jenkins-pipeline
git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git ~/5-service-jenkins-pipeline
cd ~/5-service-jenkins-pipeline

# Deploy services using newgrp to apply docker group
newgrp docker << 'DOCKER_EOF'
  # Wait for docker daemon
  sleep 2
  
  # Verify docker access
  docker ps > /dev/null
  
  # Deploy services
  docker-compose down 2>/dev/null || true
  docker-compose up -d

  echo "[OK] Services deployed on EC2"
DOCKER_EOF

"@

                            # Write deployment script as pure LF with no BOM
                            $tempFile = "$env:TEMP/deploy_$(Get-Random).sh"
                            $deployScriptLF = $deployScript -replace "`r`n", "`n"
                            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                            [System.IO.File]::WriteAllText($tempFile, $deployScriptLF, $utf8NoBom)
                            
                            # Convert file to Unix line endings (remove any CRLF that might exist)
                            $content = [System.IO.File]::ReadAllText($tempFile, [System.Text.Encoding]::UTF8)
                            $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
                            [System.IO.File]::WriteAllText($tempFile, $content, $utf8NoBom)
                            
                            # Pipe to SSH - file is now guaranteed LF-only, no BOM
                            Get-Content -Raw $tempFile | ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" bash
                            Remove-Item $tempFile -Force
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "[OK] EC2 deployment completed"
                            } else {
                                Write-Host "[ERROR] EC2 deployment failed (exit code: $LASTEXITCODE)"
                                exit 1
                            }
                        '''
                    }
                }
            }
        }

        stage('Verify EC2 Deployment') {
            steps {
                echo 'Verifying EC2 deployment...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            
                            Write-Host "[*] Fixing SSH key permissions..."
                            icacls "$sshKey" /inheritance:r 2>&1 | Out-Null
                            icacls "$sshKey" /grant:r "SYSTEM`:`(F`)" 2>&1 | Out-Null
                            icacls "$sshKey" /grant:r "Administrators`:`(F`)" 2>&1 | Out-Null
                            Write-Host "[OK] SSH key permissions fixed"
                            
                            Write-Host "[*] Checking service status on $ec2Ip..."
                            
                            # Create verification script with LF line endings only
                            $verifyScript = @"
#!/bin/bash
echo "Verifying services..."
docker ps

# Check services by port
curl -s http://localhost:3000 > /dev/null && echo "[OK] App service running on port 3000" || echo "[ERROR] App service DOWN"
curl -s http://localhost:9080 > /dev/null && echo "[OK] Nginx running on port 9080" || echo "[ERROR] Nginx DOWN"
curl -s http://localhost:9081 > /dev/null && echo "[OK] Apache running on port 9081" || echo "[ERROR] Apache DOWN"
curl -s http://localhost:9082 > /dev/null && echo "[OK] BusyBox running on port 9082" || echo "[ERROR] BusyBox DOWN"
curl -s http://localhost:9083 > /dev/null && echo "[OK] Memcached running on port 9083" || echo "[ERROR] Memcached DOWN"
curl -s http://localhost:9084 > /dev/null && echo "[OK] Alpine running on port 9084" || echo "[ERROR] Alpine DOWN"
curl -s http://localhost:9085 > /dev/null && echo "[OK] Redis running on port 9085" || echo "[ERROR] Redis DOWN"
curl -s http://localhost:9086 > /dev/null && echo "[OK] PostgreSQL running on port 9086" || echo "[ERROR] PostgreSQL DOWN"
curl -s http://localhost:9087 > /dev/null && echo "[OK] MongoDB running on port 9087" || echo "[ERROR] MongoDB DOWN"
curl -s http://localhost:9088 > /dev/null && echo "[OK] MySQL running on port 9088" || echo "[ERROR] MySQL DOWN"
curl -s http://localhost:9089 > /dev/null && echo "[OK] RabbitMQ running on port 9089" || echo "[ERROR] RabbitMQ DOWN"
curl -s http://localhost:9091 > /dev/null && echo "[OK] Elasticsearch running on port 9091" || echo "[ERROR] Elasticsearch DOWN"
curl -s http://localhost:3001 > /dev/null && echo "[OK] Grafana running on port 3001" || echo "[ERROR] Grafana DOWN"
curl -s http://localhost:9093 > /dev/null && echo "[OK] Prometheus running on port 9093" || echo "[ERROR] Prometheus DOWN"
curl -s http://localhost:8001 > /dev/null && echo "[OK] Jenkins API Gateway running on port 8001" || echo "[ERROR] Jenkins Gateway DOWN"
curl -s http://localhost:9092 > /dev/null && echo "[OK] GitLab running on port 9092" || echo "[ERROR] GitLab DOWN"
curl -s http://localhost:5000 > /dev/null && echo "[OK] Docker Registry running on port 5000" || echo "[ERROR] Docker Registry DOWN"
curl -s http://localhost:8002 > /dev/null && echo "[OK] Portainer running on port 8002" || echo "[ERROR] Portainer DOWN"
curl -s http://localhost:8200 > /dev/null && echo "[OK] Vault running on port 8200" || echo "[ERROR] Vault DOWN"
curl -s http://localhost:8500 > /dev/null && echo "[OK] Consul running on port 8500" || echo "[ERROR] Consul DOWN"
curl -s http://localhost:2379 > /dev/null && echo "[OK] etcd running on port 2379" || echo "[ERROR] etcd DOWN"
"@

                            # Write verification script as pure LF with no BOM
                            $tempFile = "$env:TEMP/verify_$(Get-Random).sh"
                            $verifyScriptLF = $verifyScript -replace "`r`n", "`n"
                            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                            [System.IO.File]::WriteAllText($tempFile, $verifyScriptLF, $utf8NoBom)
                            
                            # Convert file to Unix line endings (remove any CRLF that might exist)
                            $content = [System.IO.File]::ReadAllText($tempFile, [System.Text.Encoding]::UTF8)
                            $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
                            [System.IO.File]::WriteAllText($tempFile, $content, $utf8NoBom)
                            
                            # Pipe to SSH - file is now guaranteed LF-only, no BOM
                            Get-Content -Raw $tempFile | ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" bash
                            Remove-Item $tempFile -Force
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Images deployed directly to EC2."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
