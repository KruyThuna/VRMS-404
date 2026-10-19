# ==============================================================================
# Stage 1: Build & Package (Gradle Layer-Cached)
# ==============================================================================
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build

# Install shell utilities for safe cross-platform wrapper execution
RUN apk add --no-cache bash dos2unix

# Step 1: Copy Gradle wrapper and project configuration
COPY gradlew gradlew.bat ./
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./

# Normalize line endings and execution permissions
RUN dos2unix ./gradlew && chmod +x ./gradlew

# Step 2: Pre-fetch dependencies (cached unless dependencies change)
RUN ./gradlew dependencies --no-daemon

# Step 3: Copy application source code
COPY src/ src/

# Step 4: Build executable Spring Boot application (skip test execution during packaging)
RUN ./gradlew bootJar -x test --no-daemon

# Step 5: Extract Spring Boot layered JAR for efficient Docker caching
RUN java -Djarmode=tools -jar build/libs/*.jar extract --layers --destination extracted/

# ==============================================================================
# Stage 2: Hardened, Minimal Production Runtime
# ==============================================================================
FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app

# Security: Create non-root dedicated system user & group (UID/GID 10001)
RUN addgroup -g 10001 -S vrms && \
    adduser -u 10001 -S vrms -G vrms -h /app -s /sbin/nologin

# Production JVM Performance & Container Optimizations
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+ExitOnOutOfMemoryError \
               -Djava.security.egd=file:/dev/./urandom"

# Copy layers in order of change frequency (dependencies rarely change; app code changes often)
COPY --from=builder --chown=vrms:vrms /build/extracted/dependencies/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/application/ ./

USER vrms:vrms

EXPOSE 8080

# Native health check using busybox wget
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD wget -q --spider http://localhost:8080/api/vehicles || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]

