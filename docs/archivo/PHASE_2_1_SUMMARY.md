# Phase 2.1 — Authentication & User Core Hardening Summary

## What changed

- **Refresh token rotation:** Tokens are single-use; after refresh the old token is revoked (`revokedAt`) and linked to the new one (`replacedByTokenId`). Reuse returns `401` with code `AUTH_REFRESH_REUSED`.
- **Logout:** `POST /auth/logout` accepts `{ refreshToken }` and revokes that token.
- **Email normalization:** `User` has `emailNormalized` (unique); register/login use trim + lowercase. Duplicate registration with different casing returns 409; login works regardless of casing.
- **Strict Zod schemas:** `availableEquipment` (string[], max 200), `goals` (array of `{ type, priority, customText? }`, max 10), `muscleFocus` (array of `{ muscleId, priority }`, max 100). No free-form JSON.
- **Production config:** If `NODE_ENV=production`, startup requires `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET`; otherwise the process exits.

## Prisma schema changes

- **User:** `email` no longer unique; added `emailNormalized` (unique). All lookups/inserts use `emailNormalized`.
- **RefreshToken:** Added `revokedAt` (DateTime?), `replacedByTokenId` (String?, self-FK), `createdByIp` (String?), `userAgent` (String?).

**Migration name:** `20240305110000_phase_2_1_hardening`

## New endpoint

| Method | Path           | Body                | Description                    |
|--------|----------------|---------------------|--------------------------------|
| POST   | /auth/logout   | `{ "refreshToken": "..." }` | Revoke the given refresh token |

## How to test rotation behavior

1. **Reuse after refresh:** Call `POST /auth/refresh` with a valid token twice. First call returns 200 and new tokens. Second call with the *same* (old) token returns 401 and body `{ "code": "AUTH_REFRESH_REUSED" }`.
2. **Logout:** Call `POST /auth/logout` with a refresh token, then call `POST /auth/refresh` with that token; refresh returns 401.
3. **E2E:** See `apps/api/src/modules/auth/auth.e2e-spec.ts` (refresh reuse and logout tests with mocked Prisma).

## What remains for future phases

- BCRYPT_COST (or similar) enforcement in production (optional).
- Rate limiting on auth endpoints.
- Email verification, password reset.
- Exercise catalog, training/nutrition engines, etc. (see FUTURE_TASKS.md).

## Files created

- `apps/api/prisma/migrations/20240305110000_phase_2_1_hardening/migration.sql`
- `docs/PHASE_2_1_SUMMARY.md`

## Files modified

- `apps/api/prisma/schema.prisma` — User.emailNormalized, RefreshToken fields
- `apps/api/src/main.ts` — production config check
- `apps/api/src/modules/auth/auth.service.ts` — normalize email, refresh revocation + reuse, logout
- `apps/api/src/modules/auth/auth.controller.ts` — POST /auth/logout
- `apps/api/src/modules/auth/auth.e2e-spec.ts` — email normalization, refresh reuse, logout tests
- `apps/api/src/modules/users/users.e2e-spec.ts` — strict schema tests for preferences/goals/muscle-focus
- `packages/contracts/src/enums/index.ts` — GoalType, MusclePriority
- `packages/contracts/src/schemas/auth.ts` — LogoutRequestSchema
- `packages/contracts/src/schemas/user.ts` — strict AvailableEquipment, Goals, MuscleFocus schemas
- `packages/contracts/src/schemas/user.test.ts` — tests for strict schemas
- `docs/ARCHITECTURE.md` — Authentication Layer (logout, rotation), Configuration
- `docs/DECISIONS.md` — ADR-008
- `docs/FUTURE_TASKS.md` — BCRYPT_COST task

## Commands to run

```bash
pnpm install
pnpm run build
pnpm run lint
pnpm run typecheck
pnpm run test
```

Apply migration from `apps/api`: `pnpm prisma:migrate` (or deploy migration to your DB).

## Git tag

When Phase 2.1 is complete:

```bash
git tag phase-2-1-auth-hardening
# Do not push unless intended: git push origin phase-2-1-auth-hardening
```

## Known limitations

- E2E tests mock Prisma; no in-CI database. Refresh reuse and logout behavior are covered via mocks.
- `createdByIp` / `userAgent` are not yet set from request (optional; can be added later).
