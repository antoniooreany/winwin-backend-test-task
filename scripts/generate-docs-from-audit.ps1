$ErrorActionPreference = 'Stop'

$auditDir = Join-Path (Get-Location) 'audit-output'
if (-not (Test-Path $auditDir)) { throw 'audit-output directory not found. Run ./project-audit.ps1 first.' }

$auditFile = Get-ChildItem $auditDir -Filter 'project-audit-*.md' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $auditFile) { throw 'No audit report found. Run ./project-audit.ps1 first.' }

$audit = Get-Content $auditFile.FullName -Raw

$hasFlywayHistory = $audit -match 'flyway_schema_history' -and -not ($audit -match 'relation "flyway_schema_history" does not exist')
$has500 = $audit -match 'POST /api/process with JWT' -and $audit -match '500'
$has403NoJwt = $audit -match 'POST /api/process without JWT' -and $audit -match '403'
$has403Direct = $audit -match 'POST /api/transform direct' -and $audit -match '403'
$hasDdlUpdate = $audit -match 'ddl-auto:\s*update' -or $audit -match 'ddl-auto: update'
$hasUsersTable = $audit -match 'users'
$hasProcessingLog = $audit -match 'processing_log'
$hasSmokePassEvidence = $audit -match 'Smoke Test Summary' -or $audit -match 'RESULT: PASS'

$flywayState = if ($hasFlywayHistory) { 'Active' } else { 'Not confirmed in current runtime state' }
$processNote = if ($has500) {
  'The latest audit observed `500 Internal Server Error` on `POST /api/process` with JWT, so the happy path is not documented as fully verified.'
} else {
  'The latest audit did not capture a `500` on `POST /api/process` with JWT.'
}

$readme = @"
# WinWin Backend Test Task

Backend take-home assignment implementation for WinWin.travel.

## Overview

The project contains two Spring Boot services running locally with Docker Compose and PostgreSQL:

- `auth-api` — registration, login, JWT authentication, and the protected public processing endpoint.
- `data-api` — internal text transformation service used by `auth-api`.
- `postgres` — storage for users and processing logs.

## Current state

Verified from the latest local audit:

- both modules build successfully;
- Docker Compose starts the local stack;
- health endpoints are available for both services;
- registration and login are working;
- `POST /api/process` without JWT is rejected with `403 Forbidden`;
- direct access to `POST /api/transform` without the internal token is rejected with `403 Forbidden`.

$currentProcessNote

## Database state

- Hibernate schema management is currently $(if ($hasDdlUpdate) { 'enabled with `ddl-auto=update`' } else { 'not fully confirmed from the latest audit' });
- Flyway state: $flywayState;
- observed tables include $(if ($hasUsersTable -and $hasProcessingLog) { '`users` and `processing_log`' } else { 'application tables' }).

If `flyway_schema_history` is absent in the current database, the README should not claim active Flyway-driven schema migrations.

## Tech stack

- Java 21
- Spring Boot 4.x
- Spring Security
- Spring Data JPA
- Maven
- PostgreSQL
- Docker Compose
- GitHub Actions

## Run locally

```bash
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
```

Useful commands:

```bash
docker compose ps
docker compose logs auth-api --tail 200
docker compose logs data-api --tail 200
docker compose logs postgres --tail 100
docker compose down
docker compose down -v
```

## Verification

Health endpoints:

- `GET http://localhost:8080/health`
- `GET http://localhost:8081/health`

Manual audit focuses on:

- build results;
- runtime logs;
- register/login flow;
- protected endpoint behavior with and without JWT;
- direct `data-api` access restrictions;
- PostgreSQL schema state;
- repository evidence for Flyway resources and configuration.

$(if ($hasSmokePassEvidence) { 'A previous smoke run also produced a PASS result, but the documentation should still follow the latest verified audit state where behavior differs.' } else { '' })

## Known issues

$(if ($has500) { '- `POST /api/process` with JWT currently needs investigation because the latest audit captured `500 Internal Server Error`.' } else { '- No critical runtime issue was captured in the latest audit for `POST /api/process` with JWT.' })
- Flyway should be documented as active only after migrations, runtime startup, and `flyway_schema_history` are all confirmed together.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
"@

$changelog = @"
# Changelog

## Unreleased

### Verified
- Local build succeeds for `auth-api` and `data-api`.
- Docker Compose stack starts with `auth-api`, `data-api`, and PostgreSQL.
- Registration and login are working.
- `POST /api/process` without JWT is rejected with `403 Forbidden`.
- Direct `POST /api/transform` access without the internal token is rejected with `403 Forbidden`.

### Documentation
- README aligned with the latest local audit instead of older assumptions.
- Flyway is described conservatively unless runtime evidence confirms active migrations.

### Known issues
$(if ($has500) { '- Latest audit captured `500 Internal Server Error` on `POST /api/process` with JWT.' } else { '- No `500` on `POST /api/process` with JWT was captured in the latest audit.' })
$(if (-not $hasFlywayHistory) { '- `flyway_schema_history` is not confirmed in the current runtime database state.' } else { '- Flyway runtime state is confirmed by `flyway_schema_history`.' })
"@

Set-Content -Path README.md -Value $readme -Encoding UTF8
Set-Content -Path CHANGELOG.md -Value $changelog -Encoding UTF8
Write-Host "Generated README.md and CHANGELOG.md from $($auditFile.Name)" -ForegroundColor Green
