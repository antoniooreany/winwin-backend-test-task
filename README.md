# WinWin Backend Test Task

Backend test task implementation for WinWin.travel.

## Overview

This repository contains two Spring Boot services:

- `auth-api` — authentication service with JWT-based auth logic
- `data-api` — internal data service used by `auth-api`

The project is developed with a GitFlow-style branching model and validated through Maven test runs and GitHub Actions CI.

## Current status

At the current stage:

- both modules build successfully;
- `auth-api` and `data-api` pass Maven tests;
- JWT authentication flow is implemented and covered by tests;
- documentation and release preparation are in progress.

## Repository structure

```text
.
├── auth-api
├── data-api
├── docs
└── .github/workflows
```

## Stack

- Java 21
- Spring Boot
- Spring Security
- Maven
- JUnit 5
- PostgreSQL (planned/full flow)
- Docker / Docker Compose (planned/full flow)
- GitHub Actions

## Build and test

Run tests for each module separately:

```bash
mvn -f auth-api/pom.xml clean test
mvn -f data-api/pom.xml test
```

## Authentication

`auth-api` contains JWT-related authentication logic.

Implemented at this stage:

- token generation;
- username extraction from token;
- token validation;
- focused unit tests for JWT service behavior.

## Planned next steps

- implement protected `/api/process`;
- add internal call from `auth-api` to `data-api`;
- add persistence for processing logs and full Postgres-backed flow;
- add Dockerfiles and `docker-compose.yml`;
- finalize end-to-end smoke test and release.

## Development workflow

The project follows GitFlow conventions:

- `main` — stable release history
- `develop` — integration branch
- `feature/*` — implementation branches
- `release/*` — release stabilization branches
- `hotfix/*` — urgent fixes

## Notes

This repository intentionally avoids overengineering.
The goal is to provide a clean, understandable, and incrementally deliverable backend solution.
