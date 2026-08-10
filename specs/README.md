# Specifications

This directory contains the formal specifications for the **WinWin Backend Test Task** project, following the Spec-Driven Development (SDD) principle.

## SDD Principle

All implementation work MUST start from a specification in this directory.  
No feature, fix, or architectural change may be implemented without a corresponding spec document being created or updated first.

## Index

| Spec | Description |
|------|-------------|
| [system.md](./system.md) | System-level specification: components, flows, trust boundaries, invariants |
| [api.md](./api.md) | API contract specification: all endpoints, request/response schemas, status codes |
| [invariants.md](./invariants.md) | Project invariants that MUST be preserved in all implementations |
| [persistence.md](./persistence.md) | Persistence model specification: schema, migrations, constraints |

## How to use

1. Before starting any implementation, **read the relevant spec** in this directory.
2. If no spec exists for your feature, **create it first** and get it reviewed via PR.
3. Implementation MUST conform to the spec. If the spec needs to change, update the spec in the same PR.
4. Tests MUST cover the invariants defined in [invariants.md](./invariants.md).

## Cross-references

- [Architecture overview](../docs/architecture.md) — runtime structure aligned with system.md
- [Technical decisions](../docs/decisions.md) — rationale behind spec choices
- [Verification guide](../docs/verification.md) — how to verify conformance to specs
- [KNOWN-ISSUES.md](../KNOWN-ISSUES.md) — accepted deviations from ideal spec
