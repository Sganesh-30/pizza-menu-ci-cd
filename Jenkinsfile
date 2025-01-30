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
                retry(2) {
                bat 'docker build --no-cache -t sganesh3010/pizza-app:%GIT_COMMIT% -f Dockerfile .'
                }
            }    
        }
        stage('Push Image to DockerHub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-creds', url: "") {
                    bat 'docker push sganesh3010/pizza-app:%GIT_COMMIT%'
                }
            }
        }
        stage('Update Kubernetes Manifest') {
            steps {
                script {
                    def newImageTag = "${GIT_COMMIT}"
                    powershell """
                    git clone https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git
                    cd pizza-menu-gitops-argocd
                    git checkout feature/enabling-cicd
                    (Get-Content kubernetes/deployment.yaml) -replace 'image: sganesh3010/pizza-app:.*', 'image: sganesh3010/pizza-app:${newImageTag}' | Set-Content kubernetes/deployment.yaml
                    git config --global user.email "ganeshsg430@gmail.com"
                    git config --global user.name "Ganesh"
                    git add kubernetes/deployment.yaml
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
