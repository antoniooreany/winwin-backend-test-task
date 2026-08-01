## 0.3.6

- uth-api module verification may fail locally in ProcessingHistoryIntegrationTest with java.net.ConnectException: Connection refused during mvn -f .\auth-api\pom.xml clean verify.
- scripts/check-auth-flow.ps1 may fail on the login step with Unable to read data from the transport connection: An existing connection was forcibly closed by the remote host even after docker compose up -d --build.
- scripts/check-internal-token.ps1 may fail on the valid internal-token path with Unable to read data from the transport connection: An existing connection was forcibly closed by the remote host, while the missing-header and invalid-header checks still pass.
- The main reviewer-facing smoke flow remains .\scripts\verify-local.ps1, which currently passes successfully for the local Docker Compose stack.
# Known Issues and Trade-offs

This document reflects the accepted trade-offs of the current stable release: **v0.3.0**.

Related documents:
- [README.md](./README.md)
- [Architecture overview](./docs/architecture.md)
- [Technical decisions](./docs/decisions.md)
- [Verification guide](./docs/verification.md)
- [Contributing notes](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Local verification script](./scripts/verify-local.ps1)
- [Changelog](./CHANGELOG.md)

## 1. Minimal assignment scope

The implementation is intentionally compact and focused on the test task scope.

It currently covers:
- registration
- login
- JWT-based authentication
- internal service-to-service authorization
- PostgreSQL persistence
- a minimal processing flow

## 2. Simplified processing log model

The current persistence model is intentionally simple.

The `processinglog` table stores:
- `user_email`
- `input_text`
- `output_text`
- `created_at`

A more production-oriented version could store `user_id`, request metadata, and richer audit information.

## 3. data-api is intentionally internal

[`data-api`](./data-api) is designed to be called by [`auth-api`](./auth-api), not by external clients.

Direct calls to `POST /api/transform` without a valid `X-Internal-Token` are expected to fail with `403`.

## 4. Verification is lightweight by design

[`scripts/verify-local.ps1`](./scripts/verify-local.ps1) is intended as a fast local confidence check and the primary reviewer path for release `v0.3.0`.

It covers the main flow and key negative scenarios, but it is not a full integration, load, or performance test suite.

## 5. Reviewer path is optimized for PowerShell on Windows

The documentation intentionally uses PowerShell-native commands.

This avoids quoting and escaping problems that can appear with manual HTTP calls in Windows PowerShell.

## 6. Release-oriented documentation is intentionally concise

The top-level README is intentionally short and acts as a navigation entry point.

More detailed rationale and validation steps live in `docs/verification.md`, `docs/architecture.md`, and `docs/decisions.md`.

## 7. Possible future improvements

Potential next steps:
- store `user_id` in logs instead of `user_email`
- add fuller automated integration tests
- add stronger validation and error handling coverage
- add centralized structured logging
- tighten production-facing security hardening

