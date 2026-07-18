# Execution Checklist

## Global rules

- [ ] Work only through `feature/*`, `release/*`, `hotfix/*`
- [ ] After each step: local test, commit, push, CI check
- [ ] Update documentation when API, run commands, env vars, or architecture change
- [ ] Do not move forward while current step is red locally or in CI
- [ ] Do not add new features on `release/*`

## Repository setup

- [x] Create GitHub repository
- [x] Initialize local git repository
- [x] Configure GitFlow
- [x] Create `main` and `develop`
- [x] Add base repository structure
- [x] Add initial service folders
- [ ] Add GitHub Actions workflow
- [ ] Fill core documentation