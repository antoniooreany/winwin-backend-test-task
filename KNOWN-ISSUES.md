# Known Issues and Trade-offs

Related documents:
- [README.md](./README.md)
- [Architecture overview](./docs/architecture.md)
- [Technical decisions](./docs/decisions.md)
- [Verification guide](./docs/verification.md)
- [Contributing notes](./CONTRIBUTING.md)
- [Security policy](./SECURITY.md)
- [Smoke test script](./scripts/smoke.ps1)
- [Changelog](./CHANGELOG.md)

## 1. Minimal assignment scope

The implementation is intentionally compact and focused on the test task scope summarized in [README.md](./README.md), structured in [docs/architecture.md](./docs/architecture.md), and justified in [docs/decisions.md](./docs/decisions.md).

It currently covers:
- registration
- login
- JWT-based authentication
- internal service-to-service authorization
- PostgreSQL persistence
- a minimal processing flow

## 2. Simplified processing log model

The current persistence model is intentionally simple and should be read together with [docs/architecture.md](./docs/architecture.md), [docs/verification.md](./docs/verification.md), and [README.md](./README.md).

The `processinglog` table stores:
- `user_email`
- `input_text`
- `output_text`
- `created_at`

A more production-oriented version could store `user_id`, request metadata, and richer audit information. This trade-off is also reflected in [docs/decisions.md](./docs/decisions.md).

## 3. data-api is intentionally internal

[`data-api`](./data-api) is designed to be called by [`auth-api`](./auth-api), not by external clients.

Direct calls to `POST /api/transform` without a valid `X-Internal-Token` are expected to fail with `403`, as verified in [docs/verification.md](./docs/verification.md) and described in [docs/architecture.md](./docs/architecture.md).

## 4. Smoke verification is lightweight by design

[`scripts/smoke.ps1`](./scripts/smoke.ps1) is intended as a fast local confidence check.

It covers the main flow and key negative scenarios from [README.md](./README.md) and [docs/verification.md](./docs/verification.md), but it is not a full integration or performance test suite. Change expectations for this script should stay aligned with [CONTRIBUTING.md](./CONTRIBUTING.md) and [CHANGELOG.md](./CHANGELOG.md).

## 5. Reviewer path is optimized for PowerShell on Windows

The documentation intentionally uses PowerShell-native commands.

This avoids quoting and escaping problems that can appear with manual `curl.exe` calls in Windows PowerShell. This convention is also reflected in [README.md](./README.md), [docs/verification.md](./docs/verification.md), and [CONTRIBUTING.md](./CONTRIBUTING.md).

## 6. Possible future improvements

Potential next steps:
- store `user_id` in logs instead of `user_email`
- add fuller automated integration tests
- add stronger validation and error handling coverage
- add centralized structured logging
- tighten production-facing security hardening

These items should be interpreted as future improvements, not missing assignment scope, and should remain consistent with [docs/decisions.md](./docs/decisions.md), [SECURITY.md](./SECURITY.md), and [CHANGELOG.md](./CHANGELOG.md).
