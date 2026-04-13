# syntax=docker/dockerfile:1.4
#
# 本地联调用途：在宿主已执行 spring-insight 的 mvn install 的前提下，通过 Compose 的
# additional_context「local_m2」把本机 ~/.m2/repository 中的 io/github/iweidujiang 拷入镜像，
# 再仅编译本 demo（不在镜像内编译 Spring Insight 源码）。
#
# 构建示例（需已设置 LOCAL_M2_REPOSITORY，见 compose-up.ps1 / compose-up.sh）:
#   docker build -f Dockerfile --target gateway .

FROM maven:3.9.9-eclipse-temurin-21-alpine AS build
WORKDIR /w

COPY --from=local_m2 io/github/iweidujiang /root/.m2/repository/io/github/iweidujiang

COPY pom.xml .
COPY sca-gateway/pom.xml sca-gateway/
COPY sca-order/pom.xml sca-order/
COPY sca-user/pom.xml sca-user/
COPY sca-product/pom.xml sca-product/
COPY sca-loyalty/pom.xml sca-loyalty/

RUN --mount=type=cache,target=/root/.m2/repository \
    mvn -B -q -ntp -f pom.xml dependency:go-offline -DskipTests

COPY sca-gateway/src sca-gateway/src
COPY sca-order/src sca-order/src
COPY sca-user/src sca-user/src
COPY sca-product/src sca-product/src
COPY sca-loyalty/src sca-loyalty/src

RUN --mount=type=cache,target=/root/.m2/repository \
    mvn -B -q -ntp -f pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine AS gateway
WORKDIR /app
COPY --from=build /w/sca-gateway/target/sca-gateway-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS order
WORKDIR /app
COPY --from=build /w/sca-order/target/sca-order-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8081
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS user
WORKDIR /app
COPY --from=build /w/sca-user/target/sca-user-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8083
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS product
WORKDIR /app
COPY --from=build /w/sca-product/target/sca-product-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8082
ENTRYPOINT ["java","-jar","/app/app.jar"]

FROM eclipse-temurin:21-jre-alpine AS loyalty
WORKDIR /app
COPY --from=build /w/sca-loyalty/target/sca-loyalty-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 8084
ENTRYPOINT ["java","-jar","/app/app.jar"]
