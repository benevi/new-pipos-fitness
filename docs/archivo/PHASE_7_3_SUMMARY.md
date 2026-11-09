# Phase 7.3 — Adherence Calculation Fix — Summary

## Scope

No new product features. Correct adherence metric so planned sets are not over-counted.

## Files modified

- **apps/api/src/modules/analytics/analytics.service.ts** — Adherence uses session-level planned sets (TrainingSession → TrainingSessionExercise); only workouts with planSessionId in last 7 days; completed sets only from those workouts.
- **apps/api/src/modules/analytics/analytics.e2e-spec.ts** — Mock trainingSession.findUnique; tests: single workout + TrainingSession, multiple workouts different sessions, workout without planSessionId ignored, incomplete sets, mixed completed/incomplete; assert 0 ≤ adherence ≤ 1.
- **docs/ARCHITECTURE.md** — Adherence described as session-based; TrainingSession planned sets; workouts without planSessionId excluded.
- **docs/PHASE_7_3_SUMMARY.md** — This file.

## Corrected adherence formula

- **Window:** Last 7 days; only completed WorkoutSessions with `planSessionId != null`.
- **Planned sets:** For each such workout, resolve TrainingSession by `planSessionId`; add `sum(TrainingSessionExercise.sets)` for that session. Cached by planSessionId. Total planned = sum over all such workouts.
- **Completed sets:** Count of WorkoutSet with `completed = true` in those same workouts.
- **Adherence:** `completedSets / plannedSets`, clamped to [0, 1] by engine-rules `computeAdherence`; null if plannedSets ≤ 0.

## Example adherence calculation

- Last 7 days: 2 workouts.
  - Workout A: planSessionId = ts-1. TrainingSession ts-1 has 3 planned sets (e.g. one exercise, sets: 3). User completed 2 sets.
  - Workout B: planSessionId = ts-2. TrainingSession ts-2 has 4 planned sets. User completed 4 sets.
- Planned = 3 + 4 = 7. Completed = 2 + 4 = 6. Adherence = 6/7 ≈ 0.857.

## Known limitations

- Workouts without planSessionId do not contribute to adherence (excluded by design).
- Same TrainingSession (same planSessionId) used in multiple workouts in the window each adds that session’s planned sets once per workout instance (correct per-session semantics).

## Tests added

1. Single workout with linked TrainingSession — planned from that TrainingSession, adherence 2/3, score in [0,1].
2. Multiple workouts with different TrainingSessions — no over-count; adherence 5/7.
3. Workout without planSessionId — ignored; adherence null.
4. Workout with incomplete sets — only completed count; adherence 1/3.
5. Mixed completed and incomplete — adherence 2/3, in [0,1].

## Git tag

`git tag phase-7-3-adherence-fix` (do not push automatically).
