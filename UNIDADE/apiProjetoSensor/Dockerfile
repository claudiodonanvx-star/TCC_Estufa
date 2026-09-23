FROM eclipse-temurin:21-jdk-jammy AS builder
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew && ./gradlew clean build -x test

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
COPY --from=builder /workspace/build/libs/apiProjeto-0.0.1-SNAPSHOT.jar /app/app.jar

EXPOSE 8080
CMD ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
