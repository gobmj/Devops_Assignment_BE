pipeline {
    agent any
    environment {
        DOCKER_IMAGE = 'govindmj2002/todo-app'
        TAG = '23'
        NAMESPACE = 'default'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Login to Docker Hub') {
            steps {
                withCredentials([string(credentialsId: 'docker-hub-password', variable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u govindmj2002 --password-stdin'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t $DOCKER_IMAGE:$TAG .
                docker tag $DOCKER_IMAGE:$TAG $DOCKER_IMAGE:latest
                """
            }
        }
        stage('Push Docker Image') {
            steps {
                sh """
                docker push $DOCKER_IMAGE:$TAG
                docker push $DOCKER_IMAGE:latest
                """
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh "kubectl set image deployment/todo-app todo=$DOCKER_IMAGE:$TAG --namespace=$NAMESPACE"
            }
        }
        stage('Shift Traffic to Canary') {
            steps {
                script {
                    sh 'echo "apiVersion: networking.istio.io/v1alpha3" > /tmp/virtual-service.yaml'
                    sh 'echo "kind: VirtualService" >> /tmp/virtual-service.yaml'
                    sh 'echo "metadata:" >> /tmp/virtual-service.yaml'
                    sh 'echo "  name: todo-virtual-service" >> /tmp/virtual-service.yaml'
                    sh 'echo "spec:" >> /tmp/virtual-service.yaml'
                    sh 'echo "  hosts:" >> /tmp/virtual-service.yaml'
                    sh 'echo "  - todo.example.com" >> /tmp/virtual-service.yaml'
                    sh 'echo "  gateways:" >> /tmp/virtual-service.yaml'
                    sh 'echo "  - todo-gateway" >> /tmp/virtual-service.yaml'
                    sh 'echo "  http:" >> /tmp/virtual-service.yaml'
                    sh 'echo "  - route:" >> /tmp/virtual-service.yaml'
                    sh 'echo "    - destination:" >> /tmp/virtual-service.yaml'
                    sh 'echo "        host: todo-app" >> /tmp/virtual-service.yaml'
                    sh 'echo "        subset: canary" >> /tmp/virtual-service.yaml'
                    sh 'kubectl apply -f /tmp/virtual-service.yaml'
                }
            }
        }
        stage('Run Canary Tests') {
            steps {
                script {
                    // Add actual canary testing scripts here
                    echo "Running Canary Tests..."
                }
            }
        }
        stage('Shift Traffic to Primary') {
            steps {
                script {
                    // Add logic to shift traffic fully to primary if tests pass
                    echo "Shifting Traffic to Primary..."
                }
            }
        }
    }
}