# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres informally to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The repository follows a Git Flow-style process with feature branches merged into `develop`, release branches merged into `main`, and tagged releases published from `main`.

## [0.2.0] - 2026-07-20

Tag: `v0.2.0`  
Release branch: `release/0.2.0`  
Release PR: `#15`  
Release commit: `42124ef`

### Summary

This release completes the end-to-end auth and processing flow, hardens project documentation and metadata, and adds a reusable smoke test path for local verification.

### Added

- Protected processing flow in `auth-api`:
  - `ProcessController`
  - `ProcessService`
  - `DataApiClient`
  - `ProcessRequest`
  - `ProcessResponse`
- Processing persistence in `auth-api`:
  - `ProcessingLog`
  - `ProcessingLogRepository`
- Internal transform endpoint in `data-api`:
  - `TransformController`
  - `TransformRequest`
  - `TransformResponse`
- Consistent exception handling in `auth-api`:
  - `GlobalExceptionHandler`
  - `UserAlreadyExistsException`
- Project-level documentation and governance files:
  - `CHANGELOG.md`
  - `KNOWN-ISSUES.md`
  - `CONTRIBUTING.md`
  - `SECURITY.md`
  - `LICENSE`
- Automation and repository metadata:
  - `.github/workflows/changelog.yml`
  - `.gitattributes`
- Smoke verification script:
  - `scripts/smoke.ps1`

### Changed

- Refined `README.md` to reflect the current project scope, usage flow, and verification path.
- Updated `docker-compose.yml` to align with the final service wiring for the release.
- Switched `auth-api` configuration to the current `application.yml`-based setup.
- Adjusted `SecurityConfig` to allow health checks required for smoke verification.
- Updated tests to match the implemented request/response and processing flow.

### Fixed

- Aligned health endpoint access with the active security configuration.
- Standardized duplicate-user handling via explicit exception mapping and `409 Conflict`.
- Consolidated and cleaned older planning and checklist documents that were no longer part of the final reviewer-facing documentation set.

### Merged pull requests

#### Release PR
- `#15` — `release: 0.2.0`

#### Feature and stabilization PRs included in the release history
- `#27` — `docs/readme-final-touch`
- `#26` — `feature/auth-and-data-flow-final`
- `#25` — `test/align-auth-and-data-tests`
- `#24` — `docs/project-metadata-final`
- `#23` — `chore/repo-hygiene-final`
- `#22` — `chore/smoke-script-final`
- `#21` — `feature/flyway-db-init`
- `#13` — `docs/smoke-test-and-docs-cleanup`
- `#12` — `chore/repo-cleanup`
- `#11` — `feature/optional-flyway-migrations`
- `#10` — `feature/test-coverage-hardening`
- `#9` — `feature/test-coverage-hardening`

### Notable commits by branch/theme

#### Release branch `release/0.2.0`
- `be65457` — `docs: normalize contributing and security notes`
- `6fa2a79` — `chore(release): document smoke fixes in changelog`
- `2aa6d3e` — `docs(changelog): finalize 0.2.0 release notes`

#### Docs and metadata
- `733f0d2` — `docs: clarify example transform result in README`
- `7f208bc` — `docs: finalize project metadata and decisions`

#### Feature completion
- `eff1b20` — `feat: finalize auth and data flow and data-api build config`
- `12d3d64` — `test: align auth and data tests with current implementation`

#### Repo hygiene and smoke verification
- `39f79c6` — `chore: finalize editorconfig, env example and gitignore`
- `d158e0f` — `chore(smoke): align smoke script with current DTO flow`
- `9ede1e6` — `chore(smoke): finalize smoke script and scripts layout`

#### Database and migration preparation
- `0001c0d` — `feat(db): add Flyway migrations for auth and processing tables`
- `1d97438` — `Add Flyway migrations for auth and processing tables`

### Notes

