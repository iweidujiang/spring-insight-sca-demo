ARG MAVEN_IMAGE=maven:3.9.9-eclipse-temurin-21
FROM ${MAVEN_IMAGE} AS builder
WORKDIR /workspace

COPY spring-insight ./spring-insight
COPY spring-insight-sca-demo ./spring-insight-sca-demo

RUN mvn -B -ntp -f spring-insight/pom.xml clean install -DskipTests && \
    mvn -B -ntp -f spring-insight-sca-demo/pom.xml -pl sca-order -am clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /workspace/spring-insight-sca-demo/sca-order/target/sca-order-1.0.0-SNAPSHOT.jar app.jar
ENV SPRING_PROFILES_ACTIVE=docker
EXPOSE 18081
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
