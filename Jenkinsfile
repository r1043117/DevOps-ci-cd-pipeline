pipeline {
    agent any

    environment {
        // =========================================
        // CONFIGURATION - Update these values!
        // =========================================
        // Get APP_SERVER IP from: terraform output app_server_public_ip
        APP_SERVER = 'YOUR_APP_SERVER_IP'
        APP_USER = 'admin'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Pulling code from GitHub...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image on ${env.APP_SERVER}..."
                sshagent(['vm1-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${env.APP_USER}@${env.APP_SERVER} '
                            cd /opt/flask-app &&
                            sudo docker build -t flask-app:latest . &&
                            sudo docker stop flask-app || true &&
                            sudo docker rm flask-app || true &&
                            sudo docker run -d --name flask-app --restart unless-stopped -p 5000:5000 flask-app:latest
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                echo 'Checking if app is running...'
                sh "curl -f http://${env.APP_SERVER}:5000/health || exit 1"
            }
        }
    }

    post {
        success {
            echo 'Deployment successful!'
            echo "App URL: http://${env.APP_SERVER}:5000"
        }
        failure {
            echo 'Deployment failed!'
        }
    }
}
