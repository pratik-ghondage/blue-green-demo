pipeline {

    agent any

    environment {

        BLUE_TG = "arn:aws:elasticloadbalancing:ap-south-1:289880681403:targetgroup/blue-tg/9e494a6aabfe0b58"
        GREEN_TG = "arn:aws:elasticloadbalancing:ap-south-1:289880681403:targetgroup/green-tg/14b6d335514e5213"

        LISTENER_ARN = "arn:aws:elasticloadbalancing:ap-south-1:289880681403:listener/app/blue-green-alb/f25808da238ffacf/fffe9a0c2b93e27b"

        ALB_DNS = "blue-green-alb-1371622144.ap-south-1.elb.amazonaws.com"
    }

    stages {

        stage('Clone Repository') {

            steps {
                git branch: 'main', url: 'https://github.com/pratik-ghondage/blue-green-demo.git'
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
			
			echo "ACTIVE_TG = ${ACTIVE_TG}"
			echo "BLUE_TG = ${BLUE_TG}"

                    if (ACTIVE_TG.trim() == BLUE_TG.trim()) {

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
		echo "Switching traffic to ${env.NEXT_TG}"

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
