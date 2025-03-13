pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "govindmj2002/todo-app"
        K8S_NAMESPACE = "default"  // Replace with your Kubernetes namespace
        CANARY_TRAFFIC_PERCENTAGE = 10  // Adjust the percentage of traffic for the canary release
        ISTIO_HOST = "todo-app"  // Replace with your Istio host name
        ISTIO_PRIMARY_SUBSET = "primary"  // Istio subset name for the primary release
        ISTIO_CANARY_SUBSET = "canary"  // Istio subset name for the canary release
        CANARY_SERVICE_URL = "http://3.110.186.173:32274/health-check"  // Replace with your canary service health check URL
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
                    // Shift a percentage of traffic to the canary release
                    sh """
                    kubectl apply -f - <<EOF
                    apiVersion: networking.istio.io/v1alpha3
                    kind: VirtualService
                    metadata:
                      name: todo-app
                      namespace: $K8S_NAMESPACE
                    spec:
                      hosts:
                        - $ISTIO_HOST
                      http:
                        - route:
                            - destination:
                                host: $ISTIO_HOST
                                subset: $ISTIO_PRIMARY_SUBSET
                              weight: $((100 - $CANARY_TRAFFIC_PERCENTAGE))
                            - destination:
                                host: $ISTIO_HOST
                                subset: $ISTIO_CANARY_SUBSET
                              weight: $CANARY_TRAFFIC_PERCENTAGE
                    EOF
                    """
                }
            }
        }

        stage('Run Canary Tests') {
            steps {
                script {
                    // Run tests to validate the canary release
                    def canaryTestResult = sh(script: "curl -s $CANARY_SERVICE_URL", returnStatus: true)
                    if (canaryTestResult != 0) {
                        error "Canary tests failed. Aborting the deployment."
                    }
                }
            }
        }

        stage('Shift Traffic to Primary') {
            steps {
                script {
                    // Shift all traffic to the primary release if canary tests pass
                    sh """
                    kubectl apply -f - <<EOF
                    apiVersion: networking.istio.io/v1alpha3
                    kind: VirtualService
                    metadata:
                      name: todo-app
                      namespace: $K8S_NAMESPACE
                    spec:
                      hosts:
                        - $ISTIO_HOST
                      http:
                        - route:
                            - destination:
                                host: $ISTIO_HOST
                                subset: $ISTIO_PRIMARY_SUBSET
                              weight: 100
                            - destination:
                                host: $ISTIO_HOST
                                subset: $ISTIO_CANARY_SUBSET
                              weight: 0
                    EOF
                    """
                }
            }
        }
    }
}
