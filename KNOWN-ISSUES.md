# Known Issues and Technical Debt

This document lists known limitations of the current implementation based on the latest verified local state.

## 1. Schema management is not yet versioned

Current state:

- `auth-api` uses `spring.jpa.hibernate.ddl-auto=update`;
- application tables are created automatically at runtime by Hibernate;
- `flyway_schema_history` is absent in the verified local database state;
- there are no `src/main/resources/db/migration` directories with active SQL migrations in either service.

Impact:

- schema evolution is not yet tracked through explicit versioned migrations;
- database changes are less transparent than they would be with a Flyway-managed approach;
- future changes to the persistence model would require careful coordination to avoid drift between environments.

Recommended next step:

- add real Flyway migrations under `src/main/resources/db/migration` in `auth-api`;
- switch Hibernate from `update` to `validate` once migration coverage is in place;
- consider adding simple init migrations for `users` and `processing_log` matching the current JPA model.

## 2. Protected processing flow is intentionally minimal

Current state:

- the protected `POST /api/process` endpoint in `auth-api` is implemented and verified for the basic flow:
  - unauthenticated requests are rejected (e.g., `403 Forbidden`);
  - authenticated requests with a valid JWT reach `data-api` and return a transformed result;
- `data-api` currently implements simple transformation logic that converts input text to upper-case;
- the persisted `processing_log` entries reflect this minimal transform behavior.

Impact:

- the transform behavior is deliberately simple and chosen for clarity in the context of the test task;
- this is sufficient for demonstrating service-to-service communication, persistence, and error handling, but not intended as a production-ready business logic.

Recommended next step:

- keep the current simple transform for the test scope;
- if the project is extended, replace the transform with real business logic and update documentation/examples accordingly.

## 3. Direct data-api access behavior is negative by design

Current state:

- the architecture is designed so that `data-api` only accepts trusted internal calls from `auth-api` via `X-Internal-Token`;
- direct `POST /api/transform` calls from outside the Docker network or without the internal token do not return a successful transform payload and respond with error statuses.

Impact:

- reviewers who call `data-api` directly may see error responses and need to understand that this is intentional;
- the exact error status for direct access (e.g., `400` vs `403`) is not yet formalized as part of the public contract.

Recommended next step:

- keep direct public access to `data-api` disallowed;
- document in README that direct calls without the internal token are expected to fail and are part of the security model;
- optionally standardize the direct-access error response (e.g., always `403` with a clear JSON error body) if the project grows.

## 4. End-to-end verification is still lightweight

Current state:

- the repository includes a PowerShell smoke script and manual verification steps for the main flow (register → login → process);
- there is no fully documented automated integration test suite for the complete business scenario.

Impact:

- local reproducibility is good, but automated regression confidence is limited;
- changes to internal behavior may go unnoticed without manual re-verification.

Recommended next step:

- add integration tests that cover:
  - register → login → process → database assertion;
  - negative scenarios (no JWT, invalid JWT, missing/invalid `X-Internal-Token`);
- keep smoke tests as a fast local sanity check and treat integration tests as the primary regression safety net.

## 5. Formatting tooling requires compatibility review

Observed state:

- `spotless:check` has failed locally due to formatter/runtime compatibility issues rather than application logic failures;
- the failure is related to the underlying `google-java-format` plugin and the JDK/tooling versions used.

Impact:

- code-style verification may be unreliable on some local environments;
- contributors and reviewers can encounter build failures that are unrelated to functional behavior.

Recommended next step:

- align Spotless, google-java-format, and JDK versions for consistent behavior;
- document the expected local toolchain (JDK version and Maven plugin versions);
- ensure that formatter/tooling issues do not block basic application verification for reviewers.

## 6. Security model is intentionally minimal

Current state:

- the solution uses a simple JWT flow for public authentication and a shared internal header token for service-to-service trust;
- secrets such as `JWT_SECRET`, database credentials, and `INTERNAL_TOKEN` are supplied via environment variables in Docker Compose.

Impact:

- this is appropriate for a take-home test task and a local Docker-based environment;
- it is not intended as a production-grade zero-trust architecture or comprehensive secret management.

Recommended next step:

- keep the current model for the test-task scope;
- if the project is extended, consider:
  - stronger secret management (e.g., Vault or cloud secret services);
  - more granular authorization rules;
  - defense-in-depth on internal service calls.
  