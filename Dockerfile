# syntax=docker/dockerfile:1
FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /w

# —— Spring Insight（安装到镜像内 ~/.m2）——
COPY spring-insight/pom.xml spring-insight/
COPY spring-insight/insight-agent/pom.xml spring-insight/insight-agent/
COPY spring-insight/insight-collector/pom.xml spring-insight/insight-collector/
COPY spring-insight/insight-storage/pom.xml spring-insight/insight-storage/
COPY spring-insight/spring-insight-spring-boot-starter/pom.xml spring-insight/spring-insight-spring-boot-starter/
COPY spring-insight/insight-agent/src spring-insight/insight-agent/src
COPY spring-insight/insight-collector/src spring-insight/insight-collector/src
COPY spring-insight/insight-storage/src spring-insight/insight-storage/src
COPY spring-insight/spring-insight-spring-boot-starter/src spring-insight/spring-insight-spring-boot-starter/src
RUN mvn -q -B -f spring-insight/pom.xml install -DskipTests

# —— 本演示工程 ——
COPY spring-insight-sca-demo/pom.xml spring-insight-sca-demo/
COPY spring-insight-sca-demo/sca-gateway/pom.xml spring-insight-sca-demo/sca-gateway/
COPY spring-insight-sca-demo/sca-order/pom.xml spring-insight-sca-demo/sca-order/
COPY spring-insight-sca-demo/sca-user/pom.xml spring-insight-sca-demo/sca-user/
COPY spring-insight-sca-demo/sca-product/pom.xml spring-insight-sca-demo/sca-product/
COPY spring-insight-sca-demo/sca-loyalty/pom.xml spring-insight-sca-demo/sca-loyalty/
COPY spring-insight-sca-demo/sca-gateway/src spring-insight-sca-demo/sca-gateway/src
COPY spring-insight-sca-demo/sca-order/src spring-insight-sca-demo/sca-order/src
COPY spring-insight-sca-demo/sca-user/src spring-insight-sca-demo/sca-user/src
COPY spring-insight-sca-demo/sca-product/src spring-insight-sca-demo/sca-product/src
COPY spring-insight-sca-demo/sca-loyalty/src spring-insight-sca-demo/sca-loyalty/src
RUN mvn -q -B -f spring-insight-sca-demo/pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS gateway
WORKDIR /app
COPY --from=build /w/spring-insight-sca-demo/sca-gateway/target/sca-gateway-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS order
WORKDIR /app
COPY --from=build /w/spring-insight-sca-demo/sca-order/target/sca-order-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS user
WORKDIR /app
COPY --from=build /w/spring-insight-sca-demo/sca-user/target/sca-user-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8083
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS product
WORKDIR /app
COPY --from=build /w/spring-insight-sca-demo/sca-product/target/sca-product-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8082
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS loyalty
WORKDIR /app
COPY --from=build /w/spring-insight-sca-demo/sca-loyalty/target/sca-loyalty-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8084
ENTRYPOINT ["java","-jar","/app/app.jar"]
