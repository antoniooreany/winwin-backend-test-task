# Smoke Test Checklist

## Current stage smoke checks

### Build and tests

- [x] `mvn -f auth-api/pom.xml clean test`
- [x] `mvn -f data-api/pom.xml test`

### Repository state

- [x] Feature branch committed and pushed
- [x] Pull request opened
- [x] Working tree clean

## Full end-to-end smoke checks (planned)

- [ ] Start Postgres and both services
- [ ] Register user via `auth-api`
- [ ] Login and obtain JWT
- [ ] Call protected `/api/process`
- [ ] Verify internal call to `data-api`
- [ ] Verify processing log stored in Postgres
- [ ] Verify direct invalid call to `data-api` is rejected
