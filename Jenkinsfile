pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    environment {
        DOCKER_HUB_CREDS = credentials('docker-hub-creds')
        DOCKER_USERNAME = "${DOCKER_HUB_CREDS_USR}"
        DOCKER_PASSWORD = "${DOCKER_HUB_CREDS_PSW}"
        DOCKER_REPO = "${DOCKER_USERNAME}/service-pipeline"
        IMAGE_TAG = "${BUILD_NUMBER}"
        EC2_USER = "ec2-user"
        EC2_IP = "98.82.113.29"
        EC2_SSH_KEY = credentials('jenkins-key')
    }

    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Verify') {
            steps {
                echo '🔍 Verifying environment...'
                bat 'docker --version'
                bat 'docker-compose --version'
            }
        }

        stage('Build Images') {
            steps {
                echo '🔨 Building Docker images...'
                bat 'docker-compose build'
            }
        }

        stage('Tag Images') {
            steps {
                echo '🏷️  Tagging images...'
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
                echo '📤 Pushing images to Docker Hub...'
                script {
                    powershell '''
                        # Login to Docker Hub using PowerShell pipe
                        $env:DOCKER_PASSWORD | docker login -u $env:DOCKER_USERNAME --password-stdin
                        
                        # Push all images
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
                        
                        docker logout
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up old images...'
                bat 'docker image prune -f --filter "until=24h"'
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                script {
                    withCredentials([file(credentialsId: 'jenkins-key', variable: 'SSH_KEY_FILE')]) {
                        powershell '''
                            # Variables
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            $dockerUser = $env:DOCKER_USERNAME
                            $dockerPass = $env:DOCKER_PASSWORD
                            $dockerRepo = $env:DOCKER_REPO
                            $imageTag = $env:IMAGE_TAG
                            
                            Write-Host "🔐 Deploying to EC2 at $ec2Ip as $ec2User..."
                            
                            # SSH into EC2 and execute deployment commands
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
                                echo "$dockerPass" | docker login -u "$dockerUser" --password-stdin
                                docker-compose pull
                                
                                # Redeploy services
                                docker-compose down
                                docker-compose up -d
                                docker-compose ps
                                
                                echo "✅ EC2 Deployment completed!"
"@
                            
                            # Execute SSH command
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" $sshCommand
                        '''
                    }
                }
            }
        }

        stage('Verify EC2 Deployment') {
            steps {
                echo '✅ Verifying EC2 deployment...'
                script {
                    withCredentials([file(credentialsId: 'jenkins-key', variable: 'SSH_KEY_FILE')]) {
                        powershell '''
                            $sshKey = $env:SSH_KEY_FILE
                            $ec2User = $env:EC2_USER
                            $ec2Ip = $env:EC2_IP
                            
                            Write-Host "🔍 Checking service status on $ec2Ip..."
                            
                            # SSH and check services
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" @"
                                echo "Verifying services..."
                                curl -s http://localhost:3000 > /dev/null && echo "✅ App service running on port 3000" || echo "❌ App service DOWN"
                                curl -s http://localhost:9080 > /dev/null && echo "✅ Nginx running on port 9080" || echo "❌ Nginx DOWN"
                                curl -s http://localhost:9081 > /dev/null && echo "✅ Apache running on port 9081" || echo "❌ Apache DOWN"
                                curl -s http://localhost:9082 > /dev/null && echo "✅ Caddy running on port 9082" || echo "❌ Caddy DOWN"
                                curl -s http://localhost:9088 > /dev/null && echo "✅ Traefik running on port 9088" || echo "❌ Traefik DOWN"
"@
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline succeeded! Images pushed to Docker Hub."
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
    }
}
