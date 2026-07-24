# WinWin Backend Test Task

Small two-service Spring Boot solution for the WinWin.travel backend test task.

## Overview

The project includes:
- [`auth-api`](./auth-api) — public API for registration, login, JWT authentication, and protected processing
- [`data-api`](./data-api) — internal text transformation service protected by `X-Internal-Token`
- [`postgres`](https://www.postgresql.org/) — persistence layer for users and processing logs

For runtime structure, see [Architecture overview](./docs/architecture.md). For implementation rationale, see [Technical decisions](./docs/decisions.md). For reviewer-facing validation, see [Verification guide](./docs/verification.md). For accepted trade-offs, see [Known issues and trade-offs](./KNOWN-ISSUES.md).

## Main Flow

1. A user registers in [`auth-api`](./auth-api)
2. A user logs in and receives a JWT token
3. A user calls `POST /api/process`
4. [`auth-api`](./auth-api) calls [`data-api`](./data-api)
5. The transformed result is returned to the client and stored in PostgreSQL

The same flow is described from different angles in [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), and [Verification guide](./docs/verification.md).

Current transform example: `hello -> olleh`.

## Prerequisites

- Java 21
- Maven
- PowerShell
- Docker Desktop running

Before startup, create a local `.env` file based on [`.env.example`](./.env.example). Configuration assumptions are also referenced in [Verification guide](./docs/verification.md), [Contributing notes](./CONTRIBUTING.md), and [Security policy](./SECURITY.md).

## Quick Start

Build both services:

```powershell
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
```

Start the stack:

```powershell
docker compose up -d --build
docker compose ps
```

Run the recommended verification flow:

```powershell
.\scripts\smoke.ps1
```

Stop the stack:

```powershell
docker compose down
```

Detailed verification steps are available in [Verification guide](./docs/verification.md). Local workflow conventions are documented in [Contributing notes](./CONTRIBUTING.md).

## Endpoints

- [`auth-api`](./auth-api): <http://localhost:8080>
- [`data-api`](./data-api): <http://localhost:8081>
- Swagger UI: <http://localhost:8080/swagger-ui.html>

Health response examples:
- `{"status":"ok","service":"auth-api"}`
- `{"status":"ok","service":"data-api"}`

Endpoint behavior, trust boundaries, and internal-service assumptions are described further in [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), and [Known issues and trade-offs](./KNOWN-ISSUES.md).

## Documentation Map

- [Architecture overview](./docs/architecture.md)
- [Technical decisions](./docs/decisions.md)
- [Verification guide](./docs/verification.md)
- [Known issues and trade-offs](./KNOWN-ISSUES.md)
- [Contributing notes](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Changelog](./CHANGELOG.md)
- [Smoke test script](./scripts/smoke.ps1)

## Notes

- [`data-api`](./data-api) is intentionally internal and rejects requests without a valid `X-Internal-Token`; see [Architecture overview](./docs/architecture.md), [Technical decisions](./docs/decisions.md), and [Known issues and trade-offs](./KNOWN-ISSUES.md).
- Processing logs are stored in the `processinglog` table; see [Architecture overview](./docs/architecture.md), [Verification guide](./docs/verification.md), [Technical decisions](./docs/decisions.md), and [Changelog](./CHANGELOG.md).
- The current log model stores `user_email`, `input_text`, `output_text`, and `created_at`; see [Known issues and trade-offs](./KNOWN-ISSUES.md) and [Verification guide](./docs/verification.md).
- Flyway migrations are applied by [`auth-api`](./auth-api) on startup; see [Technical decisions](./docs/decisions.md), [Verification guide](./docs/verification.md), and [Changelog](./CHANGELOG.md).
