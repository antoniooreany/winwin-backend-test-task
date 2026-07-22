# WinWin Backend Test Task

Backend take-home assignment implementation for WinWin.travel.

## Project Context

This repository contains my solution for a backend engineering test task.

The project includes:
- [`auth-api`](./auth-api) — registration, login, JWT-based authentication, protected processing endpoint, and PostgreSQL persistence.
- [`data-api`](./data-api) — internal text transformation service protected by a shared internal token.
- [`postgres`](./docker-compose.yml) — persistence layer for users and processing logs through Docker Compose.
- [`docker-compose.yml`](./docker-compose.yml) — local orchestration for both services and PostgreSQL.

The goal is to provide a minimal but clear implementation of authentication, internal service-to-service communication, deterministic database startup, and Docker-based local execution.

For verification details, see [docs/verification.md](./docs/verification.md). For current limitations, see [KNOWN-ISSUES.md](./KNOWN-ISSUES.md). For local workflow conventions, see [CONTRIBUTING.md](./CONTRIBUTING.md). For runtime architecture, see [docs/architecture.md](./docs/architecture.md). For implementation trade-offs, see [docs/decisions.md](./docs/decisions.md).

## Overview

The project contains two Spring Boot services running locally with Docker Compose and PostgreSQL:

- [`auth-api`](./auth-api) — handles registration, login, JWT-based authentication, and the protected client-facing processing endpoint.
- [`data-api`](./data-api) — internal service used by [`auth-api`](./auth-api) for text transformation.
- [`postgres`](./docker-compose.yml) — persistence layer for users and processing logs.

## Architecture

### auth-api

Responsibilities:
- register users;
- authenticate users and issue JWT tokens;
- expose a protected `POST /api/process` endpoint;
- call [`data-api`](./data-api) through an internal request;
- store a processing log entry in PostgreSQL.

Implementation and request-flow details are described in [docs/architecture.md](./docs/architecture.md) and [docs/decisions.md](./docs/decisions.md).

### data-api

Responsibilities:
- expose the transformation endpoint used by [`auth-api`](./auth-api);
- validate the shared internal token header;
- process incoming text and return the transformed value.

