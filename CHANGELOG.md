# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres informally to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Flyway-based database initialization for reproducible local startup.
- Improved project documentation (README, CONTRIBUTING, SECURITY) with clearer run instructions and smoke-test flow.

### Changed

- Normalized markdown formatting across repository documentation.
- Moved database setup toward deterministic schema initialization instead of relying only on ad hoc local state.

## [0.2.0] - unreleased

> Release branch `release/0.2.0` exists, but the version is not yet tagged or published.

### Added

- Optional Flyway migrations for `users` and `processing_log` to support repeatable schema creation.
- Repository housekeeping updates to prepare a clean submission package.

### Changed

- Documentation updated to reflect the Docker Compose flow and manual smoke testing.
- Minor configuration and code tweaks to support fresh database startup.

### Known Limitations

- `0.2.0` is still in preparation; end-to-end integration tests are not yet exhaustive.

## [0.1.0-rc1] - 2026-07-18

### Added

- Initial authentication service (`auth-api`) with JWT-based registration and login endpoints.
- Initial data service (`data-api`) with health checks.
- Unit tests for JWT service, auth service, and user details service.
- Basic CI workflow with Maven test runs for both modules.

### Changed

- Hardened JWT token handling for tests to avoid flaky `ExpiredJwtException` during validation.

### Known Limitations

- No persistent database configuration wired for production.
- Internal communication between `auth-api` and `data-api` still minimal.
- End-to-end integration tests are not yet exhaustive.