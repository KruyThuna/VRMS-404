
# 1. Build stage using Java 21
FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app

# 2. Copy Gradle wrapper and configuration
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle.kts settings.gradle.kts ./

# 3. Make Gradle wrapper executable
RUN chmod +x gradlew

# 4. Copy application source
COPY src ./src

# 5. Build the Spring Boot JAR
RUN ./gradlew bootJar --no-daemon -x test

# 6. Runtime stage using Java 21 JRE
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# 7. Copy the executable JAR
COPY --from=builder /app/build/libs/*.jar app.jar

# 8. Document the application port
EXPOSE 8080

# 9. Run Spring Boot
ENTRYPOINT ["java", "-jar", "app.jar"]
