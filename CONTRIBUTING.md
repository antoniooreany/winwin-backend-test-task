# Contributing

This repository is primarily a backend test-task submission, but the following conventions are used to keep changes consistent, reviewable, and easy to verify locally.

For the project overview and run instructions, see [README.md](./README.md). For verification steps and current behavior, see [docs/verification.md](./docs/verification.md). For current limitations and accepted trade-offs, see [KNOWN-ISSUES.md](./KNOWN-ISSUES.md). For runtime structure, see [docs/architecture.md](./docs/architecture.md). For implementation rationale, see [docs/decisions.md](./docs/decisions.md). For security expectations, see [SECURITY.md](./SECURITY.md). For visible repository history, see [CHANGELOG.md](./CHANGELOG.md).

## Local workflow

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

- Check both `/health` endpoints as described in [README.md](./README.md) and [docs/verification.md](./docs/verification.md).
- Run [scripts/smoke.ps1](./scripts/smoke.ps1).
- Verify auth and protected processing behavior manually when needed using the examples in [README.md](./README.md).

This quick path should stay consistent with [docs/verification.md](./docs/verification.md) and the runtime assumptions from [docs/architecture.md](./docs/architecture.md).

### 4. Review documentation and working tree changes

```powershell
git status --short
git diff -- README.md KNOWN-ISSUES.md CONTRIBUTING.md SECURITY.md CHANGELOG.md docs/verification.md docs/architecture.md docs/decisions.md scripts/smoke.ps1
```

Documentation should stay consistent across [README.md](./README.md), [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), [docs/verification.md](./docs/verification.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), [SECURITY.md](./SECURITY.md), and [CHANGELOG.md](./CHANGELOG.md).

## Git workflow

Use `main` for stable release history, `develop` for integration, and short-lived feature branches for task-focused changes.

### Branch naming

Use short, descriptive, lowercase branch names:

- `feature/version-sync`
- `feature/reviewer-docs`
- `fix/docker-copy-patterns`
- `hotfix/jwt-expiry-check`

If a task tracker is used, prepend the issue key or number, for example `feature/123-version-sync`.

### Standard flow

```powershell
git checkout develop
git pull origin develop
git checkout -b feature/<name>
```

Make small, focused commits during the task:

```powershell
git status
git add <files>
git commit -m "type: short clear message"
```

Before opening a pull request, rebase the feature branch onto the latest `origin/develop`:

```powershell
git fetch origin
git rebase origin/develop
```

If the rebase rewrites commits, update the remote branch safely:

```powershell
git push --force-with-lease
```

Open a pull request from `feature/<name>` into `develop`, wait for green CI, then merge. After merge:

```powershell
git checkout develop
git pull origin develop
git branch -d feature/<name>
git push origin --delete feature/<name>
```

### Branch rules

- Do not commit directly to `main`.
- Avoid committing directly to `develop`; create a feature branch even for small CI or documentation changes.
- Rebase only feature branches, not shared branches such as `develop` or `main`.
- Keep `develop` clean and synchronized with `origin/develop`.
- If a commit is made on `develop` by mistake, move it into a feature branch and reset local `develop` back to `origin/develop`.

## Change guidelines

- Keep the implementation aligned with the assignment scope described in [README.md](./README.md).
- Do not introduce unnecessary abstractions without also updating [docs/decisions.md](./docs/decisions.md).
- Do not document unverified behavior as completed; verification claims should remain aligned with [docs/verification.md](./docs/verification.md) and [scripts/smoke.ps1](./scripts/smoke.ps1).
- Do not log secrets, passwords, or tokens.
- Keep documentation cross-links working and up to date across [README.md](./README.md), [docs/verification.md](./docs/verification.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), and [KNOWN-ISSUES.md](./KNOWN-ISSUES.md).

## Documentation policy

When project behavior changes, update the relevant documents together:

- [README.md](./README.md) for project overview, quick start, and documentation navigation
- [docs/verification.md](./docs/verification.md) for the shortest reproducible validation path
- [KNOWN-ISSUES.md](./KNOWN-ISSUES.md) for active limitations and accepted trade-offs
- [docs/architecture.md](./docs/architecture.md) for runtime boundaries and request flow
- [docs/decisions.md](./docs/decisions.md) for implementation rationale
- [SECURITY.md](./SECURITY.md) for repository security expectations
- [CHANGELOG.md](./CHANGELOG.md) when a reviewer-visible change is made
- [scripts/smoke.ps1](./scripts/smoke.ps1) if the smoke flow itself changes

## Database note

The PostgreSQL schema is Flyway-managed. If schema behavior changes, update [README.md](./README.md), [docs/verification.md](./docs/verification.md), [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), [docs/architecture.md](./docs/architecture.md), [docs/decisions.md](./docs/decisions.md), and [CHANGELOG.md](./CHANGELOG.md) in the same change.

## Verification note

The current quick verification path is [scripts/smoke.ps1](./scripts/smoke.ps1). Manual API checks from [README.md](./README.md) should remain runnable and consistent with [docs/verification.md](./docs/verification.md).

## Versioning

The current repository version is stored in `.version`.

To update the version in one place and synchronize both Maven modules, run:

```powershell
.\scripts\set-version.ps1 -Version 0.3.5
```

This updates:
- `.version`
- `auth-api/pom.xml`
- `data-api/pom.xml`

Release-related documentation such as `README.md` and `CHANGELOG.md` should still be reviewed and finalized before publishing a release.

