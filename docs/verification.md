# Verification Guide

This document describes how to verify the project locally using only PowerShell commands.

Project entry point: [README.md](../README.md)  
Architecture: [docs/architecture.md](./architecture.md)  
Technical rationale: [docs/decisions.md](./decisions.md)  
Known limitations: [KNOWN-ISSUES.md](../KNOWN-ISSUES.md)  
Local workflow: [CONTRIBUTING.md](../CONTRIBUTING.md)  
Security note: [SECURITY.md](../SECURITY.md)  
Automated check: [scripts/smoke.ps1](../scripts/smoke.ps1)

## Verification Scope

This guide validates the same main runtime path summarized in [README.md](../README.md), explained in [docs/architecture.md](./architecture.md), and justified in [docs/decisions.md](./decisions.md). Scope limitations and simplifications are documented in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

## Prerequisites

Before running any command, make sure:
- Docker Desktop is running
- Java 21 is installed
- Maven is available
- a local [`.env`](../.env.example) file has been created based on [`.env.example`](../.env.example)

For setup context, also see [README.md](../README.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

## Recommended Path

The recommended reviewer path is:

```powershell
.\scripts\smoke.ps1
```

This script validates:
- Docker Compose startup
- health checks
- registration
- login
- protected processing
- rejection without JWT
- rejection of direct access to [`data-api`](../data-api)

The script is the shortest reproducible path described in [README.md](../README.md) and maintained alongside [CONTRIBUTING.md](../CONTRIBUTING.md).

## Manual Verification

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

This step aligns with [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md), and [docs/architecture.md](./architecture.md).

### 2. Health checks

```powershell
Invoke-RestMethod -Method GET -Uri "http://localhost:8080/health"
Invoke-RestMethod -Method GET -Uri "http://localhost:8081/health"
```

Expected responses:
- `{"status":"ok","service":"auth-api"}`
- `{"status":"ok","service":"data-api"}`

Health responses should remain aligned with [README.md](../README.md), [CHANGELOG.md](../CHANGELOG.md), and [scripts/smoke.ps1](../scripts/smoke.ps1).

### 3. Register

```powershell
$registerBody = @{ email = "reviewer@example.com"; password = "Pass12345!" } | ConvertTo-Json
Invoke-WebRequest -Method POST -Uri "http://localhost:8080/api/auth/register" -ContentType "application/json" -Body $registerBody
```

Expected:
- HTTP 201 Created

This step exercises the public boundary described in [docs/architecture.md](./architecture.md).

### 4. Login

```powershell
$loginBody = @{ email = "reviewer@example.com"; password = "Pass12345!" } | ConvertTo-Json
$loginResponse = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/auth/login" -ContentType "application/json" -Body $loginBody
$token = $loginResponse.token
$token
```

Expected:
- a JWT token is returned

This matches the authentication model described in [docs/decisions.md](./decisions.md) and [docs/architecture.md](./architecture.md).

### 5. Protected processing

```powershell
$processBody = @{ text = "hello" } | ConvertTo-Json
Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/process" -Headers @{ Authorization = "Bearer $token" } -ContentType "application/json" -Body $processBody
```

Expected response:
- `{"result":"olleh"}`

This step validates the main runtime flow documented in [README.md](../README.md), [docs/architecture.md](./architecture.md), and [scripts/smoke.ps1](../scripts/smoke.ps1).

### 6. Database verification

```powershell
docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT id, user_email, input_text, output_text, created_at FROM processinglog ORDER BY id DESC LIMIT 5;"
```

Expected:
- at least one row appears after a successful processing request
- the inserted row contains `user_email`, input text, output text, and timestamp

This confirms the current persistence model documented in [README.md](../README.md), [docs/architecture.md](./architecture.md), [docs/decisions.md](./decisions.md), and [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

### 7. Negative scenario: no JWT

```powershell
$body = @{ text = "hello" } | ConvertTo-Json
try {
    Invoke-RestMethod -Method POST -Uri "http://localhost:8080/api/process" -ContentType "application/json" -Body $body
} catch {
    $_.Exception.Message
}
```

Expected:
- request is rejected
- current expected status is `403`

The boundary being tested here is described in [docs/architecture.md](./architecture.md) and [docs/decisions.md](./decisions.md).

### 8. Negative scenario: direct access to data-api without internal token

```powershell
$body = @{ text = "hello" } | ConvertTo-Json
try {
    Invoke-RestMethod -Method POST -Uri "http://localhost:8081/api/transform" -ContentType "application/json" -Body $body
} catch {
    $_.Exception.Message
}
```

Expected:
- request is rejected
- current expected status is `403`

This matches the internal-service boundary described in [docs/architecture.md](./architecture.md), [docs/decisions.md](./decisions.md), and [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

### 9. Negative scenario: wrong internal token

```powershell
$body = @{ text = "hello" } | ConvertTo-Json
try {
    Invoke-RestMethod -Method POST -Uri "http://localhost:8081/api/transform" -Headers @{ "X-Internal-Token" = "wrong-token" } -ContentType "application/json" -Body $body
} catch {
    $_.Exception.Message
}
```

Expected:
- request is rejected
- current expected status is `403`

This check supports the same trust-boundary assumptions described in [docs/architecture.md](./architecture.md) and [docs/decisions.md](./decisions.md).

## Notes

- [`auth-api`](../auth-api) applies Flyway migrations on startup; see [docs/decisions.md](./decisions.md), [README.md](../README.md), and [CHANGELOG.md](../CHANGELOG.md).
- The current database table name is `processinglog`, not `processing_log`; see [README.md](../README.md), [docs/architecture.md](./architecture.md), and [CHANGELOG.md](../CHANGELOG.md).
- The current processing log stores `user_email`, not `user_id`; see [KNOWN-ISSUES.md](../KNOWN-ISSUES.md) and [docs/decisions.md](./decisions.md).
- For the shortest reproducible review path, prefer [scripts/smoke.ps1](../scripts/smoke.ps1) over manual request-by-request verification.
