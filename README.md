# WinWin Backend Test Task

Backend test task implementation for WinWin.travel.

## What is included

The project consists of two Spring Boot services:

- `auth-api` — handles registration, login, JWT authentication, and protected requests.
- `data-api` — internal service used by `auth-api` for text transformation.

The application runs locally with Docker Compose and PostgreSQL.

## Tech stack

- Java 21
- Spring Boot 4.x
- Spring Security
- Spring Data JPA
- Maven
- PostgreSQL
- Docker Compose
- GitHub Actions

## Current state

Implemented and verified:

- build and tests for both modules;
- working Docker Compose setup;
- PostgreSQL integration;
- user registration and login;
- JWT-protected endpoint flow;
- internal service-to-service call from `auth-api` to `data-api`.

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

Check status:

```bash
docker compose ps
```

Stop the stack:

```bash
docker compose down
```

Reset database volume:

```bash
docker compose down -v
docker compose up -d --build
```

## Health endpoints

- `GET http://localhost:8080/health`
- `GET http://localhost:8081/health`

Expected responses:

```json
{
  "status": "ok",
  "service": "auth-api"
}
```

```json
{
  "service": "data-api",
  "status": "ok"
}
```

## API flow

### Register

```text
POST /api/auth/register
```

```json
{
  "email": "user@example.com",
  "password": "Pass12345!"
}
```

### Login

```text
POST /api/auth/login
```

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

### Protected request

```text
POST /api/process
Authorization: Bearer <JWT>
```

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

## Database note

The local PostgreSQL schema is currently initialized automatically on startup through Hibernate with `spring.jpa.hibernate.ddl-auto=update`, which means schema changes are managed by Hibernate rather than versioned Flyway SQL migrations at this stage. This matches the current project state where application tables are created automatically and no Flyway schema history table is present.

## Next steps

- Introduce versioned Flyway SQL migrations under `src/main/resources/db/migration`.
- Switch Hibernate schema management from `ddl-auto=update` to `validate` or `none` after migrations are in place.
- Extend automated integration testing for the full Docker Compose flow.

## Useful commands

```bash
docker compose logs auth-api --tail 200
docker compose logs data-api --tail 200
docker compose logs -f auth-api
```

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
