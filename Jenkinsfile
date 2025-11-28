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
        EC2_IP = credentials('ec2-ip')
        EC2_USER = "ec2-user"
        EC2_KEY = credentials('ec2-ssh-key')
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
                sh 'docker --version'
                sh 'docker-compose --version'
            }
        }

        stage('Build Images') {
            steps {
                echo '🔨 Building Docker images...'
                sh 'docker-compose build'
            }
        }

        stage('Tag Images') {
            steps {
                echo '🏷️  Tagging images...'
                sh '''
                    docker tag nginx:alpine ${DOCKER_REPO}:nginx-${IMAGE_TAG}
                    docker tag nginx:alpine ${DOCKER_REPO}:nginx-latest
                    docker tag httpd:2.4-alpine ${DOCKER_REPO}:httpd-${IMAGE_TAG}
                    docker tag httpd:2.4-alpine ${DOCKER_REPO}:httpd-latest
                    docker tag caddy:2-alpine ${DOCKER_REPO}:caddy-${IMAGE_TAG}
                    docker tag caddy:2-alpine ${DOCKER_REPO}:caddy-latest
                    docker tag traefik:latest ${DOCKER_REPO}:traefik-${IMAGE_TAG}
                    docker tag traefik:latest ${DOCKER_REPO}:traefik-latest
                    docker tag python:3.11-alpine ${DOCKER_REPO}:app-${IMAGE_TAG}
                    docker tag python:3.11-alpine ${DOCKER_REPO}:app-latest
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing images to Docker Hub...'
                sh '''
                    echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin
                    docker push ${DOCKER_REPO}:nginx-${IMAGE_TAG}
                    docker push ${DOCKER_REPO}:nginx-latest
                    docker push ${DOCKER_REPO}:httpd-${IMAGE_TAG}
                    docker push ${DOCKER_REPO}:httpd-latest
                    docker push ${DOCKER_REPO}:caddy-${IMAGE_TAG}
                    docker push ${DOCKER_REPO}:caddy-latest
                    docker push ${DOCKER_REPO}:traefik-${IMAGE_TAG}
                    docker push ${DOCKER_REPO}:traefik-latest
                    docker push ${DOCKER_REPO}:app-${IMAGE_TAG}
                    docker push ${DOCKER_REPO}:app-latest
                    docker logout
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo '🚀 Deploying to EC2...'
                sh '''
                    scp -i ${EC2_KEY} -o StrictHostKeyChecking=no docker-compose.yml ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
                    scp -i ${EC2_KEY} -o StrictHostKeyChecking=no .env ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
                    scp -i ${EC2_KEY} -o StrictHostKeyChecking=no -r html/ ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
                    scp -i ${EC2_KEY} -o StrictHostKeyChecking=no -r app/ ${EC2_USER}@${EC2_IP}:/home/ec2-user/app/
                    
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "cd /home/ec2-user/app && docker-compose pull && docker-compose down && docker-compose up -d"
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh '''
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "docker-compose ps"
                    
                    echo "Testing service endpoints..."
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:9080"
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:9081"
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:9082"
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:3000"
                    ssh -i ${EC2_KEY} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} "curl -s -o /dev/null -w '%{http_code}' http://localhost:9088"
                '''
            }
        }

        stage('Cleanup') {
            steps {
                echo '🧹 Cleaning up old images...'
                sh '''
                    docker image prune -f --filter "until=24h"
                '''
            }
        }
    }

    post {
        success {
            echo """
            ========================================
            ✅ DEPLOYMENT SUCCESSFUL
            ========================================
            Access Services At:
            Nginx:   http://${EC2_IP}:9080
            Apache:  http://${EC2_IP}:9081
            Caddy:   http://${EC2_IP}:9082
            App:     http://${EC2_IP}:3000
            Traefik: http://${EC2_IP}:9088
            ========================================
            """
        }
        failure {
            echo "❌ Pipeline failed. Check logs for details."
        }
    }
}
