pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        skipDefaultCheckout(true)
    }

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_INPUT = 'false'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                sh '''
                    echo "===== Jenkins Environment ====="
                    whoami
                    echo "Terraform:"
                    terraform version
                    echo "Icarus Verilog:"
                    iverilog -V | head -n 1
                    echo "Git:"
                    git --version
                    echo "Kubernetes:"
                    kubectl version --client
                '''
            }
        }

        stage('RTL Simulation') {
            steps {
                sh './scripts/simulate.sh'
            }
        }

        stage('Design Quality Checks') {
            steps {
                sh './scripts/design_quality_check.sh'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -input=false -out=phase2.tfplan'
                }
            }
        }
    }

    post {
        always {
            echo '===== Pipeline completed up to Terraform Plan ====='
        }
    }
}
