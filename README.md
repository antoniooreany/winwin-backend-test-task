# WinWin Backend Test Task

Backend test task implementation for WinWin.travel.

## Overview

The project contains two Spring Boot services running locally with Docker Compose and PostgreSQL:

- `auth-api` — handles registration, login, JWT-based authentication, and the protected client-facing processing endpoint.
- `data-api` — internal service used by `auth-api` for text transformation.
- `postgres` — persistence layer for users and processing logs.

The goal is to provide a minimal but clear implementation of authentication, internal service-to-service communication, and Docker-based local startup.

## Architecture

### auth-api

Responsibilities:

- register users;
- authenticate users and issue JWT tokens;
- expose a protected `POST /api/process` endpoint;
- call `data-api` through an internal request;
- store a processing log entry in PostgreSQL.

### data-api

Responsibilities:

- expose the transformation endpoint used by `auth-api`;
- validate the shared internal token header;
- process incoming text and return the transformed value.

### postgres

Stores:

- `users`
- `processing_log`

## Tech Stack

- Java 21
- Spring Boot
- Spring Security
- Spring Data JPA
- Maven
- PostgreSQL
- Docker Compose

## Project Structure

```text
.
├── auth-api
├── data-api
├── docker-compose.yml
└── README.md
```

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
docker compose up -d --build
```

## Expected Services

After startup, the following services should be available:

- `auth-api` — `http://localhost:8080`
- `data-api` — `http://localhost:8081`
- `postgres` — `localhost:5432`

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
  "result": "HELLO"
}
```

Expected behavior:

- validates the JWT in `auth-api`;
- forwards the request to `data-api` using the internal token header;
- returns the transformed result to the client;
- stores a processing log record in PostgreSQL.

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

## PowerShell Smoke Test

If a PowerShell smoke script is included in the repository, it can be run from the project root like this:

```powershell
pwsh ./scripts/smoke.ps1
```

A typical smoke test should:

- start the Docker Compose stack;
- wait until both services are available;
- register a test user;
- log in and obtain a JWT token;
- call the protected `/api/process` endpoint with the token;
- verify that the same endpoint rejects a request without JWT;
- print a final PASS/FAIL summary.

## Database

At the current stage, the PostgreSQL schema is initialized automatically on startup through Hibernate.

Current approach:

- schema creation is driven by JPA/Hibernate;
- tables are created automatically during application startup;
- no versioned Flyway SQL migrations are required for the basic working version.

This keeps the solution simple, which matches the scope of the test task.

## Planned Improvements

- add versioned Flyway SQL migrations under `src/main/resources/db/migration`;
- switch Hibernate schema management from `ddl-auto=update` to `validate` or `none`;
- add stronger end-to-end integration coverage for the full Docker Compose flow.

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

Restart the stack:

```bash
docker compose down
docker compose up -d --build
```

## Notes

- `data-api` is intended for internal use only and should accept requests only when the shared `X-Internal-Token` header is valid.
- passwords must be stored in hashed form;
- secrets and tokens should not be logged;
- the solution intentionally keeps the architecture simple and focused on the task requirements.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).