# Contributing

This repository is primarily a backend test-task submission, but the following conventions are used to keep changes consistent and reviewable.

## Local workflow

1. Build both services:
   ```bash
   mvn -f auth-api/pom.xml clean package -DskipTests
   mvn -f data-api/pom.xml clean package -DskipTests
   ```

2. Start the local stack:
   ```bash
   docker compose up -d --build
   ```

3. Verify the runtime state:
   - check both `/health` endpoints;
   - run the smoke script if available;
   - verify auth and protected processing behavior manually when needed.

## Change guidelines

- keep the implementation aligned with the assignment scope;
- do not introduce unnecessary abstractions;
- do not document unverified behavior as completed;
- do not log secrets, passwords, or tokens.

## Documentation policy

When project behavior changes, update:

- `README.md`
- `CHANGELOG.md`
- `KNOWN-ISSUES.md` when relevant
- `docs/verification.md` if the verification path changes

## Database note

The current project state uses Hibernate-managed schema creation. If Flyway is introduced later, the documentation must be updated accordingly.
