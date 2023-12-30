pipeline {
    environment {
        IMAGE_NAME = 'unit-testing'                // Docker 镜像名称，一般和项目名称相同
        CONTAINER_NAME = 'unit-testing'
        DOCKER_ID = 'sqdd'
        DOCKER_PASSWORD = 'csq010216'
        POSTMAN_COLLECTION = '/home/local/project/pipeline/postman_collection.json'
        //POSTMAN_ENVIRONMENT = "/home/local/project/pipeline/postman_environment.json"
    }

    agent any
    stages {
        // 从代码仓库拉取代码和用于流水线任务的 Jenkinsfile 和 Dockerfile
        stage('Pull code') {
            agent any
            steps {
                echo '1. Fetch code from Git'
                checkout scm
            }
        }

        // 执行单元测试及代码覆盖率分析，单元覆盖率要求为 70%，如果低于 70% 则构建失败
        stage('Unit Test') {
            agent {
                docker {
                    image 'maven:3-alpine' // 在流水线中启动 Maven
                    args '-v /root/.m2:/root/.m2'
                }
            }
            steps {
                echo '2. Run unit test'
                sh 'mvn -B org.jacoco:jacoco-maven-plugin:prepare-agent test'
                jacoco(changeBuildStatus: true, maximumLineCoverage: "70")
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        // 使用 SonarQube 进行代码分析
        stage('Code analysis with SonarQube') {
            steps {
                echo '3. Code analysis with SonarQube'
                withSonarQubeEnv('sonar') {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=Myproject -Dsonar.host.url=http://localhost:9000 -Dsonar.login=dc255142fef90d37fe732f411cd5ae5702f2e3ff'
                }
            }
        }

        // 构建代码
        stage('Build') {
            agent {
                docker {
                    image 'maven:3-alpine'
                    args '-v /root/.m2:/root/.m2'
                }
            }
            steps {
                echo '4. Make build package'
                sh 'mvn -B -DskipTests clean package'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        // 创建 Docker 镜像并推送到 Docker 服务器
        stage('Build Docker Image') {
            agent any
            steps {
                echo '5. Build Docker Image and then push to Docker server'
                sh '''
                    docker build -f Dockerfile -t ${DOCKER_ID}/${IMAGE_NAME}:latest .
                    docker login -u ${DOCKER_ID} -p ${DOCKER_PASSWORD}
                    docker push ${DOCKER_ID}/${IMAGE_NAME}:latest
                '''
            }
        }

        // 在测试服务器的节点拉取应用的镜像，创建并启动容器
        stage('Deploy') {
            agent { label 'test001' }
            steps {
                echo '6. Pull Docker image and run container in test environment'
                sh '''
                    docker login -u ${DOCKER_ID} -p ${DOCKER_PASSWORD}
                    docker pull ${DOCKER_ID}/${IMAGE_NAME}:latest
                    docker run --name ${IMAGE_NAME} -p 9001:9001 -d ${DOCKER_ID}/${IMAGE_NAME}:latest
                '''
            }
        }

        // 在测试服务器节点启动 Newman 容器并执行 BVT 测试
        stage('Build Verification Test') {
            agent { label 'test001' }
            steps {
                echo '7. Run Build Verification Test in test environment'
                sh '''
                    docker pull postman/newman
                    docker run --rm --name newman --volumes-from ${CONTAINER_NAME} -d postman/newman run ${POSTMAN_COLLECTION} -e ${POSTMAN_ENVIRONMENT} -r cli
                '''
            }
        }
    }
}