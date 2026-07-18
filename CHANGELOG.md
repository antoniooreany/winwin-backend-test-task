# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres (informally) to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-rc1] - 2026-07-18

### Added
- Initial authentication service (\uth-api\) with JWT-based login and registration endpoints.
- Initial data service (\data-api\) with health checks.
- Unit tests for JWT service, auth service and user details service.
- Basic CI workflow with Maven test runs for both modules.

### Changed
- Hardened JWT token handling for tests to avoid flaky ExpiredJwtException during validation.

### Known limitations
- No persistent database configuration wired for production.
- Internal communication between \uth-api\ and \data-api\ still minimal.
- End-to-end integration tests are not yet exhaustive.

