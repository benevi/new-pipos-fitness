# Phase 3 — Exercise Catalog System Summary

## Objective

Create the curated exercise catalog: muscles, equipment, exercises with filtering and pagination, YouTube media, and basic admin CRUD. This catalog will feed the training engine in later phases.

## Files Created

### packages/contracts
- `src/schemas/catalog.ts` — Muscle, EquipmentItem, Exercise, ExerciseFilterQuery, ExerciseListResponse, ExerciseDetail, ExerciseMediaYouTube, CreateExerciseRequest, UpdateExerciseRequest, AddExerciseMediaRequest (Zod)
- `src/schemas/catalog.test.ts` — schema tests
- `src/enums/index.ts` — added MuscleRole, CurationStatus

### apps/api
- `src/modules/catalog/catalog.module.ts`
- `src/modules/catalog/muscles/muscles.module.ts`, `muscles.service.ts`, `muscles.controller.ts`
- `src/modules/catalog/equipment/equipment.module.ts`, `equipment.service.ts`, `equipment.controller.ts`
- `src/modules/catalog/exercises/exercises.module.ts`, `exercises.service.ts`, `exercises.controller.ts`
- `src/modules/catalog/admin/admin-catalog.module.ts`, `admin-catalog.service.ts`, `admin-catalog.controller.ts`
- `src/modules/catalog/catalog.e2e-spec.ts`
- `prisma/migrations/20240306000000_exercise_catalog/migration.sql`

## Files Modified

- `packages/contracts/src/enums/index.ts` — MuscleRole, CurationStatus
- `packages/contracts/src/schemas/index.ts` — export catalog
- `apps/api/prisma/schema.prisma` — Muscle, EquipmentItem, Exercise, ExerciseMuscle, ExerciseEquipment, ExerciseVariant, ExerciseMediaYouTube, YouTubeChannel, CurationStatus enum
- `apps/api/prisma/seed.ts` — seed muscles, equipment, exercises, exercise-muscle links, YouTube channel, example media
- `apps/api/src/app.module.ts` — import CatalogModule
- `docs/ARCHITECTURE.md` — Exercise Catalog System section
- `docs/FUTURE_TASKS.md` — Phase 3 task updated

## Database Schema Changes

### New models
- **Muscle:** id, name, region, meshRegionId
- **EquipmentItem:** id, name, category
- **Exercise:** id, slug (unique), name, description, difficulty, movementPattern, place (TrainingLocation)
- **ExerciseMuscle:** exerciseId, muscleId, role (composite PK); indexes on muscleId
- **ExerciseEquipment:** exerciseId, equipmentItemId (composite PK); index on equipmentItemId
- **ExerciseVariant:** id, exerciseId, variantExerciseId, reason
- **ExerciseMediaYouTube:** id, exerciseId, youtubeVideoId, channelName, isPrimary, startSeconds, endSeconds, curationStatus (enum)
- **YouTubeChannel:** id, channelName (unique), trustedScore, whitelisted

### New enum
- **CurationStatus:** approved, pending, rejected, unavailable

**Migration name:** `20240306000000_exercise_catalog`

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /muscles | List all muscles |
| GET | /equipment-items | List all equipment items |
| GET | /exercises | List exercises (filters: muscleId, equipmentId, difficulty, movementPattern, place, search; pagination: page, limit). Response: `{ items, page, limit, totalCount }` (Flutter-friendly). |
| GET | /exercises/:id | Exercise detail with muscles, variants, media |
| GET | /exercises/:id/media | Approved YouTube media for exercise |
| POST | /admin/exercises | Create exercise (admin) |
| PUT | /admin/exercises/:id | Update exercise (admin) |
| POST | /admin/exercises/:id/media | Add YouTube media (admin) |
| PUT | /admin/exercise-media/:id/approve | Approve media (admin) |
| PUT | /admin/exercise-media/:id/reject | Reject media (admin) |

## Commands to Run

```bash
pnpm install
pnpm run build
pnpm run lint
pnpm run typecheck
pnpm run test
```

From `apps/api`:
- Set `DATABASE_URL`
- `pnpm prisma:generate`
- `pnpm prisma:migrate` — apply migration
- `pnpm exec prisma db seed` — seed muscles, equipment, exercises, media

## Seed Instructions

1. Ensure migrations are applied: `pnpm prisma:migrate` (or deploy migration).
2. Run seed: `pnpm exec prisma db seed` (from repo root or from `apps/api`).
3. Seed creates: 9 muscles, 6 equipment items, 18 exercises, exercise–muscle links for bench-press and squat, one YouTube channel, one approved YouTube media for bench-press.

## Known Limitations

- Admin endpoints have no authentication (placeholder for future phase).
- Exercise list filter does not support multiple muscleIds/equipmentIds (single filter only).
- E2E tests mock Prisma; no in-CI database.
- Seed is idempotent for exercises (upsert by slug); media create is skipped if same video already exists for exercise.

## Intentionally Not Implemented

- Training engine, nutrition engine, analytics, AI assistant, notifications, billing, Flutter app, plan generation, tracking (later phases).
- Admin auth (recorded in FUTURE_TASKS).

## Git Tag

When Phase 3 is complete:

```bash
git tag phase-3-exercise-catalog
# Optional: git push origin phase-3-exercise-catalog
```
