# Project Invariants

Version: **v0.3.7**  
Status: **Stable**

This document defines the project invariants — behavioral properties that MUST be preserved in every implementation, fix, or refactoring.

These invariants are the source of truth for test coverage. Every invariant listed here MUST have at least one test or verification step that exercises it.

Cross-references:
- [System spec](./system.md) — full system context
- [API contract](./api.md) — endpoint contracts these invariants apply to
- [Persistence spec](./persistence.md) — persistence invariants
- [Verification guide](../docs/verification.md) — how invariants are verified locally
- [KNOWN-ISSUES.md](../KNOWN-ISSUES.md) — accepted deviations

---

## INV-001: data-api direct access is always rejected

**Statement:** Any HTTP request to `data-api` endpoints without a valid `X-Internal-Token` header MUST return HTTP `403`.

**Applies to:** `POST /api/transform` (data-api)

**Covered by:** Smoke verification step "rejection of direct access to data-api" and "rejection with wrong internal token".

---

## INV-002: Protected endpoints require valid JWT

**Statement:** Any request to `POST /api/process` (auth-api) without a valid JWT in the `Authorization: Bearer` header MUST return HTTP `403`.

**Applies to:** `POST /api/process` (auth-api)

**Covered by:** Smoke verification step "rejection without JWT".

---

## INV-003: Successful processing persists a log entry

**Statement:** Every successful `POST /api/process` call MUST result in exactly one new row in the `processinglog` table containing: `user_email`, `input_text`, `output_text`, and `created_at`.

**Applies to:** `auth-api` → PostgreSQL

**Covered by:** Database verification step in `scripts/verify-local.ps1` and integration test in `auth-api`.

---

## INV-004: Text transformation is deterministic and reversible

**Statement:** The `data-api` MUST transform the input text by reversing it. The transformation MUST be:
- Deterministic: same input always produces same output
- Character-level: `reverse("hello") == "olleh"`
- No side effects: transformation does not modify state

**Applies to:** `POST /api/transform` (data-api)

**Covered by:** Unit tests in `data-api`.

---

## INV-005: Registration is idempotent on duplicate email

**Statement:** A second registration attempt with an already-registered email MUST return HTTP `409 Conflict` and MUST NOT create a duplicate user record.

**Applies to:** `POST /api/auth/register` (auth-api)

**Covered by:** Integration test and full-verification script (409 handling).

---

## INV-006: All services must pass health checks before verification

**Statement:** Before any functional verification step, all three services (`auth-api`, `data-api`, `postgres`) MUST be running and healthy. `auth-api` and `data-api` health endpoints MUST return `{"status":"ok",...}`.

**Applies to:** Verification scripts and CI pipeline

**Covered by:** `scripts/verify-local.ps1` and `scripts/full-verification.ps1`.

---

## INV-007: Environment configuration via .env only

**Statement:** All secrets and environment-specific configuration (JWT secret, internal token, DB credentials) MUST be provided via `.env` file and MUST NOT be hardcoded in source code or committed to the repository.

**Applies to:** All services, all environments

**Covered by:** `.gitignore` (`.env` is excluded), `.env.example` provides the template.

---

## INV-008: No direct commits to main or develop

**Statement:** No code changes may be committed or pushed directly to `main` or `develop`. All changes MUST go through a Pull Request from a `feature/*`, `fix/*`, `release/*`, or `chore/*` branch.

**Applies to:** Repository branching model

**Covered by:** Branch protection rules on GitHub (to be configured) and SDD process enforcement.

---

## Adding New Invariants

When introducing a new behavioral constraint:
1. Add it to this file with a new `INV-NNN` identifier
2. Describe which test or verification step covers it
3. If no test exists yet, create one before or alongside the implementation
