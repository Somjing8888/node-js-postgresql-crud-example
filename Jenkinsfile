pipeline {
    agent any

    // ฟังก์ชันสำหรับสร้าง Git tag สุ่ม
    def generateRandomGitTag() {
        def randomNum = (int) (Math.random() * 1000000)
        def gitTag = "v${randomNum}"
        return gitTag
    }

    stages {
        stage('Init') {
            steps {
                echo 'Initialization...'
            }
        }
        stage('Build') {
            steps {
                git branch: 'Develop', credentialsId: 'AuthenGit', url: 'https://github.com/Somjing8888/node-js-postgresql-crud-example.git'
                echo "Start building Docker image"
            
                def gitTag = generateRandomGitTag()
                echo "Random Git tag: ${gitTag}"

                withCredentials([usernamePassword(credentialsId: 'AuthenDockerHub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh 'docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}'
                    sh 'docker build -t exam01nodejs:latest .'
                    echo "Pushing Docker image to Dockerhub"
                    sh 'docker tag exam01nodejs:latest somjing888/exam01nodejs:${gitTag} '
                    sh 'docker push somjing888/exam01nodejs:${gitTag}'
                    sh 'docker logout'
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
                        echo "Deployment Kubernetes to Staging environment..."
                        withKubeConfig(credentialsId: 'kube-config-staging') {
                            sh 'helm install postgres Exam_03/postgresql --namespace staging || true'
                            sh 'helm upgrade postgres Exam_03/postgresql --namespace staging'
                        }
                    }
                }
                stage('Production') {
                    when {
                        branch 'Master'
                    }
                    steps {
                        echo 'Deployment to Kubernetes Production environment...'
                        withKubeConfig(credentialsId: 'kube-config-production') {
                            sh 'helm install postgres Exam_03/postgresql --namespace production || true'
                            sh 'helm upgrade postgres Exam_03/postgresql --namespace production'
                        }
                    }
                }
            }
        }
    }
}
