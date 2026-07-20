# Contributing

Thanks for your interest in contributing to the WinWin Backend Test Task repository.

This project is intentionally kept small and focused. Contributions should aim
to improve clarity, correctness, or test coverage without overengineering.

## Branching Model

The repository follows a GitFlow-style branching strategy:

- `main` — stable releases
- `develop` — integration branch
- `feature/*` — new features or refactorings
- `release/*` — release stabilization
- `hotfix/*` — urgent fixes on top of production

## Contribution Steps

1. Create a feature branch from `develop`, for example:
   - `feature/my-improvement`
2. Implement the change and add or update tests.
3. Ensure the build is green locally:

   ```bash
   mvn -f auth-api/pom.xml clean test
   mvn -f data-api/pom.xml clean test
   ```

4. Push your feature branch to GitHub.
5. Open a Pull Request into `develop`.
6. Make sure the PR description explains:
   - what was changed,
   - why it was changed,
   - how it was tested.

## Code Style and Tests

- Prefer clear, explicit code over “clever” solutions.
- Every new behavior should be covered by tests (unit or integration).
- Do not introduce new external dependencies without a clear need.

## Commit Messages

- Use concise, descriptive messages (e.g. `feat:`, `fix:`, `test:`, `chore:`).
- Group related changes into a single commit when possible.

## Reporting Issues

If you find a bug or inconsistency:

1. Check existing issues and documentation.
2. When opening a new issue, include:
   - steps to reproduce,
   - expected vs actual behavior,
   - environment details (Java version, OS, etc.).