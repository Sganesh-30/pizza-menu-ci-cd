pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = 'docker-creds'
        REPO_URL = 'https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git'
        LOCAL_DIR = 'pizza-menu-gitops-argocd'
        GITHUB_CREDS = credentials('github-acc-creds')
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
        stage('Checkout Manifest & Update Image Tag') {
            steps {
                script {
                    bat '''
                    @echo off
                    echo "Cleaning up existing repository..."
                    if exist pizza-menu-gitops-argocd (
                        rmdir /s /q pizza-menu-gitops-argocd
                        echo "Deleted existing repository."
                    )

                    echo "Cloning repository..."
                    git clone https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git pizza-menu-gitops-argocd
                    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

                    echo "Updating deployment.yaml with new image tag..."
                    powershell -Command "& { (Get-Content pizza-menu-gitops-argocd\\kubernetes\\deployment.yaml) -replace 'image: .*', 'image: sganesh3010/pizza-app:%GIT_COMMIT%' | Set-Content pizza-menu-gitops-argocd\\kubernetes\\deployment.yaml }"
                    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

                    echo "sganesh3010/pizza-app:%GIT_COMMIT%"

                    echo "File updated successfully!"
                    '''
                }
            }
        }
        stage('Commit and Push') {
            steps {
                script {
                    withCredentials([usernameColonPassword(credentialsId: 'github-acc-creds', variable: 'GITHUB_REPO')]) {
                    bat '''

                    git remote -v

                    git ls-remote https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git

                    git remote set-url origin https://%GITHUB_REPO%@github.com/Sganesh-30/pizza-menu-gitops-argocd.git
                    
                    git credential reject https://github.com/Sganesh-30/pizza-menu-gitops-argocd.git

                    @echo off
                    cd pizza-menu-gitops-argocd\\kubernetes

                    echo "Configuring Git..."
                    git config --global user.email "ganeshsg430@gmail.com"
                    git config --global user.name "Ganesh"

                    echo "Checking Git status..."
                    git status

                    echo "Staging changes..."
                    git add deployment.yaml
                    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

                    type deployment.yaml

                    echo "Committing changes..."
                    git commit -m "Update image to sganesh3010/pizza-app:%GIT_COMMIT%"
                    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

                    echo "Pushing changes..."
                    git push -u origin main
                    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

                    echo "Changes pushed successfully!"
                    '''
                    }
                }
            }
        }

    }
}