Direct access expectations and negative checks are also documented in [docs/verification.md](./docs/verification.md) and [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

### postgres

Stores:
- `users`
- `processing_log`

Database and schema notes are described in [docs/verification.md](./docs/verification.md), [docs/decisions.md](./docs/decisions.md), and [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

## Tech Stack

- Java 21
- Spring Boot
- Spring Security
- Spring Data JPA
- Maven
- PostgreSQL
- Docker Compose
- Flyway

## Project Structure

```text
.
├── auth-api
├── data-api
├── docker-compose.yml
├── docs
├── scripts
├── KNOWN-ISSUES.md
├── CONTRIBUTING.md
└── README.md
```

See [docs/architecture.md](./docs/architecture.md) for the runtime view and [docs/decisions.md](./docs/decisions.md) for the rationale behind implementation choices.

## Run Locally

Build both services:

```bash
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
```

Start the full stack:

```bash
docker compose up -d --build
```

Check container status:

```bash
docker compose ps
```

Stop the stack:

```bash
docker compose down
```

Reset the database volume and start from a clean state:

```bash
docker compose down -v
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
```

The shortest reproducible verification path is also documented in [docs/verification.md](./docs/verification.md). Contributor workflow expectations are described in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Expected Services

After startup, the following services should be available:

- `auth-api` — `http://localhost:8080`
- `data-api` — `http://localhost:8081`
- `postgres` — `localhost:5432`

Startup assumptions, runtime boundaries, and service roles are also summarized in [docs/architecture.md](./docs/architecture.md).

## Health Endpoints

- `GET http://localhost:8080/health`
- `GET http://localhost:8081/health`

Example responses:

```json
{
  "status": "ok",
  "service": "auth-api"
}
```

```json
{
  "status": "ok",
  "service": "data-api"
}
```

These checks are part of the smoke flow described in [scripts/smoke.ps1](./scripts/smoke.ps1) and explained in [docs/verification.md](./docs/verification.md).

## API Flow

### Register

```text
POST /api/auth/register
Content-Type: application/json
```

Example request:

```json
{
  "email": "user@example.com",
  "password": "Pass12345!"
}
```

Expected behavior:
- creates a new user;
- stores the password in hashed form.

Registration verification steps are included in [docs/verification.md](./docs/verification.md), and operational notes for contributors are in [CONTRIBUTING.md](./CONTRIBUTING.md).

### Login

```text
POST /api/auth/login
Content-Type: application/json
```

Example request:

```json
{
  "email": "user@example.com",
  "password": "Pass12345!"
}
```

Example response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

JWT-related design notes are described in [docs/decisions.md](./docs/decisions.md), and the verification steps are documented in [docs/verification.md](./docs/verification.md).

### Protected Processing

```text
POST /api/process
Authorization: Bearer <JWT>
Content-Type: application/json
```

Example request:

```json
{
  "text": "hello"
}
```

Example response:

```json
{
  "result": "transformed text"
}
```

Expected behavior:
- validates the JWT in [`auth-api`](./auth-api);
- forwards the request to [`data-api`](./data-api) using the internal token header;
- returns the transformed result to the client;
- stores a processing log record in PostgreSQL.

This flow is currently verified end-to-end by the smoke script in [scripts/smoke.ps1](./scripts/smoke.ps1). The step-by-step check is described in [docs/verification.md](./docs/verification.md).

## Manual Smoke Test

### 1. Register a user

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass12345!"}'
```

### 2. Log in

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"Pass12345!"}'
```

Save the returned JWT token.

### 3. Call the protected endpoint

```bash
curl -X POST http://localhost:8080/api/process \
  -H "Authorization: Bearer <JWT>" \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected result:
- transformed text is returned;
- a new record is written to `processing_log`.

### 4. Verify unauthorized access is rejected

```bash
curl -X POST http://localhost:8080/api/process \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected result:
- request is rejected because no JWT is provided.

### 5. Verify direct access to data-api is rejected without the internal token

```bash
curl -X POST http://localhost:8081/api/transform \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected result:
- request is rejected with `403 Forbidden`.

These manual checks mirror the automated sequence in [scripts/smoke.ps1](./scripts/smoke.ps1). The same flow is summarized in [docs/verification.md](./docs/verification.md).

## PowerShell Smoke Test

A PowerShell smoke script can be run from the project root like this:

```powershell
pwsh ./scripts/smoke.ps1
```

The current smoke flow passes successfully with a full local Docker Compose startup and API verification.

A typical smoke test should:
- start the Docker Compose stack;
- wait until both services are available;
- register a test user;
- log in and obtain a JWT token;
- call the protected `/api/process` endpoint with the token;
- verify that the same endpoint rejects a request without JWT;
- verify that `data-api` rejects direct access without a valid internal token;
- print a final PASS/FAIL summary.

The current verification strategy is documented in [docs/verification.md](./docs/verification.md). Contributor expectations around rerunning the smoke flow are described in [CONTRIBUTING.md](./CONTRIBUTING.md).

## Database

The PostgreSQL schema is initialized through Flyway migrations.

Current approach:
- versioned SQL migrations live under `src/main/resources/db/migration`;
- schema creation is deterministic and works on a clean database;
- application startup does not rely only on ad hoc local database state.

This keeps local startup reproducible and easier to verify.

Database verification examples are included in [docs/verification.md](./docs/verification.md). Remaining database-related limitations, if any, are listed in [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

## Useful Commands

Show recent logs:

```bash
docker compose logs auth-api --tail 200
docker compose logs data-api --tail 200
docker compose logs postgres --tail 200
```

Follow logs in real time:

```bash
docker compose logs -f auth-api
docker compose logs -f data-api
```

Restart the stack from scratch:

```bash
docker compose down -v
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
```

These commands are also useful during the workflow described in [CONTRIBUTING.md](./CONTRIBUTING.md) and during troubleshooting noted in [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

## Notes

- `data-api` is intended for internal use only and should accept requests only when the shared `X-Internal-Token` header is valid.
- passwords must be stored in hashed form.
- secrets and tokens should not be logged.
- the solution intentionally keeps the architecture simple and focused on the task requirements.
- `spotless:check` may fail in this environment due to a `google-java-format` and JDK compatibility issue, so formatting was applied with IDE tooling.

Related project resources:
- [docs/verification.md](./docs/verification.md)
- [KNOWN-ISSUES.md](./KNOWN-ISSUES.md)
- [CONTRIBUTING.md](./CONTRIBUTING.md)
- [docs/architecture.md](./docs/architecture.md)
- [docs/decisions.md](./docs/decisions.md)

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
