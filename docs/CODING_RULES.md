# Coding Rules

Rules for human and AI-generated code to keep the system consistent and safe.

## Scope and Modules

- **Never modify unrelated modules.** Changes must be limited to the feature or fix at hand.
- **Respect module boundaries.** Do not move business logic into API or worker; do not add I/O to engine-rules.
- **Keep changes minimal.** Prefer clarity over cleverness; avoid large refactors unless explicitly requested.

## Contracts

- **Contracts must be updated with API changes.** When adding or changing endpoints, update `packages/contracts` first (schemas, enums).
- **Use contracts for validation.** API and worker must validate inputs/outputs with Zod schemas from contracts.
- **No duplicate DTOs.** Do not define request/response shapes in apps; use contracts.

## Business Logic

- **Business logic only inside engine-rules.** Training and nutrition decisions are implemented as pure functions in `packages/engine-rules`.
- **No DB or framework in engine-rules.** Engine functions must not import Prisma, NestJS, or any I/O layer.
- **Deterministic engines.** Same inputs must produce the same outputs; no randomness inside core logic unless explicitly designed.

## Tests

- **Tests required for engines.** Every exported engine function must have unit tests.
- **Engine tests must not use DB or HTTP.** Use in-memory inputs only.
- **CI must pass.** Lint, typecheck, and tests must succeed before merge.

## Dependencies

- **Avoid unnecessary dependencies.** Prefer standard library or existing packages.
- **Document architectural decisions.** Non-obvious choices go in `docs/DECISIONS.md`.
