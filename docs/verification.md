# Verification Guide

This guide matches the current stable release: **v0.3.0**.

This document describes how to verify the project locally using PowerShell commands and the provided verification script.

Project entry point: [README.md](../README.md)  
Architecture: [Architecture overview](./architecture.md)  
Technical rationale: [Technical decisions](./decisions.md)  
Known limitations: [KNOWN-ISSUES.md](../KNOWN-ISSUES.md)  
Local workflow: [CONTRIBUTING.md](../CONTRIBUTING.md)  
Security note: [SECURITY.md](../SECURITY.md)  
Automated check: [scripts/verify-local.ps1](../scripts/verify-local.ps1)

## Verification scope

This guide validates the main runtime path summarized in [README.md](../README.md). Scope limitations and simplifications are documented in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

For the shortest and most reproducible reviewer path, use the current verification script entry point for release `v0.3.0`: [scripts/verify-local.ps1](../scripts/verify-local.ps1).

## Prerequisites

Before running any command, make sure:

- Docker Desktop is running
- Java 21 is installed
- Maven is available
- a local `.env` file has been created based on [`.env.example`](../.env.example)

## Recommended path

The recommended reviewer path is:

```powershell
.\scripts\verify-local.ps1
```

This script validates:

- Docker Compose startup
- health checks for `auth-api` and `data-api`
- registration
- login
- protected processing
- PostgreSQL persistence
- rejection without JWT
- rejection of direct access to [`data-api`](../data-api)
- rejection with a wrong internal token

It is the shortest reproducible verification path for this repository and the primary verification entry point for release `v0.3.0`.

## Manual verification (optional)

Manual verification is optional and intended only as an additional aid for reviewers who prefer step-by-step checks. For the shortest and most reproducible path, prefer the automated [scripts/verify-local.ps1](../scripts/verify-local.ps1) script.

If you still want to verify endpoints manually, you can use any HTTP client you prefer (for example `curl`, PowerShell `Invoke-RestMethod`, Postman or a similar tool). The following examples use PowerShell syntax, but any equivalent HTTP client is acceptable.

### 1. Clean start

```powershell
docker compose down -v
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
docker compose ps
```

Expected:

- all three containers are running
- PostgreSQL is healthy

### 2. Health checks

Use a browser or any HTTP client of your choice to check:

- `http://127.0.0.1:8080/health`
- `http://127.0.0.1:8081/health`

Expected responses:

- `{"status":"ok","service":"auth-api"}`
- `{"status":"ok","service":"data-api"}`

### 3. Register and login

If you want to repeat the authentication flow manually, use any HTTP client such as Postman, `curl`, or a REST client in your IDE.

Manual flow:

1. Register: send `POST http://localhost:8080/api/auth/register` with JSON body: `{"email":"reviewer@example.com","password":"Pass12345!"}`
2. Login: send `POST http://localhost:8080/api/auth/login` with the same JSON body.
3. Extract the returned JWT token from the login response.

Expected:

- registration returns HTTP 201 Created
- login returns a JSON body with a valid JWT token

For the shortest and most reproducible path, prefer the automated [scripts/verify-local.ps1](../scripts/verify-local.ps1) script.

### 4. Protected processing

Send a request with a valid JWT token:

- `POST http://localhost:8080/api/process`
- JSON body: `{"text":"hello"}`

Expected response:

- `{"result":"olleh"}`

In this implementation, "processing" means reversing the input text (for example, `hello -> olleh`).

A successful request should also create a new row in the `processinglog` table.

### 5. Database verification

There are two ways to verify persistence.

#### Option A: verification through the provided script

The recommended script [scripts/verify-local.ps1](../scripts/verify-local.ps1) already performs a protected processing request and verifies that the expected row is persisted in PostgreSQL during its execution.

Use this option if you want the shortest reproducible reviewer path.

#### Option B: manual SQL inspection in a running stack

If you want to inspect the database manually, keep the Docker Compose stack running, complete a successful protected processing request, and then query PostgreSQL:

```powershell
docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT id, user_email, input_text, output_text, created_at FROM processinglog ORDER BY id DESC LIMIT 5;"
```

Expected:

- at least one row appears after a successful `POST /api/process` request
- the inserted row contains `user_email`, input text, output text, and timestamp

If the query returns `(0 rows)`, no successful protected processing request has been persisted in the currently running stack yet. Make sure you have:

- registered and logged in to obtain a valid JWT, and
- successfully called `POST /api/process`

before querying the `processinglog` table.

### 6. Negative scenario: no JWT

Send a request to `POST http://localhost:8080/api/process` without an `Authorization` header.

Expected:

- request is rejected
- current expected status is `403`

### 7. Negative scenario: direct access to data-api without internal token

Send a request to `POST http://localhost:8081/api/transform` without `X-Internal-Token`.

Expected:

- request is rejected
- current expected status is `403`

### 8. Negative scenario: wrong internal token

Send a request to `POST http://localhost:8081/api/transform` with an incorrect `X-Internal-Token` header.

Expected:

- request is rejected
- current expected status is `403`

## Notes

- [`auth-api`](../auth-api) applies Flyway migrations on startup.
- The current database table name is `processinglog`, not `processing_log`.
- The current processing log stores `user_email`, not `user_id`.
- For the shortest reproducible review path, prefer [scripts/verify-local.ps1](../scripts/verify-local.ps1) over manual request-by-request verification.
## Release alignment

This verification flow aligns with release [`v0.3.2`](https://github.com/antoniooreany/winwin-backend-test-task/releases/tag/v0.3.2).

Reviewer-facing documentation for this release keeps the local setup, verification script usage, README quick start, and documentation map aligned with the current stable reviewer entry point.


