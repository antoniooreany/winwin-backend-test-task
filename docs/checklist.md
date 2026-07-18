# Execution Checklist

## Global rules

- [x] Work only through `feature/*`, `release/*`, `hotfix/*`
- [x] After each step: local test, commit, push, CI check
- [x] Update documentation when API, run commands, env vars, or architecture change
- [x] Do not move forward while current step is red locally or in CI
- [x] Do not add new features on `release/*`

## Repository setup

- [x] Create GitHub repository
- [x] Initialize local git repository
- [x] Configure GitFlow
- [x] Create `main` and `develop`
- [x] Add base repository structure
- [x] Add initial service folders
- [x] Add GitHub Actions workflow
- [x] Fill core documentation

## Services

- [x] Bootstrap `auth-api` Spring Boot service
- [x] Bootstrap `data-api` Spring Boot service
- [x] Add basic `/health` endpoints
- [x] Ensure `mvn -f auth-api/pom.xml test` passes
- [x] Ensure `mvn -f data-api/pom.xml test` passes

## Auth & processing

- [x] Implement JWT-based authentication in `auth-api`
- [x] Implement register/login flow
- [x] Add unit tests for JWT service and auth flow
- [ ] Implement protected `/api/process`
- [ ] Implement internal call to `data-api` with shared header
- [ ] Add persistence for processing logs

## Infrastructure

- [ ] Add Dockerfiles for both services
- [ ] Add `docker-compose.yml` with Postgres and both services
- [ ] Add smoke test script or documented curl flow

## Finalization

- [ ] Run full end-to-end flow (register -> login -> process -> DB check)
- [x] Update README with current instructions
- [ ] Create release branch and tag
