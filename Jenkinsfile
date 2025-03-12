pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker build -t govindmj2002/todo-app:$BUILD_NUMBER .'
                sh 'docker tag govindmj2002/todo-app:$BUILD_NUMBER govindmj2002/todo-app:latest'
                sh 'docker push govindmj2002/todo-app:$BUILD_NUMBER'
                sh 'docker push govindmj2002/todo-app:latest'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl set image deployment/todo-app todo=govindmj2002/todo-app:$BUILD_NUMBER'
            }
        }
    }
}
