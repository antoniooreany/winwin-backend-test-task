# Technical Decisions

## Purpose

This file records small architectural and implementation decisions made during development.
The goal is to show intentional trade-offs without overengineering.

## Initial decisions

### Git workflow
Use GitFlow with `main`, `develop`, `feature/*`, `release/*`, and `hotfix/*`.

### Repository style
Use a monorepo-like repository layout with two top-level applications:
- `auth-api`
- `data-api`

### Java version
Use Java 21 for local development, CI, and Docker consistency.

### Build tool
Use Maven for both Spring Boot applications.

### CI
Use GitHub Actions for basic verification on push and pull request.

## Auth & security decisions

### JWT library
Use `io.jsonwebtoken:jjwt` for JWT generation and parsing with HS256 signing and a Base64-encoded secret key.

### Token lifetime
Use a fixed token expiration window to keep the implementation simple and predictable for the test task.

### Password hashing
Use Spring Security `PasswordEncoder` with BCrypt.

### Test strategy
Test public service behavior instead of private methods.
Prefer small, stable unit tests over fragile framework-heavy tests unless integration coverage is required.
