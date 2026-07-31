FROM maven:3.9.8-eclipse-temurin-21 AS builder
WORKDIR /build

COPY auth-api/pom.xml auth-api/pom.xml
COPY auth-api/src auth-api/src

RUN mvn -f auth-api/pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /build/auth-api/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
