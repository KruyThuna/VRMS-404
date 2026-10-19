# 🚗 VRMS-404 (Vehicle Rental Management System)

A full-stack, enterprise-grade Vehicle Rental Management System with a modern Flutter client & admin workspace, Spring Boot REST backend, and containerized MySQL database.

---

## 🏗️ Project Architecture

```
PM-404 / VRMS-404/
├── vehicle_rental/           # Flutter Client App & Admin Management Hub
│   ├── lib/                  # Dart source code (screens, controllers, models)
│   └── test/                 # 42 unit and integration tests (all passing)
│
├── vrms/                     # Spring Boot 4 REST Backend (Java 21)
│   ├── src/main/java/        # REST Controllers, JPA Entities, Services
│   ├── Dockerfile            # Multi-stage production container image
│   └── build.gradle.kts      # Gradle configuration
│
├── docker-compose.yml        # Orchestrates Spring Boot & MySQL containers
├── vrms_database.sql         # Production database schema & seed data
├── SPRING_DOCKER_HOSTING_GUIDE.md # Production hosting & deployment manual
└── .env.example              # Environment variables template
```

---

## ⚡ Quick Start

### 1. Run via Docker Compose (Recommended)
```bash
# Clone the repository
git clone https://github.com/KruyThuna/VRMS-404.git
cd VRMS-404

# Start both MySQL and Spring Boot in detached mode
docker compose up -d

# Check service health
docker compose ps
```
- **Backend API**: http://localhost:8080/api/vehicles
- **Interactive Swagger Docs**: http://localhost:8080/swagger-ui.html
- **MySQL Database**: `localhost:3307` (user: `root`, pass: `12345`)

### 2. Run Flutter Frontend
```bash
cd vehicle_rental
flutter pub get
flutter run -d chrome    # Or target Windows / Android / iOS
```

---

## 🧪 Testing
```bash
cd vehicle_rental
flutter test
```
All 42 automated tests covering car rentals, overdue unpaid returns, and customer settlements are verified and passing.
