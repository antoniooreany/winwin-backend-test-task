# WinWin Backend Test Task

Implementation of the [WinWin.travel](http://WinWin.travel) backend test task: two Spring Boot services running with PostgreSQL through Docker Compose.

## Project overview

The repository contains three runtime components:

- `auth-api` — public API for registration, login, JWT authentication, and the protected processing endpoint.

- `data-api` — internal service that transforms input text and only accepts trusted requests from `auth-api`.

- `postgres` — persistence layer for users and processing logs.

The implementation is intentionally scoped to the assignment requirements and focuses on clarity, reproducibility, and correctness.

## Scope implemented

The following assignment requirements are implemented in the current project state:

- user registration in `auth-api`;

- user login in `auth-api`;

- password hashing with BCrypt;

- JWT-based protection for `POST /api/process`;

- internal service-to-service call from `auth-api` to `data-api`;

- rejection of direct `data-api` requests without the internal token;

- persistence of users and processing records in PostgreSQL;

- local startup through a single `docker-compose.yml`.

## Tech stack

- Java 21

- Spring Boot 4.1.0

- Spring Security

- Spring Data JPA

- Maven

- PostgreSQL

- Docker Compose

## Repository structure

```text

/auth-api

/data-api

/scripts

/docker-compose.yml

/[README.md](http://README.md)

```

## Run locally

### 1. Build both services

```bash

mvn -f auth-api/pom.xml clean package -DskipTests

mvn -f data-api/pom.xml clean package -DskipTests

```

### 2. Start the full stack

```bash

docker compose up -d --build

```

### 3. Check running services

```bash

docker compose ps

```

Expected services:

- `auth-api` — `http://localhost:8080`

- `data-api` — `http://localhost:8081`

- `postgres` — `localhost:5432`

### 4. Stop the stack

```bash

docker compose down

```

### 5. Reset the database volume

```bash

docker compose down -v

mvn -f auth-api/pom.xml clean package -DskipTests

mvn -f data-api/pom.xml clean package -DskipTests

docker compose up -d --build

```

## Health endpoints

```bash

curl [http://localhost:8080/health](http://localhost:8080/health)

curl [http://localhost:8081/health](http://localhost:8081/health)

```

Expected responses:

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

## API usage

### Register

```bash

curl -X POST [http://localhost:8080/api/auth/register](http://localhost:8080/api/auth/register) \

  -H "Content-Type: application/json" \

  -d '{"email":"[user@example.com](mailto:user@example.com)","password":"Pass12345!"}'

```

Expected behavior:

- returns `201 Created` for a new user;

- returns `409 Conflict` if the user already exists.

### Login

```bash

curl -X POST [http://localhost:8080/api/auth/login](http://localhost:8080/api/auth/login) \

  -H "Content-Type: application/json" \

  -d '{"email":"[user@example.com](mailto:user@example.com)","password":"Pass12345!"}'

```

Example response:

```json

{

  "token": "eyJhbGciOiJIUzI1NiJ9..."

}

```

### Protected processing

```bash

curl -X POST [http://localhost:8080/api/process](http://localhost:8080/api/process) \

  -H "Authorization: Bearer <JWT>" \

  -H "Content-Type: application/json" \

  -d '{"text":"hello"}'

```

Expected response:

```json

{

  "result": "HELLO"

}

```

### Negative checks

#### Without JWT

```bash

curl -X POST [http://localhost:8080/api/process](http://localhost:8080/api/process) \

  -H "Content-Type: application/json" \

  -d '{"text":"hello"}'

```

Expected result: `403 Forbidden`

#### Direct access to data-api

```bash

curl -X POST [http://localhost:8081/api/transform](http://localhost:8081/api/transform) \

  -H "Content-Type: application/json" \

  -d '{"text":"hello"}'

```

Expected result: `403 Forbidden` without the trusted internal token.

## Verification status

The following behavior has been verified against the current project state:

- both applications build successfully;

- Docker Compose starts the full stack successfully;

- both health endpoints respond with `200 OK`;

- registration works;

- duplicate registration is rejected;

- login returns a JWT;

- `POST /api/process` without JWT is rejected with `403 Forbidden`;

- direct `POST /api/transform` without the internal token is rejected with `403 Forbidden`;

- PostgreSQL contains `users` and `processing_log`;

- successful processing requests are expected to be persisted in `processing_log`.

## Database notes

The current schema management approach is Hibernate-based.

Observed project state:

- `auth-api` uses `spring.jpa.hibernate.ddl-auto=update`;

- the application tables are created automatically in the running environment;

- `flyway_schema_history` is not present in the verified local database state;

- active versioned Flyway migrations are not currently confirmed.

This means the project should currently be described as Hibernate-managed, not Flyway-managed.

## Smoke test

A lightweight end-to-end smoke test is available from the repository root:

```powershell

pwsh ./scripts/smoke.ps1

```

This is the preferred quick verification path after local changes.

## Design choices

This implementation intentionally keeps the architecture simple and aligned with the assignment:

- JWT-based authentication for the public API;

- a shared internal header token for service-to-service trust;

- a minimal persistence model centered on the requested use case;

- Docker-first local execution for easy review and reproducibility.

## Future improvements

If the project were extended beyond the test-task scope, the next logical improvements would be:

- introduce real Flyway migrations under `src/main/resources/db/migration`;

- switch Hibernate schema mode from `update` to `validate` after migrations are in place;

- add dedicated automated integration tests for the full Docker Compose happy-path;

- improve contributor and troubleshooting documentation.

## License

This project is licensed under the MIT License. See `LICENSE`.
