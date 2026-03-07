# Phase 6 — Workout Tracking — Summary

## Files created

- **apps/api/prisma/schema.prisma** — Added WorkoutSession, WorkoutExercise, WorkoutSet models (migration to be created by user).
- **apps/api/src/modules/workouts/workouts.module.ts**
- **apps/api/src/modules/workouts/workouts.service.ts**
- **apps/api/src/modules/workouts/workouts.controller.ts**
- **apps/api/src/modules/workouts/workouts.e2e-spec.ts**
- **packages/contracts/src/schemas/workouts.ts**
- **packages/contracts/src/schemas/workouts.test.ts**
- **docs/PHASE_6_SUMMARY.md** (this file).

## Files modified

- **apps/api/prisma/schema.prisma** — User.workoutSessions; TrainingSession.workoutSessions; added WorkoutSession, WorkoutExercise, WorkoutSet with relations and indexes.
- **apps/api/src/app.module.ts** — Imported and registered WorkoutsModule.
- **packages/contracts/src/schemas/index.ts** — Export workouts.
- **docs/ARCHITECTURE.md** — Added section "Workout Tracking".
- **docs/FUTURE_TASKS.md** — Phase 6 done; recorded nutrition, analytics, AI assistant, notifications, Flutter UI as future.

## Database (Prisma) schema

- **WorkoutSession:** id (uuid), userId (FK User), planSessionId (optional FK TrainingSession, onDelete SetNull), startedAt (default now()), completedAt (nullable), durationMinutes (nullable), notes (nullable). Indexes: userId, planSessionId.
- **WorkoutExercise:** id, workoutSessionId (FK WorkoutSession, onDelete Cascade), exerciseId (string), order (int). Index: workoutSessionId.
- **WorkoutSet:** id, workoutExerciseId (FK WorkoutExercise, onDelete Cascade), setIndex (int), weightKg (float nullable), reps (int nullable), rir (int nullable), completed (boolean default true). Index: workoutExerciseId.

## API endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /workouts/history | JWT | Recent workout sessions for current user (up to 50). |
| POST | /workouts/start | JWT | Start workout session. Body: `planSessionId` (optional). Returns WorkoutSession. |
| POST | /workouts/:id/exercises | JWT | Add exercise to workout. Body: `exerciseId`. Returns full WorkoutSession. |
| POST | /workouts/:id/exercises/:exerciseId/sets | JWT | Log a set. Body: `weightKg`, `reps`, `rir`, `completed` (all optional). Returns full WorkoutSession. |
| POST | /workouts/:id/finish | JWT | Finish session. Body: `durationMinutes`, `notes` (optional). Returns WorkoutSession. |

## Example workout log (response shape)

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "userId": "550e8400-e29b-41d4-a716-446655440001",
  "planSessionId": "550e8400-e29b-41d4-a716-446655440002",
  "startedAt": "2025-03-07T10:00:00.000Z",
  "completedAt": "2025-03-07T10:45:00.000Z",
  "durationMinutes": 45,
  "notes": "Felt strong",
  "exercises": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440003",
      "workoutSessionId": "550e8400-e29b-41d4-a716-446655440000",
      "exerciseId": "ex-bench-press",
      "order": 0,
      "sets": [
        {
          "id": "550e8400-e29b-41d4-a716-446655440004",
          "workoutExerciseId": "550e8400-e29b-41d4-a716-446655440003",
          "setIndex": 0,
          "weightKg": 80,
          "reps": 10,
          "rir": 2,
          "completed": true
        },
        {
          "id": "550e8400-e29b-41d4-a716-446655440005",
          "workoutExerciseId": "550e8400-e29b-41d4-a716-446655440003",
          "setIndex": 1,
          "weightKg": 80,
          "reps": 8,
          "rir": 1,
          "completed": true
        }
      ]
    }
  ]
}
```

## Known limitations

- No pagination on GET /workouts/history (fixed limit 50).
- exerciseId in WorkoutExercise is a string; no FK to Exercise catalog (allows flexibility; validation can be added later).
- No edit/delete of sessions, exercises, or sets once created (append-only).
- No validation that exerciseId exists in catalog when adding to workout.

## Commands to run

```bash
pnpm install
cd apps/api && pnpm prisma generate
pnpm prisma migrate dev --name add-workout-tracking
pnpm lint
pnpm typecheck
pnpm test
```

## Git tag

```bash
git tag phase-6-workout-tracking
```

Do not push automatically.
