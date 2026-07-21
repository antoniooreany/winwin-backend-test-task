$ErrorActionPreference = 'Stop'

$readme = @'
# WinWin Backend Test Task

Backend take-home assignment implementation for WinWin.travel.

## Overview

The project contains two Spring Boot services running locally with Docker Compose and PostgreSQL:

- `auth-api` — handles registration, login, JWT-based authentication, and the protected client-facing processing endpoint.
- `data-api` — internal text transformation service used by `auth-api`.
- `postgres` — persistence layer for users and processing logs.

## Current state

Implemented and verified:

- build succeeds for both modules;
- Docker Compose starts the full local stack;
- PostgreSQL integration is working;
- user registration and login work;
- direct access to `data-api` without the internal token is rejected with `403 Forbidden`;
- requests to `POST /api/process` without JWT are rejected with `403 Forbidden`.

Current limitations verified during manual checks:

- the database schema is currently created through Hibernate with `spring.jpa.hibernate.ddl-auto=update` in `auth-api`;
- Flyway is not active in the running application state: there is no `db/migration` directory and no `flyway_schema_history` table in the database;
- `auth-api/pom.xml` contains a Flyway-related PostgreSQL artifact, but this does not currently result in active versioned schema migrations;
- the protected `POST /api/process` call returned `500 Internal Server Error` during the latest manual verification, so this flow must be described as incomplete until fixed.

## Tech stack

- Java 21
- Spring Boot 4.1.0
- Spring Security
- Spring Data JPA
- Maven
- PostgreSQL
- Docker Compose
- GitHub Actions

## Run locally

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

## Expected services

After startup, the following services should be available:

- `auth-api` — `http://localhost:8080`
- `data-api` — `http://localhost:8081`
- `postgres` — `localhost:5432`

## Health endpoints

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

## API flow

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

### Protected processing

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

Current observed behavior:

- without JWT, the request is rejected with `403 Forbidden`;
- with JWT, the endpoint is intended to call `data-api` and persist a processing log, but the latest manual verification returned `500 Internal Server Error`, so this flow should be treated as not fully verified yet.

### Direct access to data-api

```text
POST /api/transform
Content-Type: application/json
```

Example request:

```json
{
  "text": "hello"
}
```

Current observed behavior:

- direct access without the internal token is rejected with `403 Forbidden`.

## Verification

### Smoke script

A PowerShell smoke script is available from the repository root:

```powershell
pwsh ./scripts/smoke.ps1
```

This is the preferred verification path because it exercises the intended end-to-end flow and was previously used to obtain a passing result on the released state.

### Manual checks performed

The latest manual checks confirmed:

- successful build for both services;
- clean Docker Compose startup after `docker compose down -v`;
- presence of `users` and `processing_log` tables in PostgreSQL;
- absence of `flyway_schema_history`;
- successful login returning a JWT token;
- `403 Forbidden` for `/api/process` without JWT;
- `403 Forbidden` for direct `/api/transform` access without the internal token;
- `500 Internal Server Error` for the protected `/api/process` call during that manual run.

## Database

The current database state is Hibernate-managed, not Flyway-managed.

Observed facts:

- `auth-api/src/main/resources/application.yml` contains `ddl-auto: update`;
- there is no `auth-api/src/main/resources/db/migration` directory;
- there is no `data-api/src/main/resources/db/migration` directory;
- the database contains `users` and `processing_log` tables;
- the database does not contain `flyway_schema_history`.

This means the README should not claim that schema migrations are currently executed through Flyway.

## Next steps

- fix the `POST /api/process` happy-path failure that currently returns `500` during manual verification;
- if Flyway is intended, add real SQL migrations under `src/main/resources/db/migration` and switch Hibernate schema management from `ddl-auto=update` to `validate` or `none`;
- once the behavior is re-verified, keep `README.md` identical in `main` and `develop` so the documentation does not diverge between public branches.

## Useful commands

```bash
docker compose logs auth-api --tail 200
docker compose logs data-api --tail 200
docker compose logs postgres --tail 200
docker compose logs -f auth-api
docker compose logs -f data-api
```

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
'@

Set-Content -Path README.md -Value $readme -NoNewline
Write-Host 'README.md has been generated successfully.' -ForegroundColor Green
