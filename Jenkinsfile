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
        stage('Update Image in K8'){
            steps{
                bat'''
                rm -rf /pizza-menu-gitops-argocd/kubernetes
                https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git
                (Get-Content kubernetes/deployment.yaml) -replace 'image: .*', 'image: ' + "sganesh3010/pizza-app:%GIT_COMMIT%" | Set-Content kubernetes/deployment.yaml
                 git config --global user.email "ganeshsg430@gmail.com"
                 git config --global user.name "Ganesh"
                 git add deployment.yaml
                 git commit -m "Update image to ganesh3010/pizza-app:%GIT_COMMIT%"
                 git push origin main
                '''
            }
        }
    }
}
