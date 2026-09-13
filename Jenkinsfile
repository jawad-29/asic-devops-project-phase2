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
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Environment') {
            steps {
                echo "Jenkins workspace:"
                echo pwd()

                sh '''
                    set -e

                    echo "================================="
                    echo "Jenkins Environment"
                    echo "================================="

                    echo "User:"
                    whoami

                    echo "Terraform:"
                    terraform version

                    echo "Icarus Verilog:"
                    iverilog -V | head -n 1

                    echo "Git:"
                    git --version

                    echo "Kubernetes:"
                    kubectl version --client

                    echo "================================="
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

        stage('Review Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform show -no-color phase2.tfplan'
                }
            }
        }

        stage('Manual Approval') {
            steps {
                input(
                    message: 'Terraform plan has been reviewed. Approve deployment to Kubernetes?',
                    ok: 'Approve Apply',
                    cancel: 'Abort'
                )
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -input=false phase2.tfplan'
                }
            }
        }

        stage('Post-Deployment Verification') {
            steps {
                sh '''
                    set -e

                    NAMESPACE="semiconductor-devops-phase2"
                    JOB="openroad-eda-job"

                    echo "============================================="
                    echo "POST-DEPLOYMENT VERIFICATION"
                    echo "============================================="

                    echo "1. Checking namespace..."
                    kubectl get namespace "$NAMESPACE"

                    echo "2. Waiting for OpenROAD Job to complete..."
                    kubectl wait \
                        --for=condition=complete \
                        "job/$JOB" \
                        -n "$NAMESPACE" \
                        --timeout=120s

                    echo "3. Checking Job status..."
                    kubectl get job "$JOB" -n "$NAMESPACE"

                    echo "4. Checking OpenROAD pod..."
                    kubectl get pods \
                        -n "$NAMESPACE" \
                        -l app=openroad-eda

                    echo "5. Reading OpenROAD output..."
                    LOGS="$(kubectl logs "job/$JOB" -n "$NAMESPACE")"

                    if [ -n "$LOGS" ]; then
                        echo "OpenROAD output:"
                        echo "$LOGS"
                        echo ""
                        echo "OPENROAD VERIFICATION PASSED"
                    else
                        echo "OPENROAD VERIFICATION FAILED"
                        echo "No output was produced by the OpenROAD Job."
                        exit 1
                    fi

                    echo "============================================="
                    echo "POST-DEPLOYMENT VERIFICATION PASSED"
                    echo "============================================="
                '''
            }
        }
    }

    post {
        always {
            echo '===== Phase 2 pipeline completed ====='
        }

        success {
            echo '===== CI/CD PIPELINE SUCCESS ====='
        }

        failure {
            echo '===== CI/CD PIPELINE FAILED ====='
        }
    }
}
