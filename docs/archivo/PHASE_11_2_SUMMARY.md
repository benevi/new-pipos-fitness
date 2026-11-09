# Phase 11.2 — Workout Resume Integrity

## Goal

Ensure workout sessions can always be resumed correctly and that partially-created sessions cannot leave the system in inconsistent states.

## Files Created

- `docs/PHASE_11_2_SUMMARY.md`

## Files Modified

- `apps/api/src/modules/workouts/workouts.controller.ts` — Added `GET /workouts/:id` endpoint
- `apps/api/src/modules/workouts/workouts.service.ts` — Added `getById()` method returning full session with exercises and sets
- `apps/mobile/lib/features/workouts/workout_session_provider.dart` — Full rewrite: async `resumeWorkout(sessionId)`, `retryAddExercises()`, `_computeResumeIndex()`, multi-session guard, fixed response parsing
- `apps/mobile/lib/features/workouts/workouts_screen.dart` — Resume uses session ID + async fetch, retry button for failed exercise initialization
- `apps/mobile/lib/features/workouts/workout_player_screen.dart` — Robust exercise lookup by `order` field
- `apps/mobile/test/features/workouts/workout_session_provider_test.dart` — Extended with resume, retry, multi-session, duplicate-set tests

## Resume Workflow

1. WorkoutsScreen calls `checkForActiveWorkout()` on load
2. Fetches `GET /workouts/history`, filters `completedAt == null`, picks most recent
3. Warns in debug if multiple incomplete sessions exist
4. Shows resume dialog → on confirm calls `resumeWorkout(sessionId)`
5. `resumeWorkout` fetches `GET /workouts/:id` for the full session with all exercises and sets
6. `_computeResumeIndex()` finds the first exercise with no logged sets to position the player correctly
7. State becomes active with `resumedSession: true` and correct `currentExerciseIndex`

## Retry Initialization Logic

1. If atomic start succeeds at `POST /workouts/start` but fails adding exercises, state becomes `error` with session + planSession preserved
2. UI shows "Retry" button
3. `retryAddExercises()` fetches current session via `GET /workouts/:id`
4. Determines which plan exercises are missing from the server's exercise list
5. Adds only the missing exercises, not all
6. On success → state becomes active; on failure → remains error

## Multiple-Session Guard

- History is ordered by `startedAt` desc — first incomplete session is most recent
- `debugPrint` warning if more than one incomplete session exists
- Only the most recent is offered for resume

## State Restoration

- Full session fetched from `GET /workouts/:id` includes all exercises with their logged sets
- `currentExerciseIndex` computed by `_computeResumeIndex`: first exercise with empty sets, or last exercise if all have sets
- `resumedSession` flag set to `true`

## Response Parsing Fix

- `logSet` and `addExercise` backend endpoints return the full `WorkoutSession` (not individual entities)
- Provider now parses responses as `WorkoutSession.fromJson` correctly

## Known Limitations

- Resume does not recover planSession — plan-specific targets not shown for resumed workouts
- No server-side cleanup for abandoned incomplete sessions
- Multiple incomplete sessions: only most recent resumed; older ones remain on server
- `GET /workouts/:id` does not check `completedAt` — allows fetching completed sessions too (by design)
