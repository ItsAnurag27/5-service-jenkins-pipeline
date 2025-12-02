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
        EC2_IP = "34.205.131.121"
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
                '''
            }
        }

        stage('Push to EC2') {
            steps {
                echo 'Pushing Docker images directly to EC2...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            $imageTag = $env:IMAGE_TAG
                            $dockerRepo = $env:DOCKER_REPO
                            $tempDir = "C:/temp_docker_images"
                            
                            # Fix SSH key permissions
                            Write-Host "[*] Fixing SSH key permissions..."
                            try {
                                # Remove all inherited permissions and ACEs
                                icacls "$sshKey" /inheritance:r 2>&1 | Out-Null
                                # Grant full control to SYSTEM
                                icacls "$sshKey" /grant:r "SYSTEM`:`(F`)" 2>&1 | Out-Null
                                # Grant full control to Administrators
                                icacls "$sshKey" /grant:r "Administrators`:`(F`)" 2>&1 | Out-Null
                                Write-Host "[OK] SSH key permissions fixed"
                            } catch {
                                Write-Host "[WARNING] Could not fix permissions, continuing anyway: $_"
                            }
                            
                            Write-Host "[*] Creating temporary directory for Docker images..."
                            if (!(Test-Path $tempDir)) {
                                New-Item -ItemType Directory -Path $tempDir | Out-Null
                            }
                            
                            Write-Host "[*] Saving Docker images to tar files..."
                            docker save "${dockerRepo}:nginx-${imageTag}" -o "$tempDir/nginx-${imageTag}.tar"
                            docker save "${dockerRepo}:httpd-${imageTag}" -o "$tempDir/httpd-${imageTag}.tar"
                            docker save "${dockerRepo}:busybox-${imageTag}" -o "$tempDir/busybox-${imageTag}.tar"
                            docker save "${dockerRepo}:memcached-${imageTag}" -o "$tempDir/memcached-${imageTag}.tar"
                            docker save "${dockerRepo}:app-${imageTag}" -o "$tempDir/app-${imageTag}.tar"
                            
                            Write-Host "[OK] Docker images saved"
                            Write-Host "[*] Transferring images to EC2..."
                            
                            # Transfer images via SCP
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" "mkdir -p ~/docker_images"
                            scp -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$tempDir/*.tar" "$ec2User@$ec2Ip`:~/docker_images/"
                            
                            Write-Host "[OK] Images transferred to EC2"
                            Write-Host "[*] Loading images on EC2..."
                            
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" "cd ~/docker_images && for img in *.tar; do echo Loading \$img && docker load -i \$img; done && echo All images loaded successfully"
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "[OK] All images loaded on EC2 successfully"
                                Remove-Item "$tempDir/*.tar" -Force
                                Write-Host "[OK] Temporary files cleaned up"
                            } else {
                                Write-Host "[ERROR] Failed to load images on EC2"
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
                            $imageTag = $env:IMAGE_TAG
                            
                            Write-Host "[*] Deploying to EC2 at $ec2Ip as $ec2User..."
                            
                            $sshCommand = @"
                                # Update system
                                sudo yum update -y
                                
                                # Install Docker
                                sudo yum install -y docker git
                                sudo systemctl start docker
                                sudo systemctl enable docker
                                sudo usermod -aG docker $ec2User
                                
                                # Install Docker Compose
                                sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                                
                                # Clone or update repository
                                if [ -d ~/5-service-jenkins-pipeline ]; then
                                    cd ~/5-service-jenkins-pipeline
                                    git pull origin main
                                else
                                    cd ~
                                    git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git
                                    cd 5-service-jenkins-pipeline
                                fi
                                
                                # Create docker-compose.yml with local images
                                cat > docker-compose.yml << 'COMPOSEEOF'
version: '3.8'
services:
  nginx:
    image: service-pipeline:nginx-${imageTag}
    ports:
      - "9080:80"
    networks:
      - service-net

  httpd:
    image: service-pipeline:httpd-${imageTag}
    ports:
      - "9081:80"
    networks:
      - service-net

  busybox:
    image: service-pipeline:busybox-${imageTag}
    ports:
      - "9082:80"
    networks:
      - service-net

  memcached:
    image: service-pipeline:memcached-${imageTag}
    ports:
      - "9083:80"
    networks:
      - service-net

  app:
    image: service-pipeline:app-${imageTag}
    ports:
      - "3000:3000"
    networks:
      - service-net

networks:
  service-net:
    driver: bridge
COMPOSEEOF
                                
                                # Redeploy services
                                docker-compose down
                                docker-compose up -d
                                docker-compose ps
                                
                                echo "EC2 Deployment completed"
"@
                            
                            Write-Host "[*] Connecting to EC2 via SSH..."
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" $sshCommand
                            
                            if ($LASTEXITCODE -eq 0) {
                                Write-Host "[OK] EC2 deployment completed successfully"
                            } else {
                                Write-Host "[ERROR] EC2 deployment encountered an issue"
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
                            
                            Write-Host "[*] Checking service status on $ec2Ip..."
                            
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" @"
                                echo "Verifying services..."
                                curl -s http://localhost:3000 > /dev/null && echo "[OK] App service running on port 3000" || echo "[ERROR] App service DOWN"
                                curl -s http://localhost:9080 > /dev/null && echo "[OK] Nginx running on port 9080" || echo "[ERROR] Nginx DOWN"
                                curl -s http://localhost:9081 > /dev/null && echo "[OK] Apache running on port 9081" || echo "[ERROR] Apache DOWN"
                                curl -s http://localhost:9082 > /dev/null && echo "[OK] BusyBox running on port 9082" || echo "[ERROR] BusyBox DOWN"
                                curl -s http://localhost:9083 > /dev/null && echo "[OK] Memcached running on port 9083" || echo "[ERROR] Memcached DOWN"
"@
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
