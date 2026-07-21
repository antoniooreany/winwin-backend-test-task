# Known Issues and Technical Debt

This document lists known limitations of the current implementation based on the latest verified local state.

## 1. Schema management is not yet versioned

Current state:

- `auth-api` uses `spring.jpa.hibernate.ddl-auto=update`;
- application tables are created automatically at runtime;
- `flyway_schema_history` is absent in the verified local database state.

Impact:

- schema evolution is not yet tracked through explicit versioned SQL migrations;
- database changes are less transparent than they would be with Flyway-managed migrations.

Recommended next step:

- add real Flyway migrations under `src/main/resources/db/migration`;
- switch Hibernate from `update` to `validate` after migration coverage is in place.

## 2. End-to-end verification is still lightweight

Current state:

- the project includes a smoke-test path and manual verification steps;
- there is no fully documented automated integration test suite for the complete business flow.

Impact:

- local reproducibility is good, but regression confidence can still be improved.

Recommended next step:

- add automated integration coverage for register → login → process → database assertion.

## 3. Formatting tooling requires compatibility review

Observed state:

- `spotless:check` failed locally due to a formatter/runtime compatibility problem rather than an application runtime failure.

Impact:

- code-style verification may be unreliable across some local environments.

Recommended next step:

- align Spotless, google-java-format, and JDK compatibility;
- document the expected local toolchain version.

## 4. Security model is intentionally minimal

Current state:

- the solution uses a lightweight JWT flow and a shared internal header token;
- this matches the scope of the assignment.

Impact:

- appropriate for a test task, but not intended as a production-grade zero-trust architecture.

Recommended next step:

- keep the current approach for the assignment scope;
- evolve only if the project scope grows.