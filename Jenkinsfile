pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    environment {
        DOCKER_REPO = "itsanurag27/service-pipeline"
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_USER = "ec2-user"
        EC2_IP = "98.82.113.29"
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
                bat 'docker --version'
                bat 'docker-compose --version'
            }
        }

        stage('Build Images') {
            steps {
                echo 'Building Docker images...'
                bat 'docker-compose build'
            }
        }

        stage('Tag Images') {
            steps {
                echo 'Tagging images...'
                bat '''
                    docker tag %DOCKER_REPO%:nginx %DOCKER_REPO%:nginx-%IMAGE_TAG%
                    docker tag %DOCKER_REPO%:nginx %DOCKER_REPO%:nginx-latest
                    docker tag %DOCKER_REPO%:httpd %DOCKER_REPO%:httpd-%IMAGE_TAG%
                    docker tag %DOCKER_REPO%:httpd %DOCKER_REPO%:httpd-latest
                    docker tag %DOCKER_REPO%:caddy %DOCKER_REPO%:caddy-%IMAGE_TAG%
                    docker tag %DOCKER_REPO%:caddy %DOCKER_REPO%:caddy-latest
                    docker tag %DOCKER_REPO%:traefik %DOCKER_REPO%:traefik-%IMAGE_TAG%
                    docker tag %DOCKER_REPO%:traefik %DOCKER_REPO%:traefik-latest
                    docker tag %DOCKER_REPO%:app %DOCKER_REPO%:app-%IMAGE_TAG%
                    docker tag %DOCKER_REPO%:app %DOCKER_REPO%:app-latest
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing images to Docker Hub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        powershell '''
                            Write-Host "[*] Logging in to Docker Hub..."
                            $env:DOCKER_PASSWORD | docker login -u $env:DOCKER_USERNAME --password-stdin
                            
                            if ($LASTEXITCODE -ne 0) {
                                throw "Docker Hub login failed!"
                            }
                            
                            Write-Host "[OK] Docker Hub login successful"
                            
                            Write-Host "[*] Pushing all images to Docker Hub..."
                            docker push "${env:DOCKER_REPO}:nginx-${env:IMAGE_TAG}"
                            docker push "${env:DOCKER_REPO}:nginx-latest"
                            docker push "${env:DOCKER_REPO}:httpd-${env:IMAGE_TAG}"
                            docker push "${env:DOCKER_REPO}:httpd-latest"
                            docker push "${env:DOCKER_REPO}:caddy-${env:IMAGE_TAG}"
                            docker push "${env:DOCKER_REPO}:caddy-latest"
                            docker push "${env:DOCKER_REPO}:traefik-${env:IMAGE_TAG}"
                            docker push "${env:DOCKER_REPO}:traefik-latest"
                            docker push "${env:DOCKER_REPO}:app-${env:IMAGE_TAG}"
                            docker push "${env:DOCKER_REPO}:app-latest"
                            
                            Write-Host "[OK] All images pushed successfully"
                            docker logout
                        '''
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up old images...'
                bat 'docker image prune -f --filter "until=24h"'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo 'Deploying to EC2...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-key', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            $dockerRepo = $env:DOCKER_REPO
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
                                
                                # Create .env file
                                cat > .env << 'ENVEOF'
DOCKER_REPO=$dockerRepo
IMAGE_TAG=$imageTag
ENVEOF
                                
                                # Login to Docker Hub and pull images
                                docker-compose pull
                                
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
                                curl -s http://localhost:9082 > /dev/null && echo "[OK] Caddy running on port 9082" || echo "[ERROR] Caddy DOWN"
                                curl -s http://localhost:9088 > /dev/null && echo "[OK] Traefik running on port 9088" || echo "[ERROR] Traefik DOWN"
"@
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded! Images pushed to Docker Hub."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
