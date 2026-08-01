# WinWin Backend Test Task

> For reviewers
>
> This repository contains a small two-service Spring Boot solution for the WinWin.travel backend test task. The fastest way to review it is to follow the **Quick start** section and then run `.\scripts\verify-local.ps1`.

Small two-service Spring Boot solution for the WinWin.travel backend test task.

## Release status

Current stable release: v0.3.4

Full release history: see [GitHub Releases](https://github.com/antoniooreany/winwin-backend-test-task/releases).

For repository-level version history, see [CHANGELOG.md](./CHANGELOG.md).

## Overview

The project includes:

- [`auth-api`](./auth-api) — public API for registration, login, JWT authentication, and protected processing
- [`data-api`](./data-api) — internal text transformation service protected by `X-Internal-Token`
- [PostgreSQL](https://www.postgresql.org/) — persistence layer for users and processing logs

Main flow:

1. A user registers in [`auth-api`](./auth-api).
2. A user logs in and receives a JWT token.
3. The user calls `POST /api/process`.
4. [`auth-api`](./auth-api) calls [`data-api`](./data-api).
5. The transformed result is returned to the client and stored in PostgreSQL.

Current transform example: `hello -> olleh`.

For more detail, see [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), [Verification guide](./docs/verification.md), and [Known issues and trade-offs](./KNOWN-ISSUES.md).

## Quick start

### Prerequisites

- Java 21
- PowerShell
- Docker Desktop running
- Maven (optional, only for manual local builds outside Docker)

### Setup and run

Clone the repository first:

```powershell
git clone https://github.com/antoniooreany/winwin-backend-test-task.git
cd winwin-backend-test-task
```

Then create a local `.env` file based on `.env.example`:

```powershell
Copy-Item .env.example .env
```

The `.env` file contains local PostgreSQL settings, datasource settings, the internal service token, and the JWT signing secret used by Docker Compose.

You can keep the example values for a standard local run, or replace them with your own local values before startup.

```powershell
docker compose up -d --build
docker compose ps
```

All three services (`auth-api`, `data-api`, `postgres`) should be running, and PostgreSQL should be healthy before the verification script is executed.
Docker images are built with multi-stage Dockerfiles, so a separate local `mvn package` step is not required before `docker compose up -d --build`.

Start a local verification:

```powershell
.\scripts\verify-local.ps1
```

Stop the stack (if necessary) with:

```powershell
docker compose down
```

Detailed validation steps are available in the [Verification guide](./docs/verification.md). For implementation context, see [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), and [Known issues and trade-offs](./KNOWN-ISSUES.md).

## Endpoints

Available after the stack is started with `docker compose up -d --build`:

- `auth-api`: `http://localhost:8080`
- `data-api`: `http://localhost:8081`
- Swagger UI: `http://localhost:8080/swagger-ui.html`

Health response examples:

- `{"status":"ok","service":"auth-api"}`
- `{"status":"ok","service":"data-api"}`

For a step-by-step verification path, see [Verification guide](./docs/verification.md).

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

- Clone the repository.
- Create `.env` from `.env.example`.
- Optionally replace the example local secrets and connection settings.
- Start the stack with `docker compose up -d --build`.
- Confirm that `auth-api`, `data-api`, and `postgres` are running.
- Run `.\scripts\verify-local.ps1`.
- Optionally check the health endpoints and Swagger UI.
- Stop the stack cleanly with `docker compose down`.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.
