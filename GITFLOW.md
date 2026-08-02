# GitFlow Rules

- `main` contains only released code.
- `develop` is the integration branch.
- Feature branches use `feature/<name>` and merge into `develop` by pull request.
- Release branches use `release/<version>` and merge into `main` and back into `develop`.
- Hotfix branches use `hotfix/<name>` and merge into `main` and back into `develop`.
- Pull requests require CI to pass before merge.
