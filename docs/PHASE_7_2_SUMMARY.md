# Phase 7.2 — Final Integrity Pass — Summary

## Scope

No new product features. Architectural integrity only: planVersionId on WorkoutSession, adherence from direct version linkage, hardened set-logging ownership, documentation.

## Files modified

- **apps/api/prisma/schema.prisma** — WorkoutSession.planVersionId (nullable FK to TrainingPlanVersion), relation, @@index([planVersionId]).
- **apps/api/src/modules/workouts/workouts.service.ts** — startSession: resolve TrainingSession.planVersionId when planSessionId provided, store on WorkoutSession; logSet: full ownership chain (session for user, exercise in session).
- **apps/api/src/modules/workouts/workouts.e2e-spec.ts** — Start with/without planSessionId (planVersionId); 404 for non-existent workoutExerciseId; 403 for other user’s session.
- **apps/api/src/modules/analytics/analytics.service.ts** — Adherence from WorkoutSession.planVersionId only; planned sets from exact TrainingPlanVersion per workout; null planVersionId does not contribute.
- **apps/api/src/modules/analytics/analytics.e2e-spec.ts** — Adherence tests: no workouts, one version, two versions in same week, null planVersionId; trainingPlanVersion mock.
- **packages/contracts/src/schemas/workouts.ts** — WorkoutSessionSchema.planVersionId (nullable uuid).
- **packages/contracts/src/schemas/workouts.test.ts** — WorkoutSession test payload includes planVersionId.
- **docs/ARCHITECTURE.md** — WorkoutSession.planVersionId, adherence tied to versioned workouts, set-logging ownership and why sets are on WorkoutExercise.
- **docs/PHASE_7_2_SUMMARY.md** — This file.

## Prisma schema changes

- **WorkoutSession:** `planVersionId String?` (FK to TrainingPlanVersion, `onDelete: SetNull`). Relation `planVersion TrainingPlanVersion? @relation(...)`. `@@index([planVersionId])`.
- **TrainingPlanVersion:** `workoutSessions WorkoutSession[]`.

## Adherence logic change

- **Before:** Inferred “most frequent planVersionId” in the last 7 days (ambiguous).
- **After:** For each completed workout in the window, use `WorkoutSession.planVersionId` directly. If non-null, resolve that TrainingPlanVersion and add its total planned sets (cached by version id) to the week’s planned sets. Workouts with null planVersionId do not contribute to planned-set adherence. No inference; each workout is tied to exactly one version or none.

## Set logging ownership

- **Checks:** (1) Workout session exists and belongs to authenticated user → 404 if not found, 403 if wrong user. (2) Workout exercise exists, belongs to the session from the route, and session belongs to user → 404 "Workout exercise not found" if missing or mismatched (no leak).
- **Endpoint:** Unchanged — `POST /workouts/:id/exercises/:workoutExerciseId/sets`.
- **Documented:** Sets are attached to WorkoutExercise (not catalog Exercise) because sets are per instance within a workout; same catalog exercise can appear in multiple workouts with different set logs.

## Example WorkoutSession (with planVersionId)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "user-1",
  "planSessionId": "ts-uuid",
  "planVersionId": "pv-uuid",
  "startedAt": "2025-03-07T10:00:00.000Z",
  "completedAt": "2025-03-07T10:45:00.000Z",
  "durationMinutes": 45,
  "notes": null
}
```

When started without a plan: `planSessionId` and `planVersionId` are null.

## Known limitations

- No backfill of `planVersionId` for existing WorkoutSessions that have `planSessionId` (optional follow-up migration or one-off script).
- Adherence uses version’s total planned sets per linked workout; if the same version has multiple sessions per week, each completed workout adds the full version total (design choice for Phase 7.2).

## Commands

- Migrations: from repo root, `cd apps/api && pnpm prisma migrate dev --name phase-7-2-plan-version-id`.
- Lint/typecheck/test: `pnpm lint`, `pnpm typecheck`, `pnpm test`.
- Tag: `git tag phase-7-2-final-integrity-pass` (do not push).
