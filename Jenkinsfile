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
