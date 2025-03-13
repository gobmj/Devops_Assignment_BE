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

                    sh """
                    cat <<-EOF | kubectl apply -f -
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
                              weight: $canaryTraffic
                            - destination:
                                host: $ISTIO_HOST
                                subset: $ISTIO_CANARY_SUBSET
                              weight: $canaryPercentage
                    EOF
                    """
                }
            }
        }

        stage('Run Canary Tests') {
            steps {
                script {
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
                    sh """
                    cat <<-EOF | kubectl apply -f -
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
