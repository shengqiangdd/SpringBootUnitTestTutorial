# 指定以openjdk：8-jre-alpine为基础镜像，来构建此镜像
FROM openjdk:8-jdk-alpine
# RUN用于容器内部执行命令
RUN mkdir -p /usr/local/project
# 指定容器的目录，容器启动时执行的命令会在该目录下执行
WORKDIR /usr/local/project
# 将项目 jar包复制到/usr/local/project目录下
COPY target/unit-testing-0.0.1-SNAPSHOT.jar ./
# 将接口测试脚本文件复制到/usr/local/project/pipeline目录下
COPY pipeline/*.json ./pipeline/
# 暴露容器端口为9001 Docker 镜像告知Docker宿主机应用监听了9001端口
EXPOSE 9001
# 容器启动时执行的命令
ENTRYPOINT ["java", "-jar", "unit-testing-0.0.1-SNAPSHOT.jar", "--server.port=9001"]
