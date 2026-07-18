# Architecture

## Services

### auth-api

Responsibilities:

- register/login flow;
- JWT-based authentication;
- protected business endpoint(s);
- orchestration of internal calls to `data-api`;
- persistence of users and processing logs.

### data-api

Responsibilities:

- internal-only transformation endpoint;
- validation of shared internal header/token;
- simple isolated processing logic.

## Communication model

Planned request flow:

1. Client authenticates against `auth-api`
2. `auth-api` returns JWT
3. Client calls protected endpoint in `auth-api`
4. `auth-api` calls `data-api` with internal token
5. `auth-api` stores processing metadata in Postgres
6. `auth-api` returns final response to client

## Persistence

Planned relational persistence in Postgres:

- `users`
- `processing_log`

## Security model

External access:
- JWT-based authentication for protected endpoints in `auth-api`

Internal service-to-service access:
- shared internal token in request header for calls from `auth-api` to `data-api`

## Delivery approach

The implementation is intentionally incremental:

1. repository and CI foundation;
2. service bootstrap;
3. JWT authentication;
4. protected processing flow;
5. persistence and infrastructure;
6. release stabilization.
