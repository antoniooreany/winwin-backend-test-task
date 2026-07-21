# Verification Guide

This guide provides the shortest reproducible path for validating the current project state.

## Clean start

```bash
docker compose down -v
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
docker compose ps
```

## Health checks

```bash
curl http://localhost:8080/health
curl http://localhost:8081/health
```

## Register user

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"reviewer@example.com","password":"Pass12345!"}'
```

## Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"reviewer@example.com","password":"Pass12345!"}'
```

Save the returned JWT token.

## Protected processing

```bash
curl -X POST http://localhost:8080/api/process \
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

## Negative checks

### Without JWT

```bash
curl -X POST http://localhost:8080/api/process \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected: `403 Forbidden`

### Direct call to data-api

```bash
curl -X POST http://localhost:8081/api/transform \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected: `403 Forbidden`

## Database checks

```bash
docker exec winwin-backend-test-task-postgres-1 \
  psql -U appuser -d appdb \
  -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"

docker exec winwin-backend-test-task-postgres-1 \
  psql -U appuser -d appdb \
  -c "SELECT COUNT(*) FROM processing_log;"
```

Expected:

- `users` and `processing_log` tables are present;
- successful processing requests increase the `processing_log` count.

## Smoke script

```powershell
pwsh ./scripts/smoke.ps1
```

Expected result: final `PASS`.
