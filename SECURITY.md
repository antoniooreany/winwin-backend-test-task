# Security Policy

For the project overview and local startup path, see [README.md](./README.md). For runtime boundaries, see [docs/architecture.md](./docs/architecture.md). For accepted trade-offs, see [KNOWN-ISSUES.md](./KNOWN-ISSUES.md). For implementation rationale, see [docs/decisions.md](./docs/decisions.md). For validation steps, see [docs/verification.md](./docs/verification.md). For local workflow expectations, see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Supported Versions

This repository is a coding exercise and reference implementation, not a production-grade service. There is no formal support window, but security issues are still taken seriously.

Scope expectations should be interpreted together with [README.md](./README.md), [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), and [docs/decisions.md](./docs/decisions.md).

## Reporting a Vulnerability

If you believe you have found a security issue:

1. **Do not** open a public GitHub issue with exploit details.
2. Instead, contact the repository owner directly via the email address associated with the GitHub profile.

Please include:
- a clear description of the issue
- steps to reproduce
- any potential impact you see

Responsible disclosure is appreciated. If the issue is confirmed, reasonable effort will be made to address it in a timely manner.

## Scope

The primary scope is the sample code in:
- [`auth-api`](./auth-api)
- [`data-api`](./data-api)

Infrastructure, deployment scripts, and external services are considered out of scope for this exercise repository. This should also be read in the context of [KNOWN-ISSUES.md](./KNOWN-ISSUES.md), [docs/architecture.md](./docs/architecture.md), and [CHANGELOG.md](./CHANGELOG.md).
