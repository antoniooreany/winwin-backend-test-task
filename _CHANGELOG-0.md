# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres informally to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- (reserved for future changes after 0.2.0)

### Changed

- (reserved for future changes after 0.2.0)

## [0.2.0] - 2026-07-20

### Added

- Flyway-based database initialization for reproducible local startup.
- Optional Flyway migrations for `users` and `processing_log` to support repeatable schema creation.
- PowerShell smoke test flow covering register, login, protected processing, unauthorized access, and direct access rejection for `data-api`.
- Repository housekeeping updates to prepare a clean submission package.
- Improved project documentation (README, CONTRIBUTING, SECURITY) with clearer run instructions and smoke-test flow.

### Changed

- Documentation updated to reflect the Docker Compose flow and manual smoke testing.
- Minor configuration and code tweaks to support fresh database startup.
- README updated with public-safe project context and deterministic startup guidance.
- Normalized markdown formatting across repository documentation.
- Smoke health checks aligned with the actual `/health` endpoints and `status: ok` responses.
- Smoke process payload aligned with the current `/api/process` contract.

### Known limitations

- End-to-end integration tests are not yet exhaustive.

## [0.1.0] - 2026-07-18

### Added

- Initial auth API persistence and JWT flow.

### Changed

- Prepared project documentation and release notes for 0.1.0.

### Tests

- Expanded unit coverage for implemented auth features.

## [0.1.0-rc1] - 2026-07-18

### Added

- Initial authentication service (`auth-api`) with JWT-based registration and login endpoints.
- Initial data service (`data-api`) with health checks.
- Unit tests for JWT service, auth service, and user details service.
- Basic CI workflow with Maven test runs for both modules.

### Changed

- Hardened JWT token handling for tests to avoid flaky `ExpiredJwtException` during validation.

### Known limitations

- No persistent database configuration wired for production.
- Internal communication between `auth-api` and `data-api` still minimal.
- End-to-end integration tests are not yet exhaustive.
