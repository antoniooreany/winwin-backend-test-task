# Contributing

This repository is primarily a backend test-task submission, but the following conventions are used to keep changes consistent and reviewable.

For the project overview and run instructions, see [README.md](./README.md). For verification steps and current behavior, see [docs/verification.md](./docs/verification.md). For current limitations and accepted trade-offs, see [KNOWN-ISSUES.md](./KNOWN-ISSUES.md). For runtime structure, see [docs/architecture.md](./docs/architecture.md). For implementation rationale, see [docs/decisions.md](./docs/decisions.md). For security expectations, see [SECURITY.md](./SECURITY.md). For visible repository history, see [CHANGELOG.md](./CHANGELOG.md).

## Local Workflow

### 1. Build both services

```powershell
mvn -f auth-api/pom.xml clean package -DskipTests
mvn -f data-api/pom.xml clean package -DskipTests
```

Build and startup expectations should remain aligned with [README.md](./README.md), [docs/verification.md](./docs/verification.md), and [docs/decisions.md](./docs/decisions.md).

### 2. Start the local stack

```powershell
docker compose up -d --build
```

Docker prerequisites are summarized in [README.md](./README.md), while the full reviewer path is described in [docs/verification.md](./docs/verification.md).

### 3. Verify the runtime state

- check both `/health` endpoints as described in [README.md](./README.md), [docs/verification.md](./docs/verification.md), and [CHANGELOG.md](./CHANGELOG.md)
- run [scripts/smoke.ps1](./scripts/smoke.ps1)
- verify auth and protected processing behavior manually when needed using the examples in [README.md](./README.md)

This quick path should stay consistent with [docs/verification.md](./docs/verification.md) and the runtime assumptions from [docs/architecture.md](./docs/architecture.md).

### 4. Review documentation and working tree changes

```powershell
git status --short
git diff -- README.md KNOWN-ISSUES.md CONTRIBUTING.md SECURITY.md CHANGELOG.md docs/verification.md docs/architecture.md docs/decisions.md scripts/smoke.ps1
```

Documentation should stay consistent across [README.md](./README.md), [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), [docs/verification.md](./docs/verification.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), [SECURITY.md](./SECURITY.md), and [CHANGELOG.md](./CHANGELOG.md).

## Change Guidelines

- keep the implementation aligned with the assignment scope described in [README.md](./README.md)
- do not introduce unnecessary abstractions without also updating [docs/decisions.md](./docs/decisions.md)
- do not document unverified behavior as completed; verification claims should remain aligned with [docs/verification.md](./docs/verification.md) and [scripts/smoke.ps1](./scripts/smoke.ps1)
- do not log secrets, passwords, or tokens
- keep documentation cross-links working and up to date across [README.md](./README.md), [docs/verification.md](./docs/verification.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), and [KNOWN-ISSUES.md](./KNOWN-ISSUES.md)

## Documentation Policy

When project behavior changes, update the relevant documents together:

- [README.md](./README.md) for project overview, quick start, and documentation navigation
- [docs/verification.md](./docs/verification.md) for the shortest reproducible validation path
- [KNOWN-ISSUES.md](./KNOWN-ISSUES.md) for active limitations and accepted trade-offs
- [docs/architecture.md](./docs/architecture.md) for runtime boundaries and request flow
- [docs/decisions.md](./docs/decisions.md) for implementation rationale
- [SECURITY.md](./SECURITY.md) for repository security expectations
- [CHANGELOG.md](./CHANGELOG.md) when a reviewer-visible change is made
- [scripts/smoke.ps1](./scripts/smoke.ps1) if the smoke flow itself changes

## Database Note

The PostgreSQL schema is Flyway-managed. If schema behavior changes, update [README.md](./README.md), [docs/verification.md](./docs/verification.md), [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), and [CHANGELOG.md](./CHANGELOG.md) in the same change.

## Verification Note

The current quick verification path is [scripts/smoke.ps1](./scripts/smoke.ps1). Manual API checks from [README.md](./README.md) should remain runnable and consistent with [docs/verification.md](./docs/verification.md).
