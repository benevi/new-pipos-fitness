# Phase 7 — Progress Analytics and Weekly Adaptive Engine — Summary

## Files created

- **apps/api/src/modules/analytics/analytics.module.ts**
- **apps/api/src/modules/analytics/analytics.service.ts**
- **apps/api/src/modules/analytics/analytics.controller.ts**
- **apps/api/src/modules/analytics/analytics.e2e-spec.ts**
- **packages/contracts/src/schemas/analytics.ts**
- **packages/contracts/src/schemas/analytics.test.ts**
- **packages/engine-rules/src/training/progress.ts**
- **packages/engine-rules/src/training/progress.test.ts**
- **packages/engine-rules/src/training/adaptation.ts**
- **packages/engine-rules/src/training/adaptation.test.ts**
- **docs/PHASE_7_SUMMARY.md** (this file).

## Files modified

- **apps/api/prisma/schema.prisma** — User.exerciseProgress; added ExerciseProgress model and indexes.
- **apps/api/src/app.module.ts** — Imported AnalyticsModule.
- **apps/api/src/modules/training-plans/training-plans.module.ts** — Import AnalyticsModule.
- **apps/api/src/modules/training-plans/training-plans.service.ts** — Inject AnalyticsService; pass progress to generateTrainingPlan.
- **packages/contracts/src/schemas/index.ts** — Export analytics.
- **packages/contracts/src/schemas/training-engine.ts** — TrainingEngineProgressSchema, ExerciseHistoryItemSchema; progress optional on TrainingEngineInputSchema.
- **packages/engine-rules/src/training/engine.ts** — Call adaptPlanToProgress after improvePlan.
- **packages/engine-rules/src/training/index.ts** — Export progress and adaptation.
- **docs/ARCHITECTURE.md** — Added section "Adaptive Training Engine".
- **docs/FUTURE_TASKS.md** — Phase 7 done.

## Database (Prisma)

- **ExerciseProgress:** id (uuid), userId (FK User, onDelete Cascade), exerciseId (string), estimated1RM (float nullable), volumeLastWeek (float nullable), volumeTrend (string nullable), fatigueScore (float nullable), lastUpdated (default now()). Unique (userId, exerciseId). Index on userId.

## Analytics calculations

- **e1RM:** `weightKg * (1 + reps / 30)`; best per exercise from WorkoutSet data (engine-rules).
- **Weekly volume:** Per exercise: sum of weightKg × reps for completed sets; per muscle: from ExerciseMuscle mapping with role weight (primary 1, secondary 0.5, stabilizer 0.25).
- **Adherence:** `completed_sets / planned_sets` (planned from current plan version), clamped [0, 1].
- **Fatigue:** Detected when any set has `rir ≤ 0` or reps drop > 20% between consecutive sets (engine-rules).

## Engine integration

- **TrainingEngineInput.progress** (optional): exerciseHistory, weeklyVolume, adherenceScore, fatigueScore.
- **Adaptation:** After local search, `adaptPlanToProgress(plan, progress)` reduces each exercise’s sets by 1 (min 1) when fatigueScore > 0.5 or adherenceScore < 0.7; otherwise plan unchanged.

## API endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /analytics/progress | JWT | User exercise progress (e1RM, volume, trend, fatigue, adherence). |
| GET | /analytics/volume | JWT | Weekly volume by exercise and by muscle. |

## Example progress response

```json
{
  "exercises": [
    {
      "exerciseId": "ex-bench",
      "estimated1RM": 102.5,
      "volumeLastWeek": 4800,
      "volumeTrend": "up",
      "fatigueScore": 0,
      "lastUpdated": "2025-03-07T12:00:00.000Z"
    }
  ],
  "adherenceScore": 0.85,
  "fatigueDetected": false
}
```

## Known limitations

- Volume window is last 7 days; trend uses previous 7 days. No configurable date range.
- Planned sets for adherence come from current plan version only (same week structure assumed).
- Adaptation only reduces sets; no explicit “increase load” logic (engine does not prescribe weight).
- ExerciseProgress.volumeTrend stored as string; no enum in Prisma.

## Commands to run

```bash
pnpm install
cd apps/api && pnpm prisma generate
pnpm prisma migrate dev --name add-exercise-progress
pnpm lint
pnpm typecheck
pnpm test
```

## Git tag

```bash
git tag phase-7-adaptive-engine
```

Do not push automatically.
