# Known Issues and Technical Debt

This document lists known limitations and consciously accepted trade-offs of the current implementation.

For the project overview and run instructions, see [README.md](./README.md). For verification steps and observed behavior, see [docs/verification.md](./docs/verification.md). For local workflow expectations, see [CONTRIBUTING.md](./CONTRIBUTING.md). For runtime structure, see [docs/architecture.md](./docs/architecture.md). For design choices, see [docs/decisions.md](./docs/decisions.md).

## 1. Formatting tooling requires compatibility review

Observed state:

- `spotless:check` may fail locally due to formatter and runtime compatibility issues rather than application logic failures.
- The failure is related to the underlying `google-java-format` plugin and the JDK or tooling versions used.

Impact:

- code-style verification may be unreliable on some local environments;
- contributors and reviewers can encounter build failures that are unrelated to functional behavior described in [README.md](./README.md) and validated in [docs/verification.md](./docs/verification.md).

Recommended next step:

- align Spotless, google-java-format, and JDK versions for consistent behavior;
- document the expected local toolchain in [CONTRIBUTING.md](./CONTRIBUTING.md);
- ensure formatter issues do not block core runtime validation from [docs/verification.md](./docs/verification.md).

## 2. Security model is intentionally minimal

Observed state:

- the solution uses a simple JWT flow for public authentication, as described in [README.md](./README.md) and [docs/architecture.md](./docs/architecture.md);
- internal service-to-service trust is implemented through a shared `X-Internal-Token` header between [`auth-api`](./auth-api) and [`data-api`](./data-api), as noted in [docs/decisions.md](./docs/decisions.md);
- secrets such as `JWT_SECRET`, database credentials, and `INTERNAL_TOKEN` are supplied through environment variables.

Impact:

- this is appropriate for the take-home task scope described in [README.md](./README.md);
- it is not intended as a production-grade zero-trust architecture or a comprehensive secret-management model.

Recommended next step:

- keep the current model for the assignment scope;
- if the project is extended, introduce stronger secret management and more granular authorization rules;
- reflect any future security-model change in [README.md](./README.md), [docs/verification.md](./docs/verification.md), and [docs/architecture.md](./docs/architecture.md).

## 3. End-to-end verification is still lightweight

Observed state:

- the repository includes a PowerShell smoke script in [scripts/smoke.ps1](./scripts/smoke.ps1);
- the current smoke flow passes and covers register, login, protected processing, and negative authorization checks, as documented in [docs/verification.md](./docs/verification.md);
- there is no dedicated automated integration-test suite for the full business scenario beyond the smoke flow and existing application tests.

Impact:

- local reproducibility is good;
- automated regression confidence is still lighter than a full integration-test pipeline would provide.

Recommended next step:

- keep [scripts/smoke.ps1](./scripts/smoke.ps1) as a fast local sanity check;
- add integration tests for register → login → process → database assertion;
- document any new verification layer in [README.md](./README.md), [docs/verification.md](./docs/verification.md), and [CONTRIBUTING.md](./CONTRIBUTING.md).

## 4. data-api remains intentionally internal

Observed state:

- the architecture is designed so that [`data-api`](./data-api) only accepts trusted internal calls from [`auth-api`](./auth-api), as described in [docs/architecture.md](./docs/architecture.md);
- direct `POST /api/transform` calls without the internal token are expected to fail, as shown in [README.md](./README.md) and [docs/verification.md](./docs/verification.md).

Impact:

- reviewers calling [`data-api`](./data-api) directly may see error responses that are intentional rather than accidental;
- the service should not be described as a public API.

Recommended next step:

- keep direct public access disallowed;
- keep the negative-check examples in [README.md](./README.md) and [docs/verification.md](./docs/verification.md);
- optionally standardize the direct-access error payload if the project scope grows.

## 5. The implementation remains intentionally minimal for the assignment

Observed state:

- the transform logic in [`data-api`](./data-api) is deliberately simple;
- the persistence model remains focused on `users` and `processing_log`, as described in [docs/architecture.md](./docs/architecture.md);
- the implementation prioritizes clarity and assignment coverage over additional abstractions, consistent with [README.md](./README.md) and [docs/decisions.md](./docs/decisions.md).

Impact:

- this improves reviewability for a short take-home task;
- it is not positioned as a production-ready domain model or enterprise architecture.

Recommended next step:

- keep the current simplicity for submission;
- only extend the model if new requirements appear;
- keep future scope changes aligned across [README.md](./README.md), [docs/architecture.md](./docs/architecture.md), and [docs/decisions.md](./docs/decisions.md).
