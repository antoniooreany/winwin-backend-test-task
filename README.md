# WinWin Backend Test Task

> For reviewers
>
> This repository contains a small two-service Spring Boot solution for the WinWin.travel backend test task. To review it quickly, you can follow the "Quick start" section and the "Reviewer checklist" at the end of this document.

Small two-service Spring Boot solution for the WinWin.travel backend test task.

## Release status

Current stable release: **v0.3.0**  
Previous stable releases: `v0.2.0`, `v0.1.0`  
Earlier pre-release: `v0.1.0-rc1`

Release `v0.3.0` finalizes the reviewer-facing documentation, aligns the local verification flow with the current project structure, and documents the current Docker-based verification path, Flyway-backed startup, and processing log behavior.

For published release notes, see the [Releases](https://github.com/antoniooreany/winwin-backend-test-task/releases) page. For repository-level version history, see [CHANGELOG.md](./CHANGELOG.md).

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

This script performs the shortest reproducible verification flow for the current stable release and covers the main runtime path together with key negative scenarios.

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


## Reviewer checklist

You can use this short checklist to verify the project locally.

1. Clone the repository:
   ```bash
   git clone https://github.com/antoniooreany/winwin-backend-test-task.git
   cd winwin-backend-test-task
   ```

2. Prepare environment:
   ```powershell
   Copy-Item .env.example .env
   # Update .env with local values if needed
   ```

3. Build both services (tests skipped for faster review):
   ```bash
   mvn -f auth-api/pom.xml clean package -DskipTests
   mvn -f data-api/pom.xml clean package -DskipTests
   ```

4. Start the stack:
   ```bash
   docker compose up -d --build
   docker compose ps
   ```
   Expected: `auth-api`, `data-api`, and `postgres` containers are `running` / `healthy`.

5. Run the verification script:
   ```powershell
   .\scripts\verify-local.ps1
   ```
   Expected: script completes without errors and prints a summary of the main registration → login → processing flow plus key negative scenarios.

6. Check health endpoints (optional):
   ```bash
   curl http://localhost:8080/actuator/health
   curl http://localhost:8081/actuator/health
   ```
   Expected JSON responses similar to:
   ```json
   {"status":"ok","service":"auth-api"}
   {"status":"ok","service":"data-api"}
   ```

7. Stop the stack:
   ```bash
   docker compose down
   ```
## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
