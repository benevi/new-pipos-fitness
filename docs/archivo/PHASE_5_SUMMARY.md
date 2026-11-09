# Phase 5 — Training Plan Generation and Versioning — Summary

## Files created

- **apps/api/prisma:** (migration to be created by user) — Schema changes for TrainingPlan, TrainingPlanVersion, TrainingSession, TrainingSessionExercise.
- **apps/api/src/modules/training-plans/training-plans.module.ts**
- **apps/api/src/modules/training-plans/training-plans.service.ts**
- **apps/api/src/modules/training-plans/training-plans.controller.ts**
- **apps/api/src/modules/training-plans/training-plans.service.spec.ts**
- **apps/api/src/modules/training-plans/training-plans.controller.spec.ts**
- **packages/contracts:** New schemas in `training-engine.ts`: `TrainingSessionExerciseSchema`, `TrainingSessionSchema`, `TrainingPlanVersionSchema`, `GenerateTrainingPlanResponseSchema` (and types). New tests in `training-engine.test.ts` for Phase 5 API schemas.

## Files modified

- **apps/api/prisma/schema.prisma** — Added User.trainingPlans; added TrainingPlan, TrainingPlanVersion, TrainingSession, TrainingSessionExercise with relations and indexes.
- **apps/api/package.json** — Added dependency `@pipos/engine-rules`: `workspace:*`.
- **apps/api/src/app.module.ts** — Imported and registered `TrainingPlansModule`.
- **packages/contracts/src/schemas/training-engine.ts** — Added response/version/session schemas.
- **packages/contracts/src/schemas/training-engine.test.ts** — Added tests for GenerateTrainingPlanResponseSchema and TrainingSessionExerciseSchema.
- **docs/ARCHITECTURE.md** — Added section “Training Plan Versioning”.
- **docs/FUTURE_TASKS.md** — Recorded Phase 5 as done.

## Database (Prisma) changes

- **TrainingPlan:** id (uuid), userId (FK User), createdAt, currentVersionId (optional FK TrainingPlanVersion).
- **TrainingPlanVersion:** id, planId (FK TrainingPlan), version (int), createdAt, engineVersion, objectiveScore. Unique (planId, version). Index on planId.
- **TrainingSession:** id, planVersionId (FK TrainingPlanVersion), sessionIndex, name, targetDurationMinutes. Index on planVersionId.
- **TrainingSessionExercise:** id, sessionId (FK TrainingSession), exerciseId, sets, repRangeMin, repRangeMax, restSeconds, rirTarget. Index on sessionId.
- **User:** added relation `trainingPlans TrainingPlan[]`.

## API endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST   | /training-plans/generate | JWT | Generate new plan version; create plan if none; persist version + sessions + exercises; set currentVersionId. Returns plan + version. |
| GET    | /training-plans/current  | JWT | Return latest plan snapshot (plan + current version with sessions and exercises). 404 if no plan or no current version. |
| GET    | /training-plans/versions | JWT | Return list of versions (id, planId, version, createdAt, engineVersion, objectiveScore). |
| GET    | /training-plans/versions/:id | JWT | Return specific version with sessions and exercises. 404 if not found or not owned. |

## Example plan snapshot (response shape)

```json
{
  "plan": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "userId": "550e8400-e29b-41d4-a716-446655440001",
    "createdAt": "2025-01-01T00:00:00.000Z",
    "currentVersionId": "550e8400-e29b-41d4-a716-446655440002"
  },
  "version": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "planId": "550e8400-e29b-41d4-a716-446655440000",
    "version": 1,
    "createdAt": "2025-01-01T00:00:00.000Z",
    "engineVersion": "0.0.1",
    "objectiveScore": 0.8,
    "sessions": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440003",
        "planVersionId": "550e8400-e29b-41d4-a716-446655440002",
        "sessionIndex": 0,
        "name": "Day 1",
        "targetDurationMinutes": 45,
        "exercises": [
          {
            "id": "550e8400-e29b-41d4-a716-446655440004",
            "sessionId": "550e8400-e29b-41d4-a716-446655440003",
            "exerciseId": "ex1",
            "sets": 3,
            "repRangeMin": 8,
            "repRangeMax": 12,
            "restSeconds": 90,
            "rirTarget": 2
          }
        ]
      }
    ]
  }
}
```

## Commands to run

```bash
# Install dependencies (including engine-rules in api)
pnpm install

# Generate Prisma client after schema change
cd apps/api && pnpm prisma generate

# Create and apply migration (dev)
pnpm prisma migrate dev --name add-training-plans

# Lint / typecheck / test
pnpm lint
pnpm typecheck
pnpm test
```

## Known limitations

- No workout tracking or completion data; plan is generated from user preferences and catalog only.
- No pagination on GET /training-plans/versions (list can grow; pagination can be added later).
- Plan generation does not reject when engine returns constraint violations; snapshot is stored regardless (violations are in engine metadata only).
- User preferences: `minutesPerSession` is defaulted to 45 in the service if not stored on user; `dislikedExerciseIds` is not yet stored on user (not in Phase 2.1 profile).

## Git tag

When Phase 5 is complete and verified:

```bash
git tag phase-5-plan-generation
```

Do not push automatically.
