# Architecture Overview

## Runtime components

The system consists of three local runtime components:

- `auth-api` — public-facing Spring Boot service responsible for authentication and the protected processing endpoint;
- `data-api` — internal Spring Boot service responsible for text transformation;
- `postgres` — relational persistence for users and processing logs.

## Request flow

1. A client registers and logs in through `auth-api`.
2. `auth-api` returns a JWT token after successful authentication.
3. The client calls `POST /api/process` with the JWT.
4. `auth-api` validates the JWT and forwards the text to `data-api`.
5. `auth-api` authenticates the internal call with `X-Internal-Token`.
6. `data-api` transforms the payload and returns the result.
7. `auth-api` persists a processing log entry in PostgreSQL and returns the transformed result to the client.

## Trust boundaries

- Public boundary: client → `auth-api`
- Internal boundary: `auth-api` → `data-api`
- Persistence boundary: `auth-api` → `postgres`

The public API is protected with JWT, while the internal API is protected with a shared trusted header token.

## Persistence model

The current minimum persistence model is:

- `users`
- `processing_log`

Schema creation is currently Hibernate-managed in `auth-api`.
