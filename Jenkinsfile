pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "govindmj2002/todo-app"
        K8S_NAMESPACE = "default"
        CANARY_TRAFFIC_PERCENTAGE = 10
        ISTIO_HOST = "todo-app"
        ISTIO_PRIMARY_SUBSET = "primary"
        ISTIO_CANARY_SUBSET = "canary"
        CANARY_SERVICE_URL = "http://3.110.186.173:32274/health-check"
    }

    stages {
        stage('Login to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$BUILD_NUMBER .'
                sh 'docker tag $DOCKER_IMAGE:$BUILD_NUMBER $DOCKER_IMAGE:latest'
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $DOCKER_IMAGE:$BUILD_NUMBER'
                sh 'docker push $DOCKER_IMAGE:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl set image deployment/todo-app todo=$DOCKER_IMAGE:$BUILD_NUMBER --namespace=$K8S_NAMESPACE'
            }
        }

        stage('Shift Traffic to Canary') {
            steps {
                script {
                    def canaryTraffic = 100 - (CANARY_TRAFFIC_PERCENTAGE as Integer)
                    def canaryPercentage = CANARY_TRAFFIC_PERCENTAGE as Integer
                    
                    sh '''
                    echo "apiVersion: networking.istio.io/v1alpha3" > /tmp/virtual-service.yaml
                    echo "kind: VirtualService" >> /tmp/virtual-service.yaml
                    echo "metadata:" >> /tmp/virtual-service.yaml
                    echo "  name: todo-app" >> /tmp/virtual-service.yaml
                    echo "  namespace: ${K8S_NAMESPACE}" >> /tmp/virtual-service.yaml
                    echo "spec:" >> /tmp/virtual-service.yaml
                    echo "  hosts:" >> /tmp/virtual-service.yaml
                    echo "    - ${ISTIO_HOST}" >> /tmp/virtual-service.yaml
                    echo "  http:" >> /tmp/virtual-service.yaml
                    echo "    - route:" >> /tmp/virtual-service.yaml
                    echo "        - destination:" >> /tmp/virtual-service.yaml
                    echo "            host: ${ISTIO_HOST}" >> /tmp/virtual-service.yaml
                    echo "            subset: ${ISTIO_PRIMARY_SUBSET}" >> /tmp/virtual-service.yaml
                    echo "          weight: ${canaryTraffic}" >> /tmp/virtual-service.yaml
                    echo "        - destination:" >> /tmp/virtual-service.yaml
                    echo "            host: ${ISTIO_HOST}" >> /tmp/virtual-service.yaml
                    echo "            subset: ${ISTIO_CANARY_SUBSET}" >> /tmp/virtual-service.yaml
                    echo "          weight: ${canaryPercentage}" >> /tmp/virtual-service.yaml
                    '''
                    sh 'kubectl apply -f /tmp/virtual-service.yaml'
                }
            }
        }

        stage('Run Canary Tests') {
            steps {
                script {
                    def canaryTestResult = sh(script: "curl -s $CANARY_SERVICE_URL", returnStatus: true)
                    if (canaryTestResult != 0) {
                        echo "Canary tests failed. Aborting the deployment."
                        error "Canary tests failed."
                    }
                }
            }
        }

        stage('Shift Traffic to Primary') {
            steps {
                script {
                    sh '''
                    echo "apiVersion: networking.istio.io/v1alpha3" > /tmp/virtual-service-primary.yaml
                    echo "kind: VirtualService" >> /tmp/virtual-service-primary.yaml
                    echo "metadata:" >> /tmp/virtual-service-primary.yaml
                    echo "  name: todo-app" >> /tmp/virtual-service-primary.yaml
                    echo "  namespace: ${K8S_NAMESPACE}" >> /tmp/virtual-service-primary.yaml
                    echo "spec:" >> /tmp/virtual-service-primary.yaml
                    echo "  hosts:" >> /tmp/virtual-service-primary.yaml
                    echo "    - ${ISTIO_HOST}" >> /tmp/virtual-service-primary.yaml
                    echo "  http:" >> /tmp/virtual-service-primary.yaml
                    echo "    - route:" >> /tmp/virtual-service-primary.yaml
                    echo "        - destination:" >> /tmp/virtual-service-primary.yaml
                    echo "            host: ${ISTIO_HOST}" >> /tmp/virtual-service-primary.yaml
                    echo "            subset: ${ISTIO_PRIMARY_SUBSET}" >> /tmp/virtual-service-primary.yaml
                    echo "          weight: 100" >> /tmp/virtual-service-primary.yaml
                    echo "        - destination:" >> /tmp/virtual-service-primary.yaml
                    echo "            host: ${ISTIO_HOST}" >> /tmp/virtual-service-primary.yaml
                    echo "            subset: ${ISTIO_CANARY_SUBSET}" >> /tmp/virtual-service-primary.yaml
                    echo "          weight: 0" >> /tmp/virtual-service-primary.yaml
                    '''
                    sh 'kubectl apply -f /tmp/virtual-service-primary.yaml'
                }
            }
        }
    }
}