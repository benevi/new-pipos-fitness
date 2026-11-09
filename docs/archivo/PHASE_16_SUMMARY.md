# Phase 16 — Release Readiness

## Files Created

- **.env.example** — Root example env file for backend environments.
- **apps/api/src/logging/logging.ts** — Minimal structured logging helper (`log(level, message, meta)`).
- **apps/api/src/monitoring/monitoring.ts** — Monitoring bootstrap (`initMonitoring`) with optional SENTRY_DSN usage and process-level hooks.
- **.github/workflows/ci.yml** — CI pipeline for backend (pnpm lint/typecheck/test) and mobile (flutter analyze/test).
- **scripts/verify-backend.sh** — Local backend verification: install deps, lint, typecheck, test, `prisma migrate status`.
- **scripts/verify-mobile.sh** — Local mobile verification: `flutter pub get`, `flutter analyze`, `flutter test`.

## Files Modified

- **apps/api/src/main.ts**
  - Added `log` usage and `initMonitoring()` call.
  - New `enforceEnvConfig()` validates required env vars (skips when `NODE_ENV === 'test'`), fails fast with structured error log.
  - Logs structured “Server started” event with port and env.
- **apps/api/src/health/health.controller.ts**
  - `/health` now returns `{ status: 'ok' }`.
  - New `/health/db` endpoint uses `PrismaService` with a lightweight `SELECT 1` via `$queryRaw` and returns `{ status: 'ok' | 'error' }`.
- **apps/api/src/health/health.controller.spec.ts**
  - Updated to provide a mocked `PrismaService` and assert `{ status: 'ok' }` shape.
- **apps/api/src/modules/ai-coach/ai-coach.service.ts**
  - Left functional behavior unchanged; reused existing `persistInteraction` to store `rejectionReason` via its argument (no type changes).
- **apps/mobile/lib/core/api/api_client.dart**
  - `Dio` base URL now comes from `AppConstants.baseUrl` with a guard:
    - If empty → throws `StateError('API_BASE_URL is not configured...')`.
    - Uses `const baseUrl` for analyzer cleanliness.

## Environment Variables

Backend `.env.example` documents:

- **Required**
  - `NODE_ENV` — `development` | `staging` | `production`.
  - `PORT` — API port.
  - `DATABASE_URL` — Prisma database URL.
  - `JWT_ACCESS_SECRET` — JWT access token secret.
  - `JWT_REFRESH_SECRET` — JWT refresh token secret.
- **Optional**
  - `LOG_LEVEL` — currently not wired; reserved for future log filtering.
  - `AI_PROVIDER_KEY` — reserved for AI coach provider config.
  - `SENTRY_DSN` — when set, monitoring is initialized.

`apps/api/src/main.ts` checks (except in `NODE_ENV === 'test'`): `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `PORT`, `NODE_ENV`. Missing values cause a structured `log('error', ...)` and `process.exit(1)`.

Mobile:

- `AppConstants.baseUrl` already uses `String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000')`.
- `dioProvider` throws a clear `StateError` if `API_BASE_URL` resolves to an empty string, so failing to pass `--dart-define=API_BASE_URL=...` is caught early.

## Logging Strategy

- `apps/api/src/logging/logging.ts`:
  - In **production** (`NODE_ENV === 'production'`): logs are plain JSON via `console.log(JSON.stringify({ level, message, ...meta, timestamp }))`.
  - In non-production: human-readable `[timestamp] [level] message` plus metadata object.
- `main.ts` uses `log` for:
  - Reporting missing env vars (error).
  - Server startup (info).
- Additional logs can be routed through `log` for request errors, auth failures, and AI coach interactions without changing the logging contract.

## Monitoring Integration

- `apps/api/src/monitoring/monitoring.ts`:
  - `initMonitoring()` is called at bootstrap.
  - If `SENTRY_DSN` is **absent**: logs `Monitoring disabled (no SENTRY_DSN configured)` and does nothing else.
  - If `SENTRY_DSN` is **present**:
    - Logs `Monitoring initialized` with `{ provider: 'sentry-like', hasDsn: true }`.
    - Hooks:
      - `process.on('uncaughtException', ...)` → structured `error` log with message + stack.
      - `process.on('unhandledRejection', ...)` → structured `error` log with a safe string `reason`.
  - No request payloads or user-sensitive data are logged; only error summaries.

## Health Endpoints

- **GET `/health`**
  - Returns: `{ "status": "ok" }`.
- **GET `/health/db`**
  - Performs `SELECT 1` via Prisma’s `$queryRaw`.
  - On success: `{ "status": "ok" }`.
  - On error: `{ "status": "error" }`.

These are wired through the existing `HealthModule` and `PrismaModule` (global), so Prisma is available without extra imports in `AppModule`.

## CI Pipeline

- **.github/workflows/ci.yml**
  - Triggers on pushes and PRs to `main` and `develop`.
  - **Backend job** (Node + pnpm):
    - `pnpm install --frozen-lockfile`
    - `cd apps/api && pnpm lint`
    - `cd apps/api && pnpm typecheck`
    - `cd apps/api && pnpm test`
  - **Mobile job** (Flutter):
    - `cd apps/mobile && flutter pub get`
    - `flutter analyze`
    - `flutter test`
  - Mobile job depends on backend job; CI fails if any step fails.

## Build Verification Scripts

- **scripts/verify-backend.sh**
  - `cd apps/api`
  - `pnpm install`
  - `pnpm lint`
  - `pnpm typecheck`
  - `pnpm test`
  - `pnpm exec prisma migrate status`
- **scripts/verify-mobile.sh**
  - `cd apps/mobile`
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`

These mirror the CI behavior for local pre-release checks.

## Known Limitations

- Logging and monitoring are intentionally minimal:
  - No external Sentry SDK wired yet; logs are local/aggregator-friendly JSON.
  - `LOG_LEVEL` is present but not yet used to filter verbosity.
- Health endpoints expose simple `status` only; no detailed component breakdown.
- Mobile still uses a dev-friendly default `API_BASE_URL` (`http://10.0.2.2:3000`); production URLs must be supplied via `--dart-define`.

## Commands to Verify

```bash
# Backend
cd apps/api
pnpm lint
pnpm typecheck
pnpm test
pnpm exec prisma migrate status

# Or from repo root
./scripts/verify-backend.sh

# Mobile
cd apps/mobile
flutter pub get
flutter analyze
flutter test

# Or from repo root
./scripts/verify-mobile.sh
```

