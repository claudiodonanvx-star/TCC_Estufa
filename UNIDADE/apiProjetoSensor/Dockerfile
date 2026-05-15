FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY render/app.jar /app/app.jar

EXPOSE 8080
CMD ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
