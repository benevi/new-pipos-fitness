# Phase 7.1 — Architecture Hardening — Summary

## Scope

No new product features. Architectural integrity and correctness only.

## Files created

- **docs/PHASE_7_1_SUMMARY.md** (this file).

## Files modified

- **apps/api/prisma/schema.prisma** — ExerciseProgress.volumeTrend → VolumeTrend enum; WorkoutExercise.exerciseId → FK Exercise; added enum VolumeTrend; added indexes/unique constraints (see below).
- **apps/api/src/modules/training-plans/training-plans.service.ts** — Reject invalid plans (400 + violations); do not persist when constraintViolations.length > 0.
- **apps/api/src/modules/training-plans/training-plans.service.spec.ts** — Mock AnalyticsService and engine; tests for invalid plan rejection.
- **apps/api/src/modules/workouts/workouts.service.ts** — Validate exercise exists (FK) in addExercise; logSet by workoutExerciseId.
- **apps/api/src/modules/workouts/workouts.controller.ts** — Path param :workoutExerciseId for log set.
- **apps/api/src/modules/workouts/workouts.e2e-spec.ts** — Use workoutExerciseId in set endpoint; mock exercise.findUnique.
- **apps/api/src/modules/analytics/analytics.service.ts** — Comment: ExerciseProgress derived; adherence from plan version used that week (planSession → planVersionId).
- **packages/engine-rules/src/training/adaptation.ts** — Localized adaptation: reduce sets only for exercises targeting fatigued muscles (catalog); low adherence still reduces all.
- **packages/engine-rules/src/training/adaptation.test.ts** — Localized tests; catalog and fatigue by muscle.
- **packages/engine-rules/src/training/engine.ts** — Pass catalog to adaptPlanToProgress.
- **docs/ARCHITECTURE.md** — ExerciseProgress as derived; adaptation localized; workout set endpoint and exerciseId FK.
- **docs/ENGINE_RULES.md** — Phase 7.1 localized adaptation.

## Prisma schema changes

- **Enum:** `VolumeTrend { up, down, stable }`. `ExerciseProgress.volumeTrend` type changed from `String?` to `VolumeTrend?`.
- **WorkoutExercise:** `exerciseId` now FK to `Exercise` (relation `exercise`), `onDelete: Restrict`. `Exercise` has `workoutExercises WorkoutExercise[]`.
- **Indexes / unique:**
  - `TrainingSession`: `@@unique([planVersionId, sessionIndex])`.
  - `WorkoutSession`: `@@index([userId, startedAt])`.
  - `WorkoutExercise`: `@@unique([workoutSessionId, order])`.
  - `WorkoutSet`: `@@unique([workoutExerciseId, setIndex])`.
  - `ExerciseProgress`: `@@index([userId, lastUpdated])`.
- **Note:** `TrainingPlan` already had `@@index([userId])`.

## Engine adaptation

- **Before:** Global reduction: when fatigue or low adherence, reduce sets for every exercise.
- **After:** Localized: identify fatigued muscles from progress.exerciseHistory (fatigueScore > 0.5) and catalog ExerciseMuscle; reduce sets only for plan exercises that target those muscles. Low adherence (adherenceScore < 0.7) still triggers global set reduction. Deterministic.

## API endpoint changes

| Before | After |
|--------|--------|
| `POST /workouts/:id/exercises/:exerciseId/sets` | `POST /workouts/:id/exercises/:workoutExerciseId/sets` |

- **addExercise:** `exerciseId` must exist in catalog (Exercise); 404 if not found.
- **logSet:** Uses `workoutExerciseId` (WorkoutExercise.id); 404 if workout exercise not found or not in session.

## Example invalid plan response (400)

```json
{
  "statusCode": 400,
  "code": "PLAN_CONSTRAINT_VIOLATIONS",
  "message": "Training plan has constraint violations",
  "constraintViolations": [
    {
      "code": "SESSION_DURATION_EXCEEDED",
      "message": "Session 0 estimated 60 min > 45 min"
    }
  ]
}
```

## Adherence calculation

- **Before:** Planned sets from current plan version only.
- **After:** For the last 7 days, completed workout sessions with `planSessionId` are used to determine which TrainingPlanVersion was used that week (most frequent planVersionId). Planned sets = sum of sets from that version’s sessions. Regenerated plans do not corrupt metrics because adherence is tied to the version linked via workout’s plan session.

## Known limitations

- Workout sessions without `planSessionId` do not contribute to a version for adherence; if none have it, planned sets = 0 and adherence is null.
- Migration required: add VolumeTrend enum, FK WorkoutExercise→Exercise, new indexes/unique. Existing data: ensure all WorkoutExercise.exerciseId values exist in Exercise before applying FK.

## Commands to run migrations

```bash
cd apps/api
pnpm prisma migrate dev --name phase-7-1-hardening
```

Resolve any data conflicts (e.g. orphan workout exercises with invalid exerciseId) before migrating.

## Git tag

```bash
git tag phase-7-1-architecture-hardening
```

Do not push automatically.
