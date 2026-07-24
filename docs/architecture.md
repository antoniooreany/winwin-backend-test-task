# Architecture Overview

This document summarizes the runtime structure referenced from [README.md](../README.md), the verification flow in [docs/verification.md](./verification.md), the accepted limitations in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md), and the implementation rationale in [docs/decisions.md](./decisions.md).

Additional repository guidance is available in [CONTRIBUTING.md](../CONTRIBUTING.md), [SECURITY.md](../SECURITY.md), and [CHANGELOG.md](../CHANGELOG.md).

## Runtime Components

The system consists of three local runtime components:

- [`auth-api`](../auth-api) — public-facing Spring Boot service responsible for authentication and the protected processing endpoint
- [`data-api`](../data-api) — internal Spring Boot service responsible for text transformation
- [`postgres`](../docker-compose.yml) — relational persistence for users and processing logs

The local orchestration entry point is [`docker-compose.yml`](../docker-compose.yml), as also described in [README.md](../README.md) and [docs/verification.md](./verification.md).

## Request Flow

1. A client registers and logs in through [`auth-api`](../auth-api).
2. [`auth-api`](../auth-api) returns a JWT token after successful authentication.
3. The client calls `POST /api/process` with the JWT.
4. [`auth-api`](../auth-api) validates the JWT and forwards the text to [`data-api`](../data-api).
5. [`auth-api`](../auth-api) authenticates the internal call with `X-Internal-Token`.
6. [`data-api`](../data-api) transforms the payload and returns the result.
7. [`auth-api`](../auth-api) persists a processing log entry in PostgreSQL and returns the transformed result to the client.

The same runtime flow is summarized in [README.md](../README.md), exercised in [docs/verification.md](./verification.md), and supported by [scripts/smoke.ps1](../scripts/smoke.ps1).

## Trust Boundaries

- Public boundary: client → [`auth-api`](../auth-api)
- Internal boundary: [`auth-api`](../auth-api) → [`data-api`](../data-api)
- Persistence boundary: [`auth-api`](../auth-api) → [`postgres`](../docker-compose.yml)

The public API is protected with JWT, while the internal API is protected with a shared trusted header token. This minimal model is discussed further in [docs/decisions.md](./decisions.md), tested through [docs/verification.md](./verification.md), and framed as an intentional scope choice in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

## Persistence Model

The current minimum persistence model is:

- `users`
- `processinglog`

The verification steps for these tables are documented in [docs/verification.md](./verification.md). Scope and trade-offs are described in [docs/decisions.md](./decisions.md), [KNOWN-ISSUES.md](../KNOWN-ISSUES.md), and [CHANGELOG.md](../CHANGELOG.md).
