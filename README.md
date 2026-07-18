# WinWin Backend Test Task

Backend test task implementation for WinWin.travel.

## Overview

This repository contains two Spring Boot services:

- \uth-api\ — authentication service with JWT-based auth logic.
- \data-api\ — internal data service used by \uth-api\.

The project is developed with a GitFlow-style branching model and validated
through Maven test runs and GitHub Actions CI.

## Current status

At the current stage:

- both modules build successfully;
- \uth-api\ and \data-api\ pass Maven tests;
- JWT authentication flow is implemented and covered by unit tests;
- basic CI is configured via GitHub Actions;
- initial release documentation (LICENSE, CHANGELOG, CONTRIBUTING, SECURITY)
  is in place.

## Repository structure

\\\	ext
.
├── auth-api        # Authentication service (JWT, Spring Security)
├── data-api        # Data service used by auth-api
├── docs            # Additional documentation (if any)
├── scripts         # Helper scripts (e.g. local dev helpers)
└── .github/workflows
    └── ci.yml      # CI pipeline (Maven tests)
\\\

## Stack

- Java 21
- Spring Boot 4.x
- Spring Security
- Maven
- JUnit 5
- PostgreSQL (planned for full flow)
- Docker / Docker Compose (planned for full flow)
- GitHub Actions

## Build and test

Run tests for each module separately:

\\\ash
mvn -f auth-api/pom.xml clean test
mvn -f data-api/pom.xml clean test
\\\

CI runs the same commands on each push and Pull Request.

## Authentication

\uth-api\ contains JWT-related authentication logic.

Implemented at this stage:

- token generation;
- username extraction from token;
- token validation;
- focused unit tests for JWT service behavior;
- basic auth service tests around registration and login.

## Development workflow

The project follows GitFlow conventions:

- \main\ — stable release history.
- \develop\ — integration branch.
- \eature/*\ — implementation branches.
- \elease/*\ — release stabilization branches.
- \hotfix/*\ — urgent fixes.

All changes should go through Pull Requests, with green Maven tests and CI.

## Changelog and releases

User-facing changes are tracked in [CHANGELOG.md](./CHANGELOG.md).

Tags such as \0.1.0-rc1\ can be used to mark pre-releases. Each release
should be associated with:

- a Git tag,
- an entry in the changelog,
- a passing CI build.

## License

This project is licensed under the MIT License.
See [LICENSE](./LICENSE) for details.

