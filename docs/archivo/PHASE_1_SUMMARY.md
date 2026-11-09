# Phase 1 — Foundations Summary

## Objective

Create project foundations so that future phases can be implemented safely: repository structure, architecture documentation, CI, backend/worker/contracts/engine scaffolding, GitHub bootstrap, and Git workflow conventions.

## Files Created

### Root
- `package.json` — workspace root, scripts for build/lint/typecheck/test
- `pnpm-workspace.yaml` — workspace packages: apps/*, packages/*
- `tsconfig.base.json` — shared TypeScript config
- `.gitignore`
- `README.md` — overview, commands, bootstrap instructions

### Documentation
- `docs/ARCHITECTURE.md` — system overview, module boundaries, folder structure, monorepo, engine isolation, contract-first, versioning
- `docs/CODING_RULES.md` — AI-generated code rules, scope, contracts, business logic, tests
- `docs/ENGINE_RULES.md` — placeholders for training/nutrition engine rules, safety, validation
- `docs/PHASES.md` — all 14 phases with short definitions
- `docs/DECISIONS.md` — ADRs (monorepo, engine-rules, contracts, NestJS, BullMQ, versioning)
- `docs/PHASE_1_SUMMARY.md` — this file

### CI
- `.github/workflows/ci.yml` — install, build, lint, typecheck, test on push/PR to main and develop

### Scripts
- `scripts/bootstrap_github_repo.sh` — checks git/gh, creates repo from REPO_NAME (and optional GITHUB_OWNER), init git, main + develop, push

### Packages: contracts
- `packages/contracts/package.json`
- `packages/contracts/tsconfig.json`
- `packages/contracts/vitest.config.ts`
- `packages/contracts/.eslintrc.cjs`
- `packages/contracts/src/index.ts`
- `packages/contracts/src/enums/index.ts` — PlanStatus placeholder
- `packages/contracts/src/schemas/index.ts` — HealthResponseSchema
- `packages/contracts/src/schemas/index.test.ts`

### Packages: engine-rules
- `packages/engine-rules/package.json` (depends on @pipos/contracts)
- `packages/engine-rules/tsconfig.json`
- `packages/engine-rules/vitest.config.ts`
- `packages/engine-rules/.eslintrc.cjs`
- `packages/engine-rules/src/index.ts`
- `packages/engine-rules/src/training/index.ts` — getTrainingEngineVersion()
- `packages/engine-rules/src/nutrition/index.ts` — getNutritionEngineVersion()
- `packages/engine-rules/src/training/index.test.ts`
- `packages/engine-rules/src/nutrition/index.test.ts`

### Apps: api (NestJS)
- `apps/api/package.json` — NestJS, Prisma, Swagger, Zod, @pipos/contracts
- `apps/api/nest-cli.json`
- `apps/api/tsconfig.json`
- `apps/api/.eslintrc.cjs`
- `apps/api/vitest.config.ts`
- `apps/api/src/main.ts` — bootstrap, Swagger at /docs
- `apps/api/src/app.module.ts` — HealthModule, PrismaModule, ZodValidationInterceptor
- `apps/api/src/health/health.module.ts`, `health.controller.ts` — GET /health
- `apps/api/src/health/health.controller.spec.ts`
- `apps/api/src/prisma/prisma.module.ts`, `prisma.service.ts`
- `apps/api/src/zod/zod-validation.interceptor.ts`, `zod-body.decorator.ts`
- `apps/api/prisma/schema.prisma` — User (id uuid, email, createdAt)
- `apps/api/prisma/seed.ts` — placeholder
- `apps/api/prisma/migrations/migration_lock.toml`
- `apps/api/prisma/migrations/README.md`
- `apps/api/prisma/migrations/20240305000000_init/migration.sql`

### Apps: worker
- `apps/worker/package.json` — BullMQ, ioredis
- `apps/worker/tsconfig.json`
- `apps/worker/.eslintrc.cjs`
- `apps/worker/vitest.config.ts`
- `apps/worker/src/index.ts` — Redis connection, BullMQ queue + placeholder processor, shutdown

### Apps: mobile
- `apps/mobile/package.json` — placeholder scripts for CI
- `apps/mobile/README.md` — Phase 13 placeholder

## Files Modified

None (greenfield).

## Repository Tree (Overview)

```
apps/
  api/          NestJS, /health, /docs (Swagger), Prisma, Zod
  worker/       BullMQ + Redis, placeholder job
  mobile/       Placeholder (Phase 13)
packages/
  contracts/    Zod, enums, HealthResponseSchema, tests
  engine-rules/ training + nutrition placeholders, tests
docs/
  ARCHITECTURE.md, CODING_RULES.md, ENGINE_RULES.md,
  PHASES.md, DECISIONS.md, PHASE_1_SUMMARY.md
.github/workflows/
  ci.yml
scripts/
  bootstrap_github_repo.sh
```

## Commands to Run Locally

1. **Install** (from repo root):
   ```bash
   pnpm install
   ```
   If you see `ERR_PNPM_NO_OFFLINE_META`, run `pnpm store prune` or remove `node_modules` and try again.

2. **Build**:
   ```bash
   pnpm run build
   ```

3. **Lint**:
   ```bash
   pnpm run lint
   ```

4. **Typecheck**:
   ```bash
   pnpm run typecheck
   ```

5. **Tests**:
   ```bash
   pnpm run test
   ```
   or
   ```bash
   pnpm run test:ci
   ```

6. **API** (from repo root or apps/api):
   - Set `DATABASE_URL` (PostgreSQL) in `apps/api/.env`
   - `pnpm --filter @pipos/api prisma:generate`
   - `pnpm --filter @pipos/api prisma:migrate` (first time)
   - `pnpm --filter @pipos/api start:dev`
   - Health: GET http://localhost:3000/health
   - Swagger: http://localhost:3000/docs

7. **Worker** (optional):
   - Set `REDIS_URL` (default redis://localhost:6379)
   - `pnpm --filter @pipos/worker build && pnpm --filter @pipos/worker start`

## Bootstrap GitHub Repo

1. Set `REPO_NAME` (e.g. `pipos-fitness`). Optionally `GITHUB_OWNER`.
2. From repo root (Git Bash or WSL on Windows):
   ```bash
   bash scripts/bootstrap_github_repo.sh
   ```
3. Requires: `git`, `gh` (GitHub CLI), and `gh auth login` completed.

## Intentionally Not Implemented (Phase 1)

- Authentication (Phase 2)
- Exercise catalog (Phase 3)
- Training/nutrition engine logic (Phases 4, 7)
- Plan versioning (Phase 5)
- Workout tracking (Phase 6)
- Analytics, AI assistant, notifications, billing (Phases 8–11)
- Observability / Sentry (Phase 12)
- Flutter app (Phase 13)
- Production release (Phase 14)
- Sentry or other observability

## Known Limitations / TODOs

- **Tag**: Create git tag `phase-1-foundations` after first commit and push (manual or in bootstrap script).
- **API**: No global validation pipe on body (Zod validation is via `ZodValidationInterceptor` and `@ZodBody(schema)` on routes that have a body).
- **Worker**: No real jobs; placeholder processor only.
- **Mobile**: No Flutter project yet; only placeholder package and README.
- **CI**: Runs on clean runner; if local `pnpm install` fails due to cache, use `pnpm store prune` or a fresh clone.

## Next Recommended Steps

1. Run `pnpm install` (and fix cache if needed).
2. Run build, lint, typecheck, test locally.
3. Optionally run bootstrap script to create GitHub repo and push.
4. Create tag: `git tag phase-1-foundations && git push origin phase-1-foundations`.
5. Proceed to Phase 2 (Authentication & User Core) when ready.
