pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = 'docker-creds'
    }

    stages {
        stage('Installing Dependencies') {
            steps {
                bat 'npm install'
            }
        }
        stage('Scanning Dependencies') {
            steps {
                dependencyCheck additionalArguments: 'dependency-check --scan . --out target --disableYarnAudit --format ALL', odcInstallation: 'OWSAP-10'
            }
        }
        stage('Code Coverage'){
            steps {
                catchError(buildResult: 'SUCCESS', message: 'OOPS! WE MISSED COVERAGE!!!', stageResult: 'UNSTABLE') {
                    bat 'npm run coverage'
                }
            }
        }
        stage('SAST - SonarQube') {
            steps {
                withSonarQubeEnv('sonarserver') {
                    bat '''
                    sonar-scanner.bat \
                    -D"sonar.projectKey=pizza_app" \
                    -D"sonar.sources=."  
                    '''
                }
            }
        }

        stage('Building Docker Image'){
            steps {
                bat 'docker build --no-cache -t sganesh3010/pizza-app:%GIT_COMMIT% -f Dockerfile .'
            }
        }
        stage('Push Image to DockerHub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-creds', url: "") {
                    bat 'docker push sganesh3010/pizza-app:%GIT_COMMIT%'
                }
            }
        }
        stage('Update Image for Kubernetes') {
            steps {
                script {
                    def newImageTag = "${GIT_COMMIT}"
                    bat """
                    sed -i 's|image: sganesh3010/pizza-app:.*|image: sganesh3010/pizza-app:${newImageTag}|' manifests/deployment.yaml
                    git config --global user.email "jenkins@example.com"
                    git config --global user.name "Jenkins"
                    git add manifests/deployment.yaml
                    git commit -m "Updated image tag to ${newImageTag}"
                    git push origin feature/enabling-cicd
                    """
                }
            }
        }
        stage('Create PR for Review') {
            steps {
                script {
                    bat """
                    gh pr create --title 'Deploy Feature Branch' --body 'Auto-generated PR for deployment' --base main --head feature/enabling-cicd
                    """
                }
            }
        }
    }
}
