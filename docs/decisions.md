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
