# 仅打包运行：不在镜像内执行 Maven。请先在本目录执行 mvnw clean package -DskipTests
#（compose-up 脚本会在缺少 jar 时自动执行），再打镜像只会 COPY 各模块 target 下 fat jar，秒级完成。
#
#   docker build -f Dockerfile --target gateway .

FROM eclipse-temurin:21-jre-alpine AS gateway
WORKDIR /app
COPY sca-gateway/target/sca-gateway-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS order
WORKDIR /app
COPY sca-order/target/sca-order-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS user
WORKDIR /app
COPY sca-user/target/sca-user-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8083
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS product
WORKDIR /app
COPY sca-product/target/sca-product-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8082
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS loyalty
WORKDIR /app
COPY sca-loyalty/target/sca-loyalty-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8084
ENTRYPOINT ["java","-jar","/app/app.jar"]
