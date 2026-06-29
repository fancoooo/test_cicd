// =====================================================================
//  JENKINS CI JOB  -  Khop voi nua tren cua so do CICD.png
//  Push code (GitHub) -> Pull code -> OWASP Dependency Check
//  -> SonarQube quality gate -> Trivy filesystem scan
//  -> Docker build & push -> Trigger CD job
// =====================================================================
pipeline {
    agent any

    // ---- Kich hoat build tu dong khi co push len GitHub ----
    triggers {
        // CACH 1 (khuyen nghi): webhook. Can plugin "GitHub" + bat
        // "GitHub hook trigger for GITScm polling" trong job.
        // GitHub goi /github-webhook/ -> Jenkins build ngay lap tuc.
        githubPush()

        // CACH 2 (du phong): polling. Jenkins tu hoi GitHub moi 2 phut.
        // Dung khi Jenkins khong nhan duoc webhook tu ngoai internet.
        // pollSCM('H/2 * * * *')
    }

    tools {
        // Cau hinh ten nay trong: Manage Jenkins > Tools
        maven 'maven3'
        jdk   'jdk17'
    }

    environment {
        // Doi cho phu hop registry cua ban (Docker Hub / GHCR / Harbor...)
        IMAGE_NAME   = 'vietng1997/cicd-demo'
        IMAGE_TAG    = "${env.BUILD_NUMBER}"           // moi build = 1 tag rieng
        REGISTRY_CRED = 'dockerhub-cred'               // Jenkins credentials ID
        SONAR_ENV    = 'sonarqube'                     // ten SonarQube server trong Jenkins
    }

    stages {

        // ---- Buoc 1: Pull code (GitHub) ----
        stage('Pull Code') {
            steps {
                git branch: 'master',
                    url: 'https://github.com/fancoooo/test_cicd.git'
            }
        }

        // ---- Buoc 2: Build + Unit test ----
        stage('Build & Test') {
            steps {
                sh 'mvn -B clean verify'   // verify chay test + JaCoCo coverage
            }
            post {
                always { junit '**/target/surefire-reports/*.xml' }
            }
        }

        // ---- Buoc 3: OWASP Dependency Check (icon OWASP trong anh) ----
//         stage('OWASP Dependency Check') {
//             steps {
//                 // Quet CVE trong cac thu vien. Build se fail neu CVSS >= 7 (cau hinh trong pom.xml)
//                 sh 'mvn org.owasp:dependency-check-maven:check'
//             }
//             post {
//                 always {
//                     dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
//                     archiveArtifacts artifacts: '**/dependency-check-report.html', allowEmptyArchive: true
//                 }
//             }
//         }

        // ---- Buoc 4: SonarQube - Code & quality gate analysis ----
//         stage('SonarQube Analysis') {
//             steps {
//                 withSonarQubeEnv("${SONAR_ENV}") {
//                     sh '''
//                         mvn sonar:sonar \
//                           -Dsonar.projectKey=cicd-demo \
//                           -Dsonar.java.binaries=target/classes
//                     '''
//                 }
//             }
//         }

        // ---- Buoc 5: Cho ket qua Quality Gate tu SonarQube ----
//         stage('Quality Gate') {
//             steps {
//                 timeout(time: 5, unit: 'MINUTES') {
//                     waitForQualityGate abortPipeline: true
//                 }
//             }
//         }

        // ---- Buoc 6: Trivy filesystem scan (icon Trivy trong anh) ----
//         stage('Trivy FS Scan') {
//             steps {
//                 // Quet source/dependency tren filesystem truoc khi build image
//                 sh 'trivy fs --severity HIGH,CRITICAL --exit-code 0 --format table -o trivy-fs-report.txt .'
//             }
//             post {
//                 always { archiveArtifacts artifacts: 'trivy-fs-report.txt', allowEmptyArchive: true }
//             }
//         }

        // ---- Buoc 7: Docker build & push (icon Docker trong anh) ----
        stage('Docker Build & Push') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', "${REGISTRY_CRED}") {
                        def img = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
                        // Quet chinh image vua build (Trivy image scan)
                        //sh "trivy image --severity HIGH,CRITICAL --exit-code 0 -o trivy-image-report.txt ${IMAGE_NAME}:${IMAGE_TAG}"
                        img.push()
                        img.push('latest')
                    }
                }
            }
//             post {
//                 always { archiveArtifacts artifacts: 'trivy-image-report.txt', allowEmptyArchive: true }
//             }
        }

        // ---- Buoc 8: Trigger CD Job (mui ten "Trigger Jenkins CD Job") ----
        stage('Trigger CD') {
            steps {
                build job: 'cicd-demo-CD',
                      parameters: [string(name: 'IMAGE_TAG', value: "${IMAGE_TAG}")],
                      wait: false
            }
        }
    }

//     post {
//         // ---- Notify on email (icon Gmail trong anh) ----
//         success {
//             emailext subject: "CI OK: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
//                      body: "CI thanh cong. Image: ${IMAGE_NAME}:${IMAGE_TAG}",
//                      to: 'vietxuyen97@gmail.com'
//         }
//         failure {
//             emailext subject: "CI FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
//                      body: "CI that bai. Xem: ${env.BUILD_URL}",
//                      to: 'vietxuyen97@gmail.com'
//         }
//     }
}
