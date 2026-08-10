# System Specification

Version: **v0.3.7**  
Status: **Stable**

This is the authoritative system-level specification for the WinWin Backend Test Task.  
All implementation MUST conform to this document.

Cross-references:
- [Architecture overview](../docs/architecture.md) — runtime diagram aligned with this spec
- [API spec](./api.md) — detailed endpoint contracts
- [Invariants](./invariants.md) — must-hold properties
- [Persistence spec](./persistence.md) — schema and migration contract
- [Decisions](../docs/decisions.md) — rationale for key choices

---

## 1. Components

The system consists of exactly three runtime components:

| Component | Role | Port |
|-----------|------|------|
| `auth-api` | Public-facing Spring Boot service: registration, login, JWT issuance, protected processing endpoint | 8080 |
| `data-api` | Internal Spring Boot service: text transformation | 8081 |
| `postgres` | PostgreSQL relational persistence | 5432 (internal) |

No other runtime components are in scope. Adding new components requires updating this spec first.

---

## 2. Runtime Orchestration

- Local orchestration: `docker-compose.yml` (Docker Compose v2)
- Both services use multi-stage Dockerfiles; no manual `mvn package` step is required before `docker compose up -d --build`
- Environment configuration is loaded from `.env` (based on `.env.example`)
- PostgreSQL applies Flyway migrations automatically on `auth-api` startup

---

## 3. Request Flow

The nominal request flow is:

```
Client → auth-api (POST /api/process, Bearer JWT)
       → auth-api validates JWT
       → auth-api → data-api (POST /api/transform, X-Internal-Token)
       → data-api transforms text, returns result
       → auth-api persists processinglog row in PostgreSQL
       → auth-api returns transformed result to client
```

This flow is the single source of truth for all verification scripts and integration tests.

---

## 4. Trust Boundaries

| Boundary | Protection Mechanism |
|----------|---------------------|
| Client → auth-api | JWT (Bearer token in Authorization header) |
| auth-api → data-api | Shared `X-Internal-Token` header |
| auth-api → postgres | Internal network only (not exposed publicly) |
| data-api (direct external access) | MUST be rejected (403) |

---

## 5. Authentication Model

- Registration: `POST /api/auth/register` → HTTP 201 Created
- Login: `POST /api/auth/login` → HTTP 200 OK with JWT in response body
- JWT: signed with a secret from environment variable (`JWT_SECRET`); stateless
- JWT validation performed in `auth-api` before forwarding to `data-api`

---

## 6. Text Transformation

- The current transformation is: **reverse the input string** (e.g., `hello → olleh`)
- This is intentionally minimal and demonstrates the processing pipeline
- The transformation logic lives exclusively in `data-api`

---

## 7. Persistence

- Users are persisted in the `users` table (managed by `auth-api`)
- Each successful `POST /api/process` persists one row in `processinglog`
- Schema is managed by Flyway migrations in `auth-api`
- Full persistence contract: see [persistence.md](./persistence.md)

---

## 8. CI Pipeline

- Runs on each push/PR: module unit tests for both `auth-api` and `data-api`
- Runs Docker Compose smoke checks (build + health + smoke flow)
- Gitlint validates commit message format (Conventional Commits)
- Dependabot monitors dependency updates

---

## 9. Branching Model

The project uses strict Gitflow:

| Branch Pattern | Purpose |
|----------------|---------|
| `main` | Stable releases only |
| `develop` | Integration branch |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `release/*` | Release preparation |
| `chore/*` | Non-functional changes |

Direct commits to `main` or `develop` are forbidden. All changes go through Pull Requests.

---

## 10. Versioning

- Current stable version: **v0.3.7**
- Version is tracked in [.version](../.version) and propagated by `scripts/set-version.ps1`
- Releases are tagged on GitHub with full changelog entries