- `v0.2.0` is the current tagged release on `main`.
- The repository history contains Flyway-related work on feature branches, but release documentation should describe only the verified state actually shipped with the tagged release.

---

## [0.1.0-rc1] - 2026-07-18

Tag: `v0.1.0-rc1`  
Release branch: `release/0.1.0`  
Release PR: `#7`  
Release commit: `8690e00`

### Summary

This pre-release establishes the initial two-service backend structure with Docker, PostgreSQL, authentication, JWT support, CI, and baseline project documentation.

### Added

- Initial repository standards and setup:
  - `.editorconfig`
  - `.env.example`
  - `.gitignore`
  - `.github/workflows/ci.yml`
- `auth-api` bootstrap:
  - Maven wrapper
  - `Dockerfile`
  - `pom.xml`
  - `AuthApiApplication`
  - `HealthController`
- Authentication flow in `auth-api`:
  - `AuthController`
  - `JwtService`
  - `AuthResponse`
  - `LoginRequest`
  - `RegisterRequest`
  - `AuthService`
  - `CustomUserDetailsService`
  - `JwtAuthenticationFilter`
  - `SecurityConfig`
- Persistence in `auth-api`:
  - `User`
  - `UserRepository`
- `data-api` bootstrap:
  - Maven wrapper
  - `Dockerfile`
  - `pom.xml`
  - `DataApiApplication`
  - `HealthController`
- Initial service configuration:
  - `auth-api/src/main/resources/application.properties`
  - `auth-api/src/main/resources/application.yml`
  - `data-api/src/main/resources/application.properties`
- Initial tests:
  - `JwtServiceTest`
  - `AuthServiceTest`
  - `CustomUserDetailsServiceTest`
  - `DataApiApplicationTests`
- Local environment:
  - `docker-compose.yml`
- Initial documentation:
  - `docs/architecture.md`
  - `docs/checklist.md`
  - `docs/decisions.md`
  - `docs/decisions-2.md`
  - `docs/plan.md`
  - `docs/plan-3.md`
  - `docs/smoke-checklist.md`
- Scripts directory placeholder:
  - `scripts/.gitkeep`

### Changed

- Expanded `README.md` to describe the initial architecture, Docker-based local run path, and auth flow.

### Merged pull requests

#### Release PR
- `#7` — `release: 0.1.0-rc1`

#### Foundational PRs included before the pre-release
- `#6` — merge from `develop`
- `#5` — `feature/release-docs-hardening`
- `#4` — `feature/test-coverage-hardening`
- `#3` — `feature/auth-jwt`
- `#2` — `feature/auth-persistence`
- `#1` — `feature/bootstrap-services`

### Notable commits by branch/theme

#### Release and release hardening
- `4a43cc4` — `docs: add release documentation and project metadata`
- `ae7a1a2` — `docs: add release documentation and project metadata`

#### Test hardening
- `1f36945` — `test: expand unit coverage for implemented auth features`

#### Authentication and JWT
- `65c8a1a` — `Fix auth-api tests and JWT expiration handling`
- `df49a1f` — `test: add auth and regression coverage`
- `967dc2c` — `feat: implement auth jwt flow`

#### Persistence
- `3c0e8e1` — `feat: add auth api persistence layer`

#### Service bootstrap
- `826afc6` — `chore: clean bootstrap service scaffolding`
- `baf2b7e` — `chore: bootstrap spring boot services`

### Notes

- `v0.1.0-rc1` is a pre-release tag, not the final `v0.1.0`.
- The current tag history shown for the repository includes `v0.1.0-rc1` and `v0.2.0`; no standalone `v0.1.0` tag should be documented unless it is later created.

---

## Git Flow notes

This repository history reflects a Git Flow-style release model:

- feature branches are developed from `develop`;
- stabilization happens through dedicated feature, chore, docs, and release branches;
- release branches are merged into `main`;
- annotated tags are created on release commits in `main`.

This changelog is intentionally organized around tagged releases first, then supporting PRs and notable commits included in each release.
