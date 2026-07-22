# Verification Guide

This guide provides the shortest reproducible path for validating the current project state.

For the project overview and run instructions, see [README.md](../README.md). For current limitations and accepted trade-offs, see [KNOWN-ISSUES.md](../KNOWN-ISSUES.md). For local workflow conventions, see [CONTRIBUTING.md](../CONTRIBUTING.md). For the current smoke implementation, see [scripts/smoke.ps1](../scripts/smoke.ps1). For runtime structure, see [docs/architecture.md](./architecture.md). For implementation rationale, see [docs/decisions.md](./decisions.md).

## Clean Start

```bash
docker compose down -v
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
docker compose up -d --build
docker compose ps
```

This matches the local startup path described in [README.md](../README.md).

## Health Checks

```bash
curl http://localhost:8080/health
curl http://localhost:8081/health
```

These checks are also part of [scripts/smoke.ps1](../scripts/smoke.ps1) and the local workflow in [CONTRIBUTING.md](../CONTRIBUTING.md).

## Register User

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"reviewer@example.com","password":"Pass12345!"}'
```

This corresponds to the register flow shown in [README.md](../README.md).

## Login

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"reviewer@example.com","password":"Pass12345!"}'
```

Save the returned JWT token. JWT usage and request flow are also referenced in [README.md](../README.md) and [docs/architecture.md](./architecture.md).

## Protected Processing

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

This endpoint is part of the end-to-end flow described in [README.md](../README.md), [docs/architecture.md](./architecture.md), and [scripts/smoke.ps1](../scripts/smoke.ps1).

## Negative Checks

### Without JWT

```bash
curl -X POST http://localhost:8080/api/process \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected: `403 Forbidden`

This negative check is also part of [README.md](../README.md) and [scripts/smoke.ps1](../scripts/smoke.ps1).

### Direct Call to data-api

```bash
curl -X POST http://localhost:8081/api/transform \
  -H "Content-Type: application/json" \
  -d '{"text":"hello"}'
```

Expected: `403 Forbidden`

This behavior is intentional and also explained in [README.md](../README.md), [KNOWN-ISSUES.md](../KNOWN-ISSUES.md), and [docs/architecture.md](./architecture.md).

## Database Checks

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

These checks support the persistence claims from [README.md](../README.md) and the schema notes in [docs/decisions.md](./decisions.md).

## Smoke Script

```powershell
pwsh ./scripts/smoke.ps1
```

Expected result: final `PASS`.

This is the preferred quick verification path referenced in [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md), and [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).
