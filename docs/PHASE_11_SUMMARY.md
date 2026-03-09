# Phase 11 — Workout Experience

## Goal

Implement the first real in-app experience: workout session flow allowing users to start a workout from their training plan, log sets for each exercise, and complete the session.

## Files Created

- `apps/mobile/lib/models/workout_session.dart` — Freezed models: WorkoutSession, WorkoutExercise, WorkoutSet
- `apps/mobile/lib/features/workouts/workout_session_provider.dart` — StateNotifier managing workout lifecycle
- `apps/mobile/lib/features/workouts/workout_player_screen.dart` — Active workout UI with exercise cards and set logging
- `apps/mobile/lib/features/workouts/workout_complete_screen.dart` — Post-workout summary screen
- `apps/mobile/test/features/workouts/workout_session_provider_test.dart` — Unit tests for provider state

## Files Modified

- `apps/mobile/lib/features/workouts/workouts_screen.dart` — Replaced placeholder with real training plan session list and start workout flow
- `apps/mobile/lib/app/router.dart` — Added `/workout-player` and `/workout-complete` routes outside ShellRoute (no bottom nav)

## Provider Architecture

- `workoutSessionProvider` — `StateNotifierProvider<WorkoutSessionNotifier, WorkoutSessionState>`
- State tracks: status (idle/active/finishing/completed/error), session data, plan session reference, current exercise index, error message
- Uses `ApiClient` directly for all backend calls
- Errors mapped via `mapDioException` → `ApiFailure`

## Workout Flow

1. User opens Workouts tab → `trainingPlanProvider` loads current plan
2. Sessions displayed as cards with exercise chips
3. User taps "Start Workout" → `POST /workouts/start` with planSessionId
4. All plan exercises added to workout via `POST /workouts/:id/exercises`
5. Workout player shows one exercise at a time with set input form
6. User logs sets → `POST /workouts/:id/exercises/:weId/sets`
7. UI updates immediately after each logged set
8. "Next" / "Prev" buttons navigate exercises
9. "Finish" on last exercise → `POST /workouts/:id/finish` with computed duration
10. Workout complete screen shows summary stats → "Back to Dashboard"

## API Endpoints Used

| Endpoint | Purpose |
|----------|---------|
| `GET /training-plans/current` | Load user's training plan |
| `POST /workouts/start` | Start workout session |
| `POST /workouts/:id/exercises` | Add exercise to workout |
| `POST /workouts/:id/exercises/:weId/sets` | Log a set |
| `POST /workouts/:id/finish` | Finish workout session |

## Routing

- `/workout-player` — Full-screen (outside ShellRoute, no bottom nav)
- `/workout-complete` — Full-screen summary
- Navigation: Workouts → Start → Player → Finish → Complete → Dashboard

## Known Limitations

- Exercise names show exerciseId (slug) — display names require exercise catalog integration
- No workout history view in this phase
- No rest timer between sets
- No offline support — all operations require network
- Leaving an active workout resets local state; sets already logged are saved server-side
- No duplicate workout prevention beyond local state guard
