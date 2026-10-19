# 🚀 The Ultimate Guide: Spring Boot, Docker & Production Hosting

A comprehensive, practical manual designed for developers learning how to containerize Spring Boot applications, orchestrate multi-container stacks with MySQL, and deploy them to production cloud environments.

---

## 📑 Table of Contents
1. [Core Fundamentals: Spring Boot Meets Docker](#1-core-fundamentals-spring-boot-meets-docker)
2. [Deep Dive into the Production Dockerfile](#2-deep-dive-into-the-production-dockerfile)
3. [Multi-Container Orchestration with Docker Compose](#3-multi-container-orchestration-with-docker-compose)
4. [Connecting Database & Overriding Properties](#4-connecting-database--overriding-properties)
5. [Hosting Options: Where & How to Deploy](#5-hosting-options-where--how-to-deploy)
6. [Step-by-Step Production Deployment on a VPS ($5/mo)](#6-step-by-step-production-deployment-on-a-vps)
7. [Adding Free HTTPS / SSL with Nginx Reverse Proxy](#7-adding-free-https--ssl-with-nginx-reverse-proxy)
8. [Automated CI/CD Deployment with GitHub Actions](#8-automated-cicd-deployment-with-github-actions)
9. [Production Security & Maintenance Checklist](#9-production-security--maintenance-checklist)

---

## 1. Core Fundamentals: Spring Boot Meets Docker

### Why Docker for Spring Boot?
In traditional deployment, running a Spring Boot app on a new server requires:
- Installing the exact matching Java Development Kit (JDK 21).
- Installing and configuring MySQL, matching character sets, and creating users.
- Managing background daemons (`systemd`, `nohup`).
- Debugging environment-specific issues (*"It worked on Windows, why does it crash on Linux?"*).

With **Docker**:
- The **Operating System**, **Java Runtime (JRE 21)**, **Application Code**, and **System Dependencies** are frozen into a single portable artifact called an **Image**.
- An Image runs identically on Windows, macOS, Linux, AWS, or DigitalOcean with zero configuration differences.

```
+-------------------------------------------------------------+
|                     Running Server                          |
|                                                             |
|  +-----------------------+     +-------------------------+  |
|  |     vrms-app          |     |       vrms-mysql        |  |
|  | (Spring Boot 4 / JRE) |     |       (MySQL 8.0)       |  |
|  |      Port 8080        |     |        Port 3306        |  |
|  +-----------+-----------+     +------------+------------+  |
|              |                              |               |
|              +-------- Docker Network ------+               |
+-------------------------------------------------------------+
```

---

## 2. Deep Dive into the Production Dockerfile

A basic beginner Dockerfile simply does `COPY build/libs/app.jar app.jar` and `ENTRYPOINT ["java", "-jar", "app.jar"]`. 
While this works, an **Enterprise-Grade Dockerfile** leverages **Multi-Stage Builds** and **Spring Boot Layering**.

### Understanding Spring Boot Layers
A Spring Boot JAR consists of:
1. **Dependencies (`dependencies/`)**: Third-party libraries (`spring-core`, `mysql-connector`, `lombok`). Size: **~50 MB**. Changes: **Rarely**.
2. **Spring Boot Loader (`spring-boot-loader/`)**: Internal launcher classes. Size: **~500 KB**. Changes: **Rarely**.
3. **Application (`application/`)**: Your compiled `.class` files and configs. Size: **~200 KB**. Changes: **Every single commit**.

By splitting the JAR into layers, Docker caches the heavy 50 MB dependencies layer. When you push a code change, **Docker only rebuilds and transfers the 200 KB application layer**!

### The Complete Production Dockerfile Breakdown

```dockerfile
# ==============================================================================
# Stage 1: Build & Package (Using JDK 21 on Alpine Linux)
# ==============================================================================
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build

# 1. Install tools to fix Windows CRLF line endings
RUN apk add --no-cache bash dos2unix

# 2. Copy wrapper and build configs FIRST to cache dependencies
COPY gradlew gradlew.bat ./
COPY gradle/ gradle/
COPY build.gradle.kts settings.gradle.kts ./

# Normalize Windows line endings and ensure execution permission
RUN dos2unix ./gradlew && chmod +x ./gradlew

# 3. Pre-fetch dependencies (Cached unless build.gradle.kts changes)
RUN ./gradlew dependencies --no-daemon

# 4. Copy source code and build executable JAR
COPY src/ src/
RUN ./gradlew bootJar -x test --no-daemon

# 5. Extract JAR into Spring Boot layers
RUN java -Djarmode=tools -jar build/libs/*.jar extract --layers --destination extracted/

# ==============================================================================
# Stage 2: Minimal, Hardened Runtime (Using lightweight JRE 21)
# ==============================================================================
FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app

# Security: Dedicated unprivileged system user (Never run as root!)
RUN addgroup -g 10001 -S vrms && \
    adduser -u 10001 -S vrms -G vrms -h /app -s /sbin/nologin

# Container-aware JVM memory optimization flags
ENV JAVA_OPTS="-XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:InitialRAMPercentage=50.0 \
               -XX:+ExitOnOutOfMemoryError \
               -Djava.security.egd=file:/dev/./urandom"

# Copy layers in order of change frequency
COPY --from=builder --chown=vrms:vrms /build/extracted/dependencies/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/spring-boot-loader/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/snapshot-dependencies/ ./
COPY --from=builder --chown=vrms:vrms /build/extracted/application/ ./

USER vrms:vrms

EXPOSE 8080

# Native health check
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD wget -q --spider http://localhost:8080/api/vehicles || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
```

---

## 3. Multi-Container Orchestration with Docker Compose

When your backend depends on MySQL, Docker Compose coordinates both containers on an internal virtual network.

### The Complete `docker-compose.yml`

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: vrms-mysql
    restart: unless-stopped
    stop_grace_period: 30s
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-12345}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-vrms}
    ports:
      # Exposes 3307 on host to avoid port 3306 conflicts with local MySQL
      - "${MYSQL_HOST_PORT:-3307}:3306"
    volumes:
      # Persistent storage: data survives container restarts and upgrades
      - mysql_data:/var/lib/mysql
      # Auto-initialization: runs on clean first start
      - ./vrms_database.sql:/docker-entrypoint-initdb.d/01_vrms_database.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -u root -p${MYSQL_ROOT_PASSWORD:-12345} || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 10
      start_period: 15s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - vrms-network

  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: vrms-app
    restart: unless-stopped
    stop_grace_period: 20s
    depends_on:
      mysql:
        condition: service_healthy   # <-- Waits until MySQL answers ping!
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/${MYSQL_DATABASE:-vrms}?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: ${MYSQL_ROOT_PASSWORD:-12345}
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    ports:
      - "${APP_PORT:-8080}:8080"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - vrms-network

volumes:
  mysql_data:
    name: vrms_mysql_data

networks:
  vrms-network:
    name: vrms_network
    driver: bridge
```

---

## 4. Connecting Database & Overriding Properties

### How Spring Boot Reads Environment Variables
Spring Boot has built-in relaxed binding. Any setting in `application.properties` can be overridden by environment variables:

| `application.properties` | Environment Variable in Docker |
| :--- | :--- |
| `spring.datasource.url` | `SPRING_DATASOURCE_URL` |
| `spring.datasource.username` | `SPRING_DATASOURCE_USERNAME` |
| `spring.datasource.password` | `SPRING_DATASOURCE_PASSWORD` |
| `server.port` | `SERVER_PORT` |
| `spring.jpa.hibernate.ddl-auto` | `SPRING_JPA_HIBERNATE_DDL_AUTO` |

> [!TIP]
> **Internal DNS in Docker:** Notice that inside Docker, the host is `jdbc:mysql://mysql:3306/vrms`. Docker's built-in DNS resolves the name `mysql` to the internal IP address of the `vrms-mysql` container!

---

## 5. Hosting Options: Where & How to Deploy

| Hosting Type | Popular Providers | Monthly Cost | Ease of Use | Best For |
| :--- | :--- | :--- | :--- | :--- |
| **Virtual Private Server (VPS)** | DigitalOcean, Hetzner, Linode, AWS EC2 | $4 - $12 / mo | Intermediate | **Recommended.** Full control, Docker Compose runs directly, best performance per dollar. |
| **Platform as a Service (PaaS)** | Render, Railway, Fly.io | $7 - $25 / mo | Very Easy | Push-to-deploy from GitHub. Good if you don't want to manage Linux servers. |
| **Serverless Containers (CaaS)** | AWS ECS, Google Cloud Run | Pay per request | Advanced | Enterprise systems with auto-scaling to thousands of requests. |
| **Free Cloud Tier** | Oracle Cloud Free Tier | **$0 / month** (Lifetime) | Intermediate | 4 OCPUs, 24 GB RAM Ampere A1 ARM compute instance (free forever). |

---

## 6. Step-by-Step Production Deployment on a VPS

The industry-standard production setup is renting an **Ubuntu 24.04 LTS VPS** (e.g., DigitalOcean Droplet or Hetzner Cloud for ~$5/month).

### Step 1: Initial Server Setup
SSH into your VPS:
```bash
ssh root@YOUR_SERVER_IP
```
Update server packages:
```bash
sudo apt update && sudo apt upgrade -y
```

### Step 2: Install Docker & Docker Compose
```bash
# Install Docker via official script
curl -fsSL https://get.docker.com | sh

# Verify installation
docker --version
docker compose version
```

### Step 3: Configure Firewall (UFW)
Only open the necessary ports to the public internet:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Web / Certbot)
sudo ufw allow 443/tcp   # HTTPS (SSL)
sudo ufw enable
```
> [!IMPORTANT]
> **Never open port 3306 (MySQL) to the internet!** In your `docker-compose.yml` on production, remove the `ports:` block from the `mysql` service so it is only accessible internally by Spring Boot.

### Step 4: Clone Your Project & Launch
```bash
# Clone your repo
git clone https://github.com/your-username/PM-404.git /opt/vrms
cd /opt/vrms/vrms

# Create production .env file
nano .env
# Set strong passwords:
# MYSQL_ROOT_PASSWORD=SuperSecretProdPassword_987!
# MYSQL_DATABASE=vrms

# Build and start the stack in detached background mode
docker compose up -d --build
```

---

## 7. Adding Free HTTPS / SSL with Nginx Reverse Proxy

Do not expose Spring Boot directly on port 8080 to the public. Instead, place **Nginx** in front to handle SSL encryption (HTTPS) on port 443 and forward traffic to Spring Boot on port 8080.

### Step 1: Install Nginx & Certbot
```bash
sudo apt install nginx certbot python3-certbot-nginx -y
```

### Step 2: Configure Nginx Virtual Host
Create `/etc/nginx/sites-available/vrms.conf`:
```nginx
server {
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (if needed)
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Enable the configuration:
```bash
sudo ln -s /etc/nginx/sites-available/vrms.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 3: Issue Free SSL Certificate (Let's Encrypt)
```bash
sudo certbot --nginx -d api.yourdomain.com
```
Certbot will automatically install the certificate, redirect HTTP to HTTPS, and configure automatic 90-day renewals.

---

## 8. Automated CI/CD Deployment with GitHub Actions

Whenever you push code to `main`, GitHub Actions can automatically test, build your Docker image, and deploy it to your server with zero downtime.

Create `.github/workflows/deploy.yml`:

```yaml
name: Production CI/CD Pipeline

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Deploy via SSH to VPS
        uses: appleboy/ssh-action@v1.0.3
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/vrms/vrms
            git pull origin main
            docker compose up -d --build
            docker image prune -f
```

---

## 9. Production Security & Maintenance Checklist

### 1. Database Automated Backups
Set up an automatic daily cron backup for MySQL:
```bash
# Open crontab
crontab -e

# Run backup every night at 2:00 AM
0 2 * * * docker exec vrms-mysql mysqldump -u root -p'YOUR_PASSWORD' vrms > /opt/backups/vrms_$(date +\%F).sql
```

### 2. Monitoring Container Logs
```bash
# Follow live logs for backend
docker compose logs -f app

# Follow live logs for database
docker compose logs -f mysql

# View resource usage (CPU & Memory)
docker stats
```

### 3. Cleaning Unused Docker Resources
Periodically clean up dangling images to free disk space:
```bash
docker system prune -af --volumes
```

---

## 🏁 Summary Command Cheat Sheet

| Task | Command |
| :--- | :--- |
| **Start everything in background** | `docker compose up -d` |
| **Rebuild code after changes** | `docker compose up -d --build` |
| **View logs of backend** | `docker compose logs -f app` |
| **Check container health** | `docker compose ps` |
| **Stop all containers** | `docker compose down` |
| **Reset DB volume cleanly** | `docker compose down -v && docker compose up -d` |
| **Enter container shell** | `docker exec -it vrms-app sh` |
| **Inspect MySQL directly** | `docker exec -it vrms-mysql mysql -u root -p12345 vrms` |
