# Project Plan

## Goal

Implement a small two-service backend system for the WinWin.travel test task:

- `auth-api` — authentication, protected processing endpoint, Postgres persistence
- `data-api` — internal transform endpoint protected by shared header
- `postgres` — stores users and processing logs
- `docker-compose` — runs the full stack locally

## Delivery principles

The project should look professional, but not overengineered.

Priorities:
1. Working end-to-end functionality
2. Clean repository structure
3. Consistent Git workflow
4. Clear documentation
5. Small, testable increments

## Scope

### In scope
- Register and login
- Password hashing with BCrypt
- JWT-based authentication
- Protected `/api/process`
- Internal call from `auth-api` to `data-api`
- Shared internal token validation
- Postgres persistence for users and processing logs
- Dockerfiles and docker-compose
- GitHub Actions CI
- README with run and test instructions

### Out of scope
- Refresh tokens
- Roles and permissions
- Advanced observability
- Kubernetes
- Shared library modules
- Complex architectural patterns
- Heavy deployment automation