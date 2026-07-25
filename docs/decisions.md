# Technical Decisions

This file records small architectural and implementation decisions made during development.

For the project overview and run instructions, see [README.md](../README.md). For runtime structure, see [docs/architecture.md](./architecture.md). For verification steps, see [docs/verification.md](./verification.md). For active limitations and accepted trade-offs, see [KNOWN-ISSUES.md](../KNOWN-ISSUES.md). For local workflow expectations, see [CONTRIBUTING.md](../CONTRIBUTING.md). For security expectations, see [SECURITY.md](../SECURITY.md). For repository-visible changes over time, see [CHANGELOG.md](../CHANGELOG.md).

## Purpose

The goal is to show intentional trade-offs without overengineering. The same principle is visible in [README.md](../README.md), [docs/architecture.md](./architecture.md), and [KNOWN-ISSUES.md](../KNOWN-ISSUES.md).

## Initial Decisions

### Repository Style

Use a repository layout with two top-level applications:
- [`auth-api`](../auth-api)
- [`data-api`](../data-api)

This keeps the scope easy to review from [README.md](../README.md), the runtime structure straightforward in [docs/architecture.md](./architecture.md), and the verification path clear in [docs/verification.md](./verification.md).

### Java Version

Use Java 21 for local development, Docker runtime, and general consistency.

This choice should stay aligned with commands and tooling expectations in [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md), and [docs/verification.md](./verification.md).

### Build Tool

Use Maven for both Spring Boot applications.

This keeps the build steps short and reproducible in [README.md](../README.md), [CONTRIBUTING.md](../CONTRIBUTING.md), and [docs/verification.md](./verification.md).

### Runtime Model

Use Docker Compose for the local multi-service runtime defined in [`docker-compose.yml`](../docker-compose.yml).

This keeps local startup reproducible and consistent with the verification flow in [README.md](../README.md), [docs/verification.md](./verification.md), and [CONTRIBUTING.md](../CONTRIBUTING.md).

### Authentication Model

Use JWT for the public API in [`auth-api`](../auth-api) and a shared internal token for service-to-service trust with [`data-api`](../data-api).

This keeps the implementation aligned with the assignment scope summarized in [README.md](../README.md), the trust-boundary description in [docs/architecture.md](./architecture.md), and the verification path in [docs/verification.md](./verification.md).

### Persistence Approach

Use PostgreSQL for persistence and keep the schema deterministic through Flyway migrations.

This remains consistent with the schema notes in [README.md](../README.md), the validation steps in [docs/verification.md](./verification.md), the current limitations in [KNOWN-ISSUES.md](../KNOWN-ISSUES.md), and the change history in [CHANGELOG.md](../CHANGELOG.md).

### Smoke Verification

Keep a lightweight PowerShell smoke flow in [scripts/smoke.ps1](../scripts/smoke.ps1) to validate the main scenario quickly after local changes.

This complements, but does not replace, the runnable examples in [README.md](../README.md), the detailed verification path in [docs/verification.md](./verification.md), and the local workflow guidance in [CONTRIBUTING.md](../CONTRIBUTING.md).
