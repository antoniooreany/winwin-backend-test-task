# WinWin Backend Test Task

Small two-service Spring Boot solution for the WinWin.travel backend test task.

## Overview

The project includes:

- [`auth-api`](./auth-api) — public API for registration, login, JWT authentication, and protected processing
- [`data-api`](./data-api) — internal text transformation service protected by `X-Internal-Token`
- [PostgreSQL](https://www.postgresql.org/) — persistence layer for users and processing logs

For more detail, see [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), [Verification guide](./docs/verification.md), and [Known issues and trade-offs](./KNOWN-ISSUES.md).

## Main flow

1. A user registers in [`auth-api`](./auth-api).
2. A user logs in and receives a JWT token.
3. The user calls `POST /api/process`.
4. [`auth-api`](./auth-api) calls [`data-api`](./data-api).
5. The transformed result is returned to the client and stored in PostgreSQL.

Current transform example: `hello -> olleh`.

## Getting started

### 1. Clone the repository

```powershell
git clone https://github.com/antoniooreany/winwin-backend-test-task.git
cd winwin-backend-test-task
git status
```

### 2. Prerequisites

- Java 21
- Maven
- PowerShell
- Docker Desktop running

Before startup, create a local `.env` file based on `.env.example`:

```powershell
Copy-Item .env.example .env
```

Fill in the placeholder values with your local settings.

## Quick start

### 1. Build `auth-api`

```powershell
mvn -f auth-api/pom.xml clean package -DskipTests
```

### 2. Build `data-api`

```powershell
mvn -f data-api/pom.xml clean package -DskipTests
```

### 3. Start the stack

```powershell
docker compose up -d --build
```

### 4. Check running containers

```powershell
docker compose ps
```

All three services (`auth-api`, `data-api`, `postgres`) should be running, and PostgreSQL should be healthy.

### 5. Run the recommended local verification flow

```powershell
.\scripts\verify-local.ps1
```

This script performs a smoke test of the main flow and negative scenarios.

### 6. Stop the stack

```powershell
docker compose down
```

### Optional full sequence

```powershell
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
docker compose ps
.\scripts\verify-local.ps1
docker compose down
```

Detailed validation steps are available in the [Verification guide](./docs/verification.md).

## Endpoints

Available after the stack is started with `docker compose up -d --build`:

- `auth-api`: `http://localhost:8080`
- `data-api`: `http://localhost:8081`
- Swagger UI: `http://localhost:8080/swagger-ui.html`

Health response examples:

- `{"status":"ok","service":"auth-api"}`
- `{"status":"ok","service":"data-api"}`

## Documentation map

- [Architecture overview](./docs/architecture.md)
- [Technical decisions](./docs/decisions.md)
- [Verification guide](./docs/verification.md)
- [Known issues and trade-offs](./KNOWN-ISSUES.md)
- [Contributing notes](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Changelog](./CHANGELOG.md)
- [Local verification script](./scripts/verify-local.ps1)