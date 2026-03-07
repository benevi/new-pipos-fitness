# Phase 2 — Authentication & User Core Summary

## Objective

Implement the core authentication system and user profile foundation: JWT auth (access + refresh with rotation), user registration/login, and profile/preferences/goals/muscle-focus endpoints.

## Files Created

### packages/contracts
- `src/schemas/auth.ts` — RegisterRequest, LoginRequest, RefreshTokenRequest, AuthResponse (Zod)
- `src/schemas/auth.test.ts` — schema tests
- `src/schemas/user.ts` — UserProfileUpdateRequest, UserPreferencesUpdateRequest, UserGoalsUpdateRequest, UserMuscleFocusUpdateRequest (Zod)
- `src/schemas/user.test.ts` — schema tests
- `src/enums/index.ts` — added Sex, TrainingLevel, TrainingLocation

### apps/api
- `src/modules/auth/auth.module.ts`
- `src/modules/auth/auth.service.ts` — register, login, refresh; bcrypt, JWT, hashed refresh tokens
- `src/modules/auth/auth.controller.ts` — POST /auth/register, /auth/login, /auth/refresh
- `src/modules/auth/jwt.strategy.ts` — Passport JWT strategy
- `src/modules/auth/jwt-auth.guard.ts`
- `src/modules/auth/auth.e2e-spec.ts` — Supertest auth tests
- `src/modules/users/users.module.ts`
- `src/modules/users/users.service.ts` — getMe, updateProfile, updatePreferences, updateGoals, updateMuscleFocus
- `src/modules/users/users.controller.ts` — GET /me, PUT /me/profile, /me/preferences, /me/goals, /me/muscle-focus
- `src/modules/users/current-user.decorator.ts`
- `src/modules/users/users.e2e-spec.ts` — Supertest users tests
- `prisma/migrations/20240305100000_auth_and_user_profile/migration.sql` — User columns + RefreshToken table

## Files Modified

- `packages/contracts/src/enums/index.ts` — Sex, TrainingLevel, TrainingLocation
- `packages/contracts/src/schemas/index.ts` — export auth and user schemas
- `apps/api/package.json` — @nestjs/jwt, @nestjs/passport, passport, passport-jwt, bcrypt, supertest, @types/bcrypt, @types/passport-jwt
- `apps/api/prisma/schema.prisma` — User extended; RefreshToken model; TrainingLocation enum
- `apps/api/src/app.module.ts` — import AuthModule, UsersModule
- `docs/ARCHITECTURE.md` — Authentication Layer section
- `docs/FUTURE_TASKS.md` — Phase 2 task removed; Phase 3, 4 tasks added
- `docs/DECISIONS.md` — ADR-007 JWT authentication

## Database Schema Changes

### User
- **Added**: passwordHash (required), updatedAt, heightCm, weightKg, age, sex, trainingLevel, preferredTrainingDays, availableEquipment (Json), trainingLocation (enum), goals (Json), muscleFocus (Json). All new profile/preference fields nullable.

### New
- **RefreshToken**: id, userId (FK User), tokenHash, expiresAt, createdAt.

### Enum
- **TrainingLocation**: home, gym, calisthenics.

Run from `apps/api`: `pnpm prisma:migrate` (or apply migrations on your DB).

## Commands to Run Locally

```bash
pnpm install
pnpm run build
pnpm run lint
pnpm run typecheck
pnpm run test
```

From `apps/api` (or `pnpm --filter @pipos/api ...`):

- Set `DATABASE_URL` in `.env`.
- `pnpm prisma:generate`
- `pnpm prisma:migrate` — apply migrations
- `pnpm start:dev` — API with auth and /me

Optional env: `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_EXPIRES` (default 15m), refresh fixed at 7 days.

## New API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/register | No | Register (email, password) → tokens + user |
| POST | /auth/login | No | Login → tokens + user |
| POST | /auth/refresh | No | Body: refreshToken → new tokens |
| GET | /me | Bearer | Current user profile |
| PUT | /me/profile | Bearer | Update heightCm, weightKg, age, sex |
| PUT | /me/preferences | Bearer | Update trainingLevel, preferredTrainingDays, availableEquipment, trainingLocation |
| PUT | /me/goals | Bearer | Update goals (JSON) |
| PUT | /me/muscle-focus | Bearer | Update muscleFocus (JSON) |

## Known Limitations

- No email verification or password reset (future phase).
- No rate limiting on auth endpoints (future phase).
- JWT secrets default to dev values; production must set `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET`.
- E2E tests mock Prisma; no in-CI DB required.

## Intentionally Not Implemented

- Exercise catalog, training/nutrition engine logic, analytics, AI assistant, notifications, billing, Flutter app, plan generation, workout tracking (later phases).

## Next Steps

- Create git tag: `phase-2-authentication`.
- Proceed to Phase 3 (Exercise Catalog) when ready.
