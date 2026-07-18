# WinWin Backend Test Task

Backend test task implementation for WinWin.travel.

## Overview

This repository contains two Spring Boot services:

- `auth-api` — authentication service with JWT-based auth logic.
- `data-api` — internal data service used by `auth-api`.

The project is developed with a GitFlow-style branching model and validated through Maven test runs and GitHub Actions CI.

## Current status

At the current stage:

- both modules build successfully;
- both modules pass Maven tests;
- JWT authentication flow is implemented;
- local end-to-end flow works with PostgreSQL and Docker Compose;
- basic CI is configured via GitHub Actions;
- release documentation (`LICENSE`, `CHANGELOG`, `CONTRIBUTING`, `SECURITY`) is in place.

## Repository structure

```text
.
├── auth-api        # Authentication service (JWT, Spring Security)
├── data-api        # Internal data service
├── docs            # Additional documentation (if any)
├── scripts         # Helper scripts
└── .github/workflows
    └── ci.yml      # CI pipeline
```

## Stack

- Java 21
- Spring Boot 4.x
- Spring Security
- Maven
- JUnit 5
- PostgreSQL
- Docker / Docker Compose
- GitHub Actions

## Build and test

Run tests for each module separately:

```bash
mvn -f auth-api/pom.xml clean test
mvn -f data-api/pom.xml clean test
```

Build runnable JARs:

```bash
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
```

CI runs Maven validation on each push and Pull Request.

## Running locally with Docker Compose

### Prerequisites

- JDK 21
- Maven
- Docker
- Docker Compose

### Start the project

First build both applications:

```bash
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
```

Then start the full stack:

```bash
docker compose up -d --build
```

To stop and remove containers:

```bash
docker compose down
```

To reset the database volume and start from scratch:

```bash
docker compose down -v
docker compose up -d --build
```

## Environment configuration

The project uses a root `.env` file for Docker Compose variables.

Example variables:

```env
POSTGRES_USER=appuser
POSTGRES_PASSWORD=apppassword
JWT_SECRET=change-me-in-env
INTERNAL_TOKEN=change-me-in-env
```

These values are injected into containers by `docker-compose.yml`.

## Health checks

After startup, both services should be available:

- `GET http://localhost:8080/health` → `auth-api`
- `GET http://localhost:8081/health` → `data-api`

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

## Authentication flow

`auth-api` provides public authentication endpoints and a protected processing endpoint.

Implemented behavior:

- user registration;
- user login;
- JWT generation and validation;
- forwarding authenticated processing requests to `data-api`;
- persistence of users and processing logs in PostgreSQL.

### Register

`POST /api/auth/register`

Request body:

```json
{
  "email": "user@example.com",
  "password": "Pass12345!"
}
```

Responses:

- `201 Created` — user successfully created;
- `409 Conflict` — user with the same email already exists.

Example conflict response:

```json
{
  "error": "User already exists"
}
```

### Login

`POST /api/auth/login`

Request body:

```json
{
  "email": "user@example.com",
  "password": "Pass12345!"
}
```

Successful response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9..."
}
```

## Protected processing endpoint

`POST /api/process`

Headers:

```text
Authorization: Bearer <JWT>
Content-Type: application/json
```

Request body:

```json
{
  "text": "hello"
}
```

Successful response:

```json
{
  "result": "HELLO"
}
```

## Internal data-api behavior

`data-api` is intended for internal service-to-service communication.

Direct external calls to its protected transformation endpoint without the internal token are rejected.

Example:

`POST /api/transform` without valid internal token → `403 Forbidden`

## Database

PostgreSQL is used for persistence in the full local flow.

Current database objects created by the application include:

- `users`
- `processinglog`

## Development workflow

The project follows GitFlow conventions:

- `main` — stable release history;
- `develop` — integration branch;
- `feature/*` — implementation branches;
- `release/*` — release stabilization branches;
- `hotfix/*` — urgent fixes.

All changes should go through Pull Requests with green Maven tests and CI.

## Changelog and releases

User-facing changes are tracked in [CHANGELOG.md](./CHANGELOG.md).

Pre-release tags such as `v0.1.0-rc1` may be used to mark release candidates. Each release should be associated with:

- a Git tag;
- a changelog entry;
- a passing CI build.

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.
