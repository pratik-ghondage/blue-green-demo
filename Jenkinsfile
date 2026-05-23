pipeline {

    agent any

    environment {

        BLUE_TG = "BLUE_TARGET_GROUP_ARN"
        GREEN_TG = "GREEN_TARGET_GROUP_ARN"

        LISTENER_ARN = "LISTENER_ARN"

        ALB_DNS = "YOUR_ALB_DNS"
    }

    stages {

        stage('Clone Repository') {

            steps {
                git 'https://github.com/YOUR_USERNAME/blue-green-demo.git'
            }
        }

        stage('Detect Active Environment') {

            steps {

                script {

                    ACTIVE_TG = sh(

                        script: """
                        aws elbv2 describe-listeners \
                        --listener-arn $LISTENER_ARN \
                        --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
                        --output text
                        """,

                        returnStdout: true

                    ).trim()

                    if (ACTIVE_TG == BLUE_TG) {

                        env.INACTIVE = "green"
                        env.NEXT_TG = GREEN_TG

                    } else {

                        env.INACTIVE = "blue"
                        env.NEXT_TG = BLUE_TG
                    }

                    echo "Deploying to ${env.INACTIVE}"
                }
            }
        }

        stage('Deploy') {

            steps {

                sh "./deploy.sh ${env.INACTIVE}"
            }
        }

        stage('Health Check') {

            steps {

                script {

                    sleep 20

                    def status = sh(

                        script: """
                        curl -s http://$ALB_DNS | grep Version
                        """,

                        returnStatus: true
                    )

                    if (status != 0) {

                        error("Health Check Failed")
                    }
                }
            }
        }

        stage('Switch Traffic') {

            steps {

                sh """
                aws elbv2 modify-listener \
                --listener-arn $LISTENER_ARN \
                --default-actions Type=forward,TargetGroupArn=$NEXT_TG
                """
            }
        }
    }

    post {

        failure {

            echo "Rollback Started"

            sh """
            aws elbv2 modify-listener \
            --listener-arn $LISTENER_ARN \
            --default-actions Type=forward,TargetGroupArn=$ACTIVE_TG
            """
        }
    }
}
