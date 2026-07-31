FROM maven:3.9.8-eclipse-temurin-21 AS builder
WORKDIR /build

COPY pom.xml pom.xml
COPY src src

RUN mvn clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
