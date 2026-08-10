# Persistence Specification

Version: **v0.3.7**  
Status: **Stable**

This document is the authoritative persistence model specification for the WinWin Backend Test Task.

Cross-references:
- [System spec](./system.md) — overall architecture
- [Invariants](./invariants.md) — persistence invariants (INV-003, INV-005)
- [Verification guide](../docs/verification.md) — database verification steps

---

## 1. Database

| Property | Value |
|----------|-------|
| Engine | PostgreSQL |
| Version | As specified in `docker-compose.yml` |
| Database name | `appdb` |
| User | `appuser` |
| Network | Internal Docker network only (not exposed on host) |
| Migration tool | Flyway (auto-applied on `auth-api` startup) |

---

## 2. Schema

### Table: `users`

Managed by Flyway migration in `auth-api`.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `BIGINT` / `SERIAL` | PRIMARY KEY, auto-increment |
| `email` | `VARCHAR` | UNIQUE, NOT NULL |
| `password` | `VARCHAR` | NOT NULL (stored as BCrypt hash) |

**Invariants:**
- `email` must be unique (`INV-005`)
- `password` is NEVER stored in plaintext; always BCrypt-hashed

---

### Table: `processinglog`

Managed by Flyway migration in `auth-api`.

> **Note:** The table name is `processinglog` (no underscore), not `processing_log`.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | `BIGINT` / `SERIAL` | PRIMARY KEY, auto-increment |
| `user_email` | `VARCHAR` | NOT NULL |
| `input_text` | `TEXT` | NOT NULL |
| `output_text` | `TEXT` | NOT NULL |
| `created_at` | `TIMESTAMP` | NOT NULL, default `NOW()` |

> **Note:** `user_email` is stored (not `user_id`). This is an intentional simplification documented in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

**Invariants:**
- Every successful `POST /api/process` creates exactly one row (`INV-003`)
- `created_at` is always set automatically

---

## 3. Migrations

- All Flyway migration scripts are located in `auth-api/src/main/resources/db/migration/`
- Migration file naming: `V{version}__{description}.sql`
- Migrations run automatically on `auth-api` startup
- The `data-api` has NO database access

---

## 4. Manual Inspection

To query the `processinglog` table in a running stack:

```powershell
docker exec winwin-backend-test-task-postgres-1 psql -U appuser -d appdb -c "SELECT id, user_email, input_text, output_text, created_at FROM processinglog ORDER BY id DESC LIMIT 5;"
```

Expected: at least one row after a successful `POST /api/process` call.

---

## 5. Constraints Summary

| Constraint | Where enforced |
|-----------|---------------|
| User email uniqueness | DB UNIQUE constraint + application 409 response |
| Password hashing | Application layer (BCrypt) |
| processinglog entry per request | Application layer (auth-api service) |
| No direct DB access from data-api | Architecture (data-api has no DB dependency) |
