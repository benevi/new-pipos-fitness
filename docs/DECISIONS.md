# Architecture Decision Records

ADR-style log of significant architecture and design decisions.

---

## ADR-001: Monorepo with pnpm

**Context**: Need to share contracts and engine-rules across API, worker, and (later) mobile.

**Decision**: Use a pnpm workspace monorepo. Apps in `apps/`, shared packages in `packages/`.

**Consequences**: Single install/test/lint at root; clear dependency graph; CI runs across all packages.

---

## ADR-002: Business logic in pure functions (engine-rules)

**Context**: AI and future changes must not break core training/nutrition logic.

**Decision**: All business logic lives in `packages/engine-rules` as pure functions. No database or framework dependencies there.

**Consequences**: Engine is easy to test and reason about; API and worker only orchestrate and persist; AI can call engines but not replace them.

---

## ADR-003: Contract-first with Zod

**Context**: Consistent validation and types across API, worker, and clients.

**Decision**: Shared request/response and domain schemas in `packages/contracts` using Zod. API and worker validate with these schemas.

**Consequences**: Single source of truth for shapes; type safety; no drift between docs and implementation when using same schemas for Swagger/validation.

---

## ADR-004: NestJS modular monolith for API

**Context**: Need a structured, maintainable API with clear modules.

**Decision**: NestJS as modular monolith. Modules for health, Prisma, and (later) auth, exercises, plans, etc.

**Consequences**: Clear boundaries; global Zod validation pipe; Swagger from decorators; easy to add modules per phase.

---

## ADR-005: BullMQ and Redis for jobs

**Context**: Async work (e.g. plan generation, notifications) must not block API.

**Decision**: Redis + BullMQ for job queue. Worker process in `apps/worker`.

**Consequences**: Reliable job processing; retries and visibility; same engine-rules used in worker for consistency.

---

## ADR-007: JWT authentication with refresh token rotation

**Context**: Phase 2 requires a secure auth layer for the user core.

**Decision**: Use JWT for access tokens (signed with a secret, short expiry). Use opaque refresh tokens stored as SHA-256 hashes in the database; on each refresh, the old token is deleted and a new one is issued (rotation). Passwords hashed with bcrypt. No business logic in auth beyond validation and token issuance; user profile updates are simple persistence.

**Consequences**: Clients must store refresh token securely and use it to obtain new access tokens; access token in Authorization header. Revocation is achieved by deleting the refresh token record.

---

## ADR-008: Refresh token revocation and rotation hardening (Phase 2.1)

**Context**: Single-use refresh tokens and explicit revocation improve security (token reuse detection, logout).

**Decision**: Refresh tokens are not deleted on use; they are marked with `revokedAt` and optionally linked to the replacement via `replacedByTokenId`. Reuse of a revoked token returns `401` with a stable error code `AUTH_REFRESH_REUSED`. `POST /auth/logout` accepts a refresh token in the body and sets `revokedAt` for that token. Production requires `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` to be set.

**Consequences**: Clients must use the new refresh token after each refresh; reuse is explicitly rejected. Logout is implemented as “revoke this refresh token”.

---

## ADR-006: Plan versioning (future)

**Context**: Plans are critical; history and auditability matter.

**Decision**: Plans will be immutable and versioned (Phase 5). No in-place edits of plan content.

**Consequences**: Deferred to Phase 5; design will support append-only history and clear version identifiers.
