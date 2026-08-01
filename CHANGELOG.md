# Changelog

All notable changes to this project are documented in this file.

For the current project overview, see [README.md](./README.md). For runtime structure, see [docs/architecture.md](./docs/architecture.md). For implementation rationale, see [docs/decisions.md](./docs/decisions.md). For validation guidance, see [docs/verification.md](./docs/verification.md). For accepted trade-offs, see [KNOWN-ISSUES.md](./KNOWN-ISSUES.md). For local change workflow, see [CONTRIBUTING.md](./CONTRIBUTING.md).

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows an informal [Semantic Versioning](https://semver.org/spec/v2.0.0.html) style for repository milestones.

## [Unreleased]

## [0.3.5] - 2026-08-01

### Added
- End-to-end auth-api integration test backed by PostgreSQL Testcontainers.
- CI smoke job running the full Docker Compose stack and protected flow.

### Changed
- CI now runs module tests for auth-api and data-api before packaging.
- auth-api and data-api Dockerfiles now use multi-stage builds.
- Repository versioning is centralized via .version and scripts/set-version.ps1.
## [0.3.4] - 2026-08-01

### Changed
- Release polishing.

## [0.3.3] - 2026-07-31

### Documentation

- Updated README release status to reflect the current stable release.
- Added release history alignment for reviewer-facing documentation.
- Linked the verification guide to the current published release context.

## [0.3.1] - 2026-07-31

### Documentation

- Simplified README quick start for reviewers.
- Synchronized reviewer checklist with `.\scripts\verify-local.ps1` verification flow.
- Clarified the current reviewer-facing local verification path and documentation entry points.

### Changed

- strengthened cross-links across repository documentation
- kept [README.md](./README.md) short while expanding navigation to detailed documents
- standardized documentation commands to PowerShell
- aligned schema references to `processinglog`
- clarified verification flow and smoke-test usage

## [0.3.0] - 2026-07-25

### Added

- verification guide aligned with the current reviewer path and the `scripts/verify-local.ps1` entry point
- current verification script set for local validation:
  - `scripts/verify-local.ps1`
  - `scripts/check-auth-flow.ps1`
  - `scripts/check-internal-token.ps1`
  - `scripts/full-verification.ps1`
  - `scripts/run-all-checks.ps1`
- `KNOWN-ISSUES.md` to document accepted limitations and explicit trade-offs for the current repository snapshot
- Flyway migration `V1__create_auth_tables.sql` to make auth-related schema creation explicit and reproducible on startup

### Changed

- README aligned with the current project structure, verification path, and release context
- `.env.example` and `docker-compose.yml` aligned with the reviewer-friendly local setup
- documentation wording refined across `README.md`, `docs/verification.md`, `docs/architecture.md`, and `docs/decisions.md`
- local verification flow standardized around PowerShell-first commands
- processing behavior documented as reverse-text processing (`hello -> olleh`)
- persistence wording aligned with the actual `processinglog` table and current column model

### Notes

- `0.3.0` is the current stable reviewer-facing release
- earlier releases (`0.2.0`, `0.1.0`, `0.1.0-rc1`) remain available for historical context

## [0.2.0] - 2026-07-20

### Added

- Flyway-based database initialization for reproducible local startup
- optional Flyway migrations for `users` and `processinglog` to support repeatable schema creation
- PowerShell smoke test flow covering register, login, protected processing, unauthorized access, and direct access rejection for [`data-api`](./data-api)
- repository housekeeping updates to prepare a clean submission package
- improved project documentation with clearer run instructions and smoke-test flow

### Changed

- documentation updated to reflect the Docker Compose flow and manual smoke testing
- minor configuration and code tweaks to support fresh database startup
- README updated with public-safe project context and deterministic startup guidance
- normalized markdown formatting across repository documentation
- smoke health checks aligned with the actual `/health` endpoints and `status: ok` responses
- smoke process payload aligned with the current `/api/process` contract

### Known limitations

- end-to-end integration tests are not yet exhaustive

## [0.1.0] - 2026-07-18

### Added

- initial auth API persistence and JWT flow

### Changed

- prepared project documentation and release notes for 0.1.0

### Tests

- expanded unit coverage for implemented auth features

## [0.1.0-rc1] - 2026-07-18

### Added

- initial authentication service ([`auth-api`](./auth-api)) with JWT-based registration and login endpoints
- initial data service ([`data-api`](./data-api)) with health checks
- unit tests for JWT service, auth service, and user details service
- basic CI workflow with Maven test runs for both modules

### Changed

- hardened JWT token handling for tests to avoid flaky `ExpiredJwtException` during validation

### Known limitations

- no persistent database configuration wired for production
- internal communication between [`auth-api`](./auth-api) and [`data-api`](./data-api) still minimal
- end-to-end integration tests are not yet exhaustive
