pipeline {
    agent any
    environment {
        PATH = "/opt/homebrew/bin:/usr/local/bin:${env.PATH}"
        AWS_ACCOUNT_ID = '767397732282'
        AWS_DEFAULT_REGION = 'ap-southeast-1'
        IMAGE_REPO_NAME = 'python'
        IMAGE_TAG = "v${env.BUILD_NUMBER}"
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}"
        TOKEN = credentials('UP-TELEGRAM-TOKEN')// "6476965277:AAGbiC51dS9RwGVo7y68OUJ3A1m5SbXVS4A"
        CHAT_ID = credentials('CHAT_ID')//"-4002181219"

        // Telegram Message Pre Build
        CURRENT_BUILD_NUMBER = "${currentBuild.number}"
        GIT_INFO = 'Hello from Jenkin Server '
        TEXT_BREAK = '--------------------------------------------------------------'
        TEXT_PRE_BUILD = "${TEXT_BREAK}\n${GIT_INFO}\n${JOB_NAME} is Building \n ${CURRENT_BUILD_NUMBER}"

        // Telegram Message Success and Failure
        TEXT_SUCCESS_BUILD = "${JOB_NAME} is Success"
        TEXT_FAILURE_BUILD = "${JOB_NAME} is Failure"
        def DNS = ''
        def STEP = ''
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['UAT', 'STAGE', 'PROD'], description: 'Choose the environment to deploy to')
    }

  
    stages {
        stage('Preparation') {
            steps {
                script {
                    echo "Selected Environment: ${params.ENVIRONMENT}"
                }
            }
        }
        stage('Checkout code') {
            steps {
                script {
                       STEP = "checkout source code"
                    // Define the repository URL
                    def repoUrl = 'https://github.com/error404100230/python-jenkin-terraform-fargate-ecr/'

                    // Get the list of branches using the Git Branch List plugin
                    def branches = getBranchList(repoUrl)

                    // Checkout a specific branch (for example, the first one in the list)
                    if (branches) {
                        def branchToCheckout = branches[0] // Change this to your desired branch
                        echo "Checking out branch: ${branchToCheckout}"

                        checkout scmGit(branches: [[name: branchToCheckout]], userRemoteConfigs: [[url: repoUrl]])
                    } else {
                        error 'No branches found in the repository.'
                    }
                }
            }
        }

        stage('Checking Docker version') {
            steps {
                sh 'docker -v'
            }
        }
        stage('Build image in ECR') {
            steps {
                script {
                    STEP = "Build image in ECR"
                    dir('service') {
                        dockerImage = docker.build "${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }
        stage('Scan image with trivy') {
            steps {
                script {
                    STEP = "Scan image with trivy"
                    sh "trivy image ${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                }
            }
        }
        stage('View the image') {
            steps {
                sh 'docker image ls'
            }
        }
        stage('Logging into AWS ECR') {
            steps {
                script {
                    STEP = "Logging into AWS ECR"
                    sh "aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 767397732282.dkr.ecr.ap-southeast-1.amazonaws.com"
                }
            }
        }
        stage('Pushing into ECR') {
            steps {
                script {
                    STEP = "Pushing into ECR"
                    sh "docker tag ${IMAGE_REPO_NAME}:${IMAGE_TAG} ${REPOSITORY_URI}:$IMAGE_TAG"
                    sh "docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Terraform Init') {
            steps {
                // Navigate to the Terraform directory and initialize Terraform
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('terraform') {
            steps {
                script {
                    STEP = "Deploy terraform to fargate"
                    dir('terraform') {
                        if (params.ENVIRONMENT == 'UAT') {
                            sh "terraform apply -var 'app_image=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}' -auto-approve"
                        } else if (params.ENVIRONMENT == 'STAGE') {
                            sh "terraform apply -var 'app_image=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}' -auto-approve"
                        } else if (params.ENVIRONMENT == 'PROD') {
                            sh "terraform apply -var 'app_image=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}' -auto-approve"
                        } else {
                            sh "terraform apply -var 'app_image=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/${IMAGE_REPO_NAME}:${IMAGE_TAG}' -auto-approve"
                        }
                         // Get Terraform outputs
                        def terraformOutputs = sh(script: 'terraform output -json', returnStdout: true).trim()
                        
                         // Parse JSON manually
                        def json = new groovy.json.JsonSlurper().parseText(terraformOutputs)
                        DNS = json.alb_hostname.value
                       
                    }

                }
            }
        }
    }

    post {
        success {
            script {
                def message = "The application is deployed successfully. You can access it here: ${DNS}"
                sh "curl --location --request POST 'https://api.telegram.org/bot${TOKEN}/sendMessage' --form text=' ${message} \n ${TEXT_SUCCESS_BUILD}' --form chat_id='${CHAT_ID}'"
            }
        }
        failure {
            script {
                sh "curl --location --request POST 'https://api.telegram.org/bot${TOKEN}/sendMessage' --form text='Step -> ${STEP} \n error build -> ${TEXT_FAILURE_BUILD}' --form chat_id='${CHAT_ID}'"
            }
        }
    }
}

// Function to get the list of branches from the repository
def getBranchList(repoUrl) {
    def branchList = []
    try {
        // Use the Git command to fetch the branches
        def output = sh(script: "git ls-remote --heads ${repoUrl}", returnStdout: true)

        // Parse the output to extract branch names
        output.split('\n').each { line ->
            def match = line =~ /refs\/heads\/(.+)/
            if (match) {
                branchList.add(match[0][1])
            }
        }
    } catch (Exception e) {
        error "Failed to retrieve branch list: ${e.message}"
    }
    return branchList
}