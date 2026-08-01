## Summary

Use processing history entity for user-specific log retrieval in auth-api and fix Flyway/local DB mismatch affecting ProcessingHistoryIntegrationTest.

## Changes
- Switched processing history flow to use the current migration set and schema.
- Ensured ProcessingHistoryIntegrationTest uses the same Flyway migrations as AuthApiIntegrationTest.
- Cleaned up local Postgres state so Flyway can validate and apply migrations without missing version 2.
- Verified the full auth-api test suite (unit + integration) runs green.

## Checklist
- [x] Migrations validated and applied on both Testcontainers and local Postgres.
- [x] ProcessingHistoryIntegrationTest passes without ApplicationContext/Flyway errors.
- [x] `mvn test` passes on branch `feature/processinglog-use`.
