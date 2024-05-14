pipeline {
    agent any

    stages {
        stage('Init') {
            steps {
                echo 'Initialization...'
            }
        }
        stage('Build') {
            steps {
                script {
                    // ฟังก์ชันสำหรับสร้าง Git tag สุ่ม
                    def generateRandomGitTag() {
                        def randomNum = (int) (Math.random() * 1000000)
                        def gitTag = "v${randomNum}"
                        return gitTag
                    }

                    git branch: 'develop', credentialsId: 'AuthenGit', url: 'https://github.com/Somjing8888/node-js-postgresql-crud-example.git'
                    echo "Start building Docker image"
                
                    def gitTag = generateRandomGitTag()
                    echo "Random Git tag: ${gitTag}"

                    withCredentials([usernamePassword(credentialsId: 'AuthenDockerHub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh 'docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}'
                        sh 'docker build -t exam01nodejs:latest .'
                        echo "Pushing Docker image to Dockerhub"
                        sh 'docker tag exam01nodejs:latest somjing888/exam01nodejs:${gitTag}'
                        sh 'docker push somjing888/exam01nodejs:${gitTag}'
                        sh 'docker logout'
                    }
                }
            }
        }

        stage('Deploy') {
            parallel {
                stage('Staging') {
                    when {
                        branch 'Develop'
                    }
                    steps {
                        script {
                            echo "Deployment Kubernetes to Staging environment..."
                            withKubeConfig(credentialsId: 'kube-config-staging') {
                                sh 'helm install app-node-js helm-node-js -f Exam_03/helm-node-js/values-staging.yaml --namespace staging || true'
                                sh 'helm upgrade app-node-js helm-node-js -f Exam_03/helm-node-js/values-staging.yaml --namespace staging'
                            }
                        }
                    }
                }
                stage('Production') {
                    when {
                        branch 'Master'
                    }
                    steps {
                        script {
                            echo 'Deployment to Kubernetes Production environment...'
                            withKubeConfig(credentialsId: 'kube-config-production') {
                                sh 'helm install app-node-js helm-node-js -f Exam_03/helm-node-js/values-staging.yaml --namespace production || true'
                                sh 'helm upgrade app-node-js helm-node-js -f Exam_03/helm-node-js/values-staging.yaml --namespace production'
                            }
                        }
                    }
                }
            }
        }
    }
}
