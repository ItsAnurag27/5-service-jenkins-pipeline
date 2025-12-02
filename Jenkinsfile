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
                            
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" @"
                                # Update and install Docker
                                sudo yum update -y >/dev/null 2>&1
                                sudo yum install -y docker git >/dev/null 2>&1
                                sudo systemctl start docker
                                sudo systemctl enable docker
                                sudo usermod -aG docker ec2-user
                                
                                # Install Docker Compose
                                sudo curl -s -L "https://github.com/docker/compose/releases/latest/download/docker-compose-`$(uname -s)-`$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1
                                sudo chmod +x /usr/local/bin/docker-compose
                                
                                # Install buildx plugin for docker
                                mkdir -p ~/.docker/cli-plugins
                                curl -s -L "https://github.com/docker/buildx/releases/latest/download/buildx-v0.17.0.linux-`arch`" -o ~/.docker/cli-plugins/docker-buildx 2>/dev/null || true
                                chmod +x ~/.docker/cli-plugins/docker-buildx 2>/dev/null || true
                                
                                # Clone repository
                                rm -rf ~/5-service-jenkins-pipeline
                                git clone https://github.com/ItsAnurag27/5-service-jenkins-pipeline.git ~/5-service-jenkins-pipeline
                                cd ~/5-service-jenkins-pipeline
                                
                                # Wait for docker group changes
                                sleep 2
                                
                                # Deploy services - force build from Dockerfiles
                                export DOCKER_REPO=service-pipeline
                                docker-compose down 2>/dev/null || true
                                docker-compose up -d --build 2>&1 | head -50
                                sleep 3
                                
                                echo "[OK] Services deployed on EC2"
"@
                            
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
                            
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" @"
                                echo "Verifying services..."
                                docker ps
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
