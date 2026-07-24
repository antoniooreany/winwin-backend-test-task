# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows an informal [Semantic Versioning](https://semver.org/spec/v2.0.0.html) style for repository milestones.

## [Unreleased]

### Changed

- aligned repository documentation for reviewer-facing submission
- standardized documentation commands to PowerShell
- aligned schema references to `processinglog`
- clarified verification flow and smoke-test usage

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
