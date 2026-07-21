# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres informally to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-20

Release: `v0.2.0` (Merge pull request #15 from `release/0.2.0`).

### Added
- Centralized project documentation:
  - `CHANGELOG.md` with structured release notes.
  - `CONTRIBUTING.md` with contribution guidelines.
  - `SECURITY.md` with basic security and reporting information.
- Licensing and repository metadata:
  - `LICENSE` (MIT).
  - `.gitattributes` for consistent text handling.
  - Updated `.gitignore` with refined patterns.
  - `.github/workflows/changelog.yml` to automate changelog and release notes.
- Auth flow and processing functionality:
  - Global exception handling in `auth-api`:
    - `GlobalExceptionHandler` for consistent API error responses.
    - `UserAlreadyExistsException` with proper `409 Conflict` behavior.
  - Protected processing flow:
    - `ProcessController` (`POST /api/process`) in `auth-api`.
    - `ProcessService` orchestrating JWT‑protected requests and logging.
    - `DataApiClient` in `auth-api` for internal calls to `data-api`.
    - DTOs: `ProcessRequest`, `ProcessResponse`.
  - Persistence for processing:
    - `ProcessingLog` entity and `ProcessingLogRepository`.
- Data API processing functionality:
  - `TransformController` (`POST /api/transform`) in `data-api`.
  - DTOs: `TransformRequest`, `TransformResponse`.
  - Health and transform tests for `data-api`.
- Smoke test and scripts:
  - `scripts/smoke.ps1` as the preferred end‑to‑end verification script.
  - Updated `docker-compose.yml` to reflect final service wiring and ports.

### Changed
- `README.md`:
  - Refined structure to document auth flow, protected processing, data-api, and smoke verification.
  - Clarified example transform result and usage scenarios.
- Auth API configuration:
  - Switched from `application.properties` to `application.yml` as the primary configuration source.
  - Adjusted `SecurityConfig` to allow actuator health access for smoke verification.
  - Updated `AuthService` behavior to align with new exception handling.
- Test layout:
  - `JwtServiceTest` updated for more realistic JWT handling and expiration.
  - Added `ProcessServiceTest` and aligned `AuthServiceTest` with refined behavior.
- Data API configuration:
  - `data-api` `application.properties` aligned with final runtime setup.

### Fixed
- Ensured actuator health endpoints are accessible under the current security configuration so smoke tests can run without modifying security settings.
- Harmonized tests in `auth-api` and `data-api` with the implemented DTOs and processing flow.
- Removed outdated docs (`docs/checklist.md`, `docs/plan.md`, `docs/plan-3.md`, `docs/smoke-checklist.md`, `docs/decisions-2.md`) after migrating content into `README.md` and dedicated documentation files, reducing duplication.

---

## [0.1.0-rc1] - 2026-07-18

Pre-release: `v0.1.0-rc1` (Merge pull request #7 from `release/0.1.0`).

### Added
- Initial repository and CI setup:
  - `.editorconfig` for consistent code style.
  - `.env.example` and `.gitignore` for environment and repo hygiene.
  - `.github/workflows/ci.yml` for Maven build and test pipeline.
- `auth-api` service:
  - Maven wrapper and Dockerfile.
  - `AuthApiApplication` and basic `HealthController`.
  - Auth flow:
    - `AuthController` with registration and login endpoints.
    - `JwtService` for token generation and validation.
    - DTOs: `AuthResponse`, `LoginRequest`, `RegisterRequest`.
    - Persistence:
      - `User` entity.
      - `UserRepository`.
    - Security:
      - `JwtAuthenticationFilter`.
      - `SecurityConfig`.
    - Service layer:
      - `AuthService`.
      - `CustomUserDetailsService`.
  - Configuration:
    - `application.properties` and `application.yml` for auth-api settings.
  - Tests:
    - `JwtServiceTest`.
    - `AuthServiceTest`.
    - `CustomUserDetailsServiceTest`.
- `data-api` service:
  - Maven wrapper and Dockerfile.
  - `DataApiApplication` and basic `HealthController`.
  - Base `DataApiApplicationTests`.
  - Initial `application.properties` for data-api settings.
- Dockerized environment:
  - Initial `docker-compose.yml` for `auth-api`, `data-api`, and PostgreSQL.
- Documentation and planning:
  - `docs/architecture.md` describing initial two-service architecture.
  - `docs/checklist.md` with task checklist.
  - `docs/decisions.md` and `docs/decisions-2.md` with architecture and implementation decisions.
  - `docs/plan.md` and `docs/plan-3.md` with implementation plans.
  - `docs/smoke-checklist.md` with early smoke testing steps.
- Repository hygiene:
  - `scripts/.gitkeep` to track the scripts directory in Git.

### Changed
- `README.md`:
  - Extended to describe initial auth-api/data-api architecture and Docker setup.
  - Documented basic registration/login flow and overall project scope.

### Notes
- This release is explicitly marked as “Pre-release 0.1.0-rc1” and served as the first complete iteration of the two-service architecture with Docker and CI wired in, before the `0.2.0` documentation and processing flow hardening.

---

## [Bootstrap and pre-RC work] (no tagged version)

Although not tagged as a standalone release, the following milestones preceded `0.1.0-rc1` and are useful context for the evolution:

### Repository bootstrap
- `dc73a22`, `dd6eee0`, `353533d` and related commits:
  - Initialized repository structure.
  - Added bootstrap checklist and tracked empty directories.
  - Prepared repo for feature branches.

### Auth and persistence evolution
- Feature branches and merges:
  - `feature/bootstrap-services`:
    - Bootstrapped Spring Boot projects for `auth-api` and `data-api`.
  - `feature/auth-persistence`:
    - Added persistence layer for auth-api (`User` + repository).
  - `feature/auth-jwt`:
    - Implemented JWT auth flow.
    - Extended tests and regression coverage.
  - `feature/test-coverage-hardening`:
    - Expanded unit test coverage for implemented auth features.

These milestones are captured by merges such as:

- `Merge pull request #1 from antoniooreany/feature/bootstrap-services`
- `Merge pull request #2 from antoniooreany/feature/auth-persistence`
- `Merge pull request #3 from antoniooreany/feature/auth-jwt`
- `Merge pull request #4 from antoniooreany/feature/test-coverage-hardening`  

и зафиксированы в истории, но не имеют отдельного тегированного релиза.

---

## Команды для PowerShell, чтобы всё проверить и применить идеально

### 1. Проверить, что ты на правильной ветке и теге

```powershell
# убедиться, что main указывает на v0.2.0
git status
git tag --list --sort=creatordate
git log --oneline --decorate --graph --all --tags
```

Там ты уже видишь: `HEAD -> main, tag: v0.2.0`. Это значит, что `main` сейчас на коммите релиза 0.2.0. [file:1674]

### 2. Просмотреть детали релизов ещё раз (для верификации changelog)

#### Релиз 0.2.0

```powershell
git show v0.2.0 --no-patch --stat
git log --oneline --decorate --graph --max-count=15  # посмотреть верхнюю часть истории
```

#### Pre-release 0.1.0-rc1

```powershell
git show v0.1.0-rc1 --no-patch --stat
```

### 3. Подготовить и применить новый CHANGELOG

#### 3.1. Переключиться на ветку, где будешь править docs

С учётом Git Flow (у тебя есть `develop`):

```powershell
# переключиться на develop и подтянуть изменения
git checkout develop
git pull origin develop

# создать feature-ветку для changelog и docs
git checkout -b feature/docs-changelog-sync
```

#### 3.2. Обновить `CHANGELOG.md`

Здесь ты вручную вставляешь приведённый выше текст `CHANGELOG.md` (в редакторе). После этого проверяешь diff:

```powershell
git diff --stat
git diff
```

#### 3.3. Зафиксировать изменения

```powershell
git add CHANGELOG.md
git commit -m "docs: align changelog with tagged releases 0.1.0-rc1 and 0.2.0"
```

#### 3.4. Вернуться на develop и влить feature-ветку

```powershell
git checkout develop
git merge --no-ff feature/docs-changelog-sync
git push origin develop
```

### 4. При необходимости синхронизировать `main` с `develop` (по Git Flow)

Если хочешь, чтобы обновлённый changelog оказался на `main`:

```powershell
git checkout main
git pull origin main
git merge --no-ff develop
git push origin main
```

Поскольку тег `v0.2.0` уже висит на текущем коммите `main`, важно не двигать тег, а просто добавить новый коммит поверх (или оформить changelog в рамках следующей версии, если захочешь, например, `0.2.1`). На практике для тестового проекта это ок: тег указывает на сам релиз, а changelog коммит может идти после тега, если ты не хочешь пересоздавать релиз.

### 5. Проверка финального состояния

```powershell
# убедиться, что changelog на месте и ветки синхронизированы
git status
git log --oneline --decorate --graph --all --tags

# посмотреть последний коммит с changelog
git show HEAD --no-patch --stat
```

После этого ты можешь:

- обновить GitHub Releases (контент release notes) уже опираясь на новый `CHANGELOG.md`;
- быть уверен, что changelog честно отражает два релиза: `0.1.0-rc1` и `0.2.0`, и не выдумывает несуществующий `v0.1.0`.

---

Если хочешь, следующим шагом я могу предложить тебе ещё **короткий блок для самого GitHub Release v0.2.0**, чтобы текст в UI Releases совпадал с этим changelog и выглядел как аккуратный релизный summary.