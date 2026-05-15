FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# Keep Gradle memory low for Render free instances.
ENV GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx512m"

COPY gradlew gradlew
COPY gradle gradle
COPY build.gradle settings.gradle ./
RUN chmod +x gradlew

COPY src src
RUN ./gradlew bootJar --no-daemon -x test --max-workers=1 --stacktrace

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=build /app/build/libs/*.jar /app/app.jar

EXPOSE 8080
CMD ["sh", "-c", "java -Dserver.port=${PORT:-8080} -jar /app/app.jar"]
