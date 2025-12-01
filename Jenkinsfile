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
                    bat '''
                        echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin
                        docker push %DOCKER_REPO%:nginx-%IMAGE_TAG%
                        docker push %DOCKER_REPO%:nginx-latest
                        docker push %DOCKER_REPO%:httpd-%IMAGE_TAG%
                        docker push %DOCKER_REPO%:httpd-latest
                        docker push %DOCKER_REPO%:caddy-%IMAGE_TAG%
                        docker push %DOCKER_REPO%:caddy-latest
                        docker push %DOCKER_REPO%:traefik-%IMAGE_TAG%
                        docker push %DOCKER_REPO%:traefik-latest
                        docker push %DOCKER_REPO%:app-%IMAGE_TAG%
                        docker push %DOCKER_REPO%:app-latest
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
                sshagent(['jenkins-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                            # Update system
                            sudo yum update -y
                            
                            # Install Docker if not present
                            sudo yum install -y docker git
                            sudo systemctl start docker
                            sudo systemctl enable docker
                            sudo usermod -aG docker ${EC2_USER}
                            
                            # Install Docker Compose
                            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
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
                            
                            # Create .env file for docker-compose
                            cat > .env << 'ENVEOF'
DOCKER_REPO=${DOCKER_USERNAME}/service-pipeline
IMAGE_TAG=${IMAGE_TAG}
ENVEOF
                            
                            # Pull latest images from Docker Hub
                            docker login -u ${DOCKER_USERNAME} --password-stdin <<< "${DOCKER_PASSWORD}"
                            docker-compose pull
                            
                            # Stop old containers and start new ones
                            docker-compose down
                            docker-compose up -d
                            
                            # Verify services are running
                            docker-compose ps
                            
                            echo "✅ Deployment to EC2 completed!"
EOF
                    '''
                }
            }
        }

        stage('Verify EC2 Deployment') {
            steps {
                echo '✅ Verifying EC2 deployment...'
                sshagent(['jenkins-key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} << 'EOF'
                            echo "Checking service status..."
                            curl -s http://localhost:3000 && echo "✅ App service running" || echo "❌ App service down"
                            curl -s http://localhost:9080 && echo "✅ Nginx running" || echo "❌ Nginx down"
                            curl -s http://localhost:9081 && echo "✅ Apache running" || echo "❌ Apache down"
                            curl -s http://localhost:9082 && echo "✅ Caddy running" || echo "❌ Caddy down"
                            curl -s http://localhost:9088 && echo "✅ Traefik running" || echo "❌ Traefik down"
EOF
                    '''
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
