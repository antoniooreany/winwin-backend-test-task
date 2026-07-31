FROM maven:3.9.8-eclipse-temurin-21 AS builder
WORKDIR /build

COPY data-api/pom.xml data-api/pom.xml
COPY data-api/src data-api/src

RUN mvn -f data-api/pom.xml clean package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

COPY --from=builder /build/data-api/target/*.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
