# Phase 11.1 — Workout Hardening

## Goal

Make the workout experience robust and production-safe: atomic start, exercise catalog integration, and resume capability.

## Files Created

- `apps/mobile/lib/models/exercise.dart` — Freezed model for Exercise (id, slug, name, difficulty, movementPattern, place)
- `apps/mobile/lib/features/workouts/exercise_catalog_provider.dart` — AsyncNotifier that fetches and caches the full exercise catalog as `Map<String, Exercise>`
- `apps/mobile/test/features/workouts/exercise_catalog_provider_test.dart` — Tests for exerciseName helper

## Files Modified

- `apps/mobile/lib/features/workouts/workout_session_provider.dart` — Atomic start, `starting` status, `resumedSession` flag, `checkForActiveWorkout()`, `resumeWorkout()`
- `apps/mobile/lib/features/workouts/workouts_screen.dart` — Resume dialog on screen load, catalog-backed exercise chips, starting state indicator
- `apps/mobile/lib/features/workouts/workout_player_screen.dart` — Exercise names from catalog, support resumed workouts without planSession
- `apps/mobile/test/features/workouts/workout_session_provider_test.dart` — Tests for new statuses, atomic start states, resume state

## Atomic Start Logic

1. State transitions to `starting` (prevents double start)
2. `POST /workouts/start` creates session
3. `POST /workouts/:id/exercises` for each plan exercise
4. If step 3 fails: state → `error` with message, session preserved for potential retry
5. Only on full success: state → `active`

## Catalog Provider Architecture

- `exerciseCatalogProvider` — `AsyncNotifierProvider<ExerciseCatalogNotifier, Map<String, Exercise>>`
- Paginates through `GET /exercises` (limit=100) to build a complete id→Exercise map
- Uses `ref.keepAlive()` for cross-tab caching
- `exerciseName(catalog, exerciseId)` helper returns display name or exerciseId fallback

## Resume Workout Behavior

1. When WorkoutsScreen loads, calls `checkForActiveWorkout()`
2. Fetches `GET /workouts/history`, finds first session where `completedAt == null`
3. Shows dialog: "Resume previous workout?"
4. On confirm: `resumeWorkout(session)` sets state to active with `resumedSession: true`
5. Navigates to `/workout-player` with restored exercises and sets
6. Resumed workouts show exercises from workout session data (no planSession needed)

## Known Limitations

- Resume does not recover planSession reference — plan-specific targets (sets, reps, rest) not shown for resumed workouts
- No server-side abort/cleanup for partially-started workouts
- Exercise catalog fetches all exercises on app load; no incremental update
- No retry button in UI for failed exercise-add (user can re-tap Start Workout)
