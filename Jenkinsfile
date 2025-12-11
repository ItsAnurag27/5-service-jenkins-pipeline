pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    environment {
        DOCKER_REPO = "service-pipeline"
        IMAGE_TAG  = "${BUILD_NUMBER}"
        EC2_USER   = "ec2-user"
        EC2_IP     = "44.215.75.53"
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
                sh 'docker --version'
                sh 'docker-compose --version'
            }
        }

        stage('Build Images') {
            steps {
                echo 'Building Docker images...'
                retry(3) {
                    sh '''
                        set +e
                        retryCount=0
                        maxRetries=2
                        
                        while [ $retryCount -le $maxRetries ]; do
                            docker-compose build --no-cache
                            if [ $? -eq 0 ]; then
                                exit 0
                            else
                                retryCount=$((retryCount + 1))
                                if [ $retryCount -le $maxRetries ]; then
                                    echo "[RETRY] Build failed, attempt $retryCount/$maxRetries. Waiting 10 seconds..."
                                    sleep 10
                                else
                                    exit 1
                                fi
                            fi
                        done
                    '''
                }
            }
        }

        stage('Tag Images') {
            steps {
                echo 'Tagging images...'
                sh '''
                    repo=$DOCKER_REPO
                    tag=$IMAGE_TAG
                    
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
                    docker tag "${repo}:grafana" "${repo}:grafana-${tag}"
                    docker tag "${repo}:grafana" "${repo}:grafana-latest"
                    docker tag "${repo}:prometheus" "${repo}:prometheus-${tag}"
                    docker tag "${repo}:prometheus" "${repo}:prometheus-latest"
                    docker tag "${repo}:jenkins" "${repo}:jenkins-${tag}"
                    docker tag "${repo}:jenkins" "${repo}:jenkins-latest"
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
                    withCredentials([sshUserPrivateKey(credentialsId: 'demo', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        sh '''
                            sshKey=$SSH_KEY_FILE
                            ec2User=$EC2_USER
                            ec2Ip=$EC2_IP
                            
                            echo "[*] Setting SSH key permissions..."
                            chmod 600 "$sshKey"
                            echo "[OK] SSH key permissions set"
                            
                            echo "[*] Testing SSH connection to EC2..."
                            if ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 "$ec2User@$ec2Ip" "echo 'SSH connection successful'; uname -a"; then
                                echo "[OK] SSH connection to EC2 verified"
                            else
                                echo "[ERROR] Failed to connect to EC2 (exit code: $?)"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo 'Cleaning up old images...'
                sh 'docker image prune -f --filter "until=24h"' || true
            }
        }

        stage('Deploy to EC2') {
            steps {
                echo 'Deploying services to EC2...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'demo', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        sh '''
                            sshKey=$SSH_KEY_FILE
                            ec2User=$EC2_USER
                            ec2Ip=$EC2_IP
                            
                            echo "[*] Setting SSH key permissions..."
                            chmod 600 "$sshKey"
                            echo "[OK] SSH key permissions set"
                            
                            echo "[*] Images will be built directly on EC2..."
                            
                            deployScriptPath="$WORKSPACE/scripts/deploy.sh"

                            if [ ! -f "$deployScriptPath" ]; then
                                echo "[ERROR] Deploy script not found at $deployScriptPath"
                                exit 1
                            fi

                            echo "[*] Copying deploy.sh to EC2 via scp..."
                            scp -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                "$deployScriptPath" "$ec2User@$ec2Ip:/tmp/deploy.sh"

                            if [ $? -ne 0 ]; then
                                echo "[ERROR] scp failed with exit code $?"
                                exit 1
                            fi

                            echo "[*] Running deploy.sh on EC2..."
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
                                "$ec2User@$ec2Ip" "chmod +x /tmp/deploy.sh && bash -x /tmp/deploy.sh 2>&1"

                            if [ $? -eq 0 ]; then
                                echo "[OK] EC2 deployment completed"
                            else
                                echo "[ERROR] EC2 deployment failed (exit code: $?)"
                                echo "[INFO] Check EC2 logs at /tmp/deploy.log"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        stage('Verify EC2 Deployment') {
            steps {
                echo 'Verifying EC2 deployment...'
                script {
                    withCredentials([sshUserPrivateKey(credentialsId: 'demo', keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')]) {
                        sh '''
                            sshKey=$SSH_KEY_FILE
                            ec2User=$EC2_USER
                            ec2Ip=$EC2_IP
                            
                            echo "[*] Setting SSH key permissions..."
                            chmod 600 "$sshKey"
                            echo "[OK] SSH key permissions set"
                            
                            echo "[*] Checking service status on $ec2Ip..."
                            
                            ssh -i "$sshKey" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ec2User@$ec2Ip" bash << 'VERIFY_SCRIPT'
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
curl -s http://localhost:3001 > /dev/null && echo "[OK] Grafana running on port 3001" || echo "[ERROR] Grafana DOWN"
curl -s http://localhost:9093 > /dev/null && echo "[OK] Prometheus running on port 9093" || echo "[ERROR] Prometheus DOWN"
curl -s http://localhost:8001 > /dev/null && echo "[OK] Jenkins API Gateway running on port 8001" || echo "[ERROR] Jenkins Gateway DOWN"
curl -s http://localhost:9092 > /dev/null && echo "[OK] Hello-World running on port 9092" || echo "[ERROR] Hello-World DOWN"
curl -s http://localhost:5000 > /dev/null && echo "[OK] Docker Registry running on port 5000" || echo "[ERROR] Docker Registry DOWN"
curl -s http://localhost:8002 > /dev/null && echo "[OK] Portainer running on port 8002" || echo "[ERROR] Portainer DOWN"
curl -s http://localhost:8200 > /dev/null && echo "[OK] Vault running on port 8200" || echo "[ERROR] Vault DOWN"
curl -s http://localhost:8500 > /dev/null && echo "[OK] Consul running on port 8500" || echo "[ERROR] Consul DOWN"
curl -s http://localhost:2379 > /dev/null && echo "[OK] etcd running on port 2379" || echo "[ERROR] etcd DOWN"
VERIFY_SCRIPT
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
