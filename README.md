# WinWin Backend Test Task

Backend take-home for [WinWin.travel](https://winwin.travel): two Spring Boot services + PostgreSQL, started with Docker Compose.

- `auth-api` — register / login (JWT + BCrypt), protected `POST /api/process`
- `data-api` — internal `POST /api/transform` (requires `X-Internal-Token`)
- `postgres` — `users` and `processing_log` (Flyway)

`data-api` reverses the input text. Example: `"hello"` → `"olleh"`.

## Prerequisites

- Java 21
- Maven
- Docker Desktop
- `.env` in the project root (see `.env.example`)

```env
INTERNAL_TOKEN=super-internal-token
JWT_SECRET=0123456789abcdef0123456789abcdef
```

## Quick Start

```powershell
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
docker compose ps
```

Health checks:

```powershell
curl.exe -fsS http://localhost:8080/health
curl.exe -fsS http://localhost:8081/health
```

Ports:

| Service   | URL                     |
|-----------|-------------------------|
| auth-api  | http://localhost:8080   |
| data-api  | http://localhost:8081   |
| postgres  | localhost:5432          |

## Run Example

### 1. Register

```powershell
curl.exe -X POST http://localhost:8080/api/auth/register `
  -H "Content-Type: application/json" `
  -d "{\"email\":\"a@a.com\",\"password\":\"pass\"}"
```

Expected: `201`

### 2. Login

```powershell
curl.exe -X POST http://localhost:8080/api/auth/login `
  -H "Content-Type: application/json" `
  -d "{\"email\":\"a@a.com\",\"password\":\"pass\"}"
```

Expected: `200` with `{ "token": "..." }`. Save the token.

### 3. Process

```powershell
curl.exe -X POST http://localhost:8080/api/process `
  -H "Authorization: Bearer <token>" `
  -H "Content-Type: application/json" `
  -d "{\"text\":\"hello\"}"
```

Expected:

```json
{ "result": "olleh" }
```

A row is written to `processing_log` (`user_id`, `input_text`, `output_text`, `created_at`).

### 4. Negative checks

Without JWT → rejected:

```powershell
curl.exe -X POST http://localhost:8080/api/process `
  -H "Content-Type: application/json" `
  -d "{\"text\":\"hello\"}"
```

Direct call to `data-api` without `X-Internal-Token` → `403`:

```powershell
curl.exe -X POST http://localhost:8081/api/transform `
  -H "Content-Type: application/json" `
  -d "{\"text\":\"hello\"}"
```

## Automated Smoke Test

```powershell
.\scripts\smoke.ps1
```

Covers register → login → process, plus both negative checks above.

## Docs

- [Architecture](./docs/architecture.md)
- [Technical decisions](./docs/decisions.md)
- [Verification](./docs/verification.md)
- [Known issues](./KNOWN-ISSUES.md)
- [Contributing](./CONTRIBUTING.md)
- [Security](./SECURITY.md)

## Notes

- Passwords are stored with BCrypt; secrets/tokens are not logged.
- Schema is created by Flyway on `auth-api` startup.
- `auth-api` reaches `data-api` at `http://data-api:8081` on the Docker network.
- Env vars used: Postgres credentials, `JWT_SECRET`, `INTERNAL_TOKEN`.

## License

MIT — see [LICENSE](./LICENSE).
