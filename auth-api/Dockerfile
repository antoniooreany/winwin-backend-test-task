FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

COPY target/auth-api-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
