# Phase 12 — Progress Dashboard

## Goal

Build a real progress dashboard showing training progress, adherence, weekly volume, and fatigue signals using existing analytics endpoints.

## Files Created

- `apps/mobile/lib/models/volume_metrics.dart` — Freezed models: VolumeMetrics, VolumeByExercise, VolumeByMuscle
- `apps/mobile/lib/features/dashboard/volume_provider.dart` — AsyncNotifier for `GET /analytics/volume`, keepAlive
- `apps/mobile/test/features/dashboard/dashboard_state_test.dart` — Unit tests for models, rendering logic, parsing
- `docs/PHASE_12_SUMMARY.md`

## Files Modified

- `apps/mobile/lib/features/dashboard/dashboard_screen.dart` — Full rewrite: loading/error/empty states, pull-to-refresh, 4 dashboard sections
- `docs/ARCHITECTURE.md` — Added Phase 12 section

## Provider Architecture

| Provider | Type | Endpoint | Cache |
|----------|------|----------|-------|
| `progressProvider` | `AsyncNotifier<ProgressMetrics?>` | `GET /analytics/progress` | keepAlive |
| `volumeProvider` | `AsyncNotifier<VolumeMetrics?>` | `GET /analytics/volume` | keepAlive |
| `exerciseCatalogProvider` | `AsyncNotifier<Map<String, Exercise>>` | `GET /exercises` | keepAlive |

All three are composed in the dashboard screen. Pull-to-refresh triggers `refresh()` on progress and volume providers.

## Analytics Endpoints Used

- `GET /analytics/progress` — adherenceScore, fatigueDetected, per-exercise e1RM/volume/trend/fatigue
- `GET /analytics/volume` — weekly volume by exercise and by muscle

## Dashboard Sections

### Section 1 — Summary Cards
Three metric cards in a row: Adherence (%), Exercises (count), Fatigue (Yes/No). Color-coded by threshold.

### Section 2 — Exercise Progress List
Per-exercise rows showing: display name (from catalog), estimated 1RM, weekly volume, trend icon (up/down/flat), fatigue highlight when score > 50%.

### Section 3 — Weekly Volume Summary
Card with total volume, exercise count, muscle count. Muscle breakdown as chips.

### Section 4 — Fatigue Status
Banner card: green "No fatigue detected" or red "Fatigue detected" with contextual message.

## Known Limitations

- No charts or graphs — numeric values only
- Exercise and muscle names show IDs when catalog is not loaded
- No historical comparison (single-week snapshot)
- Volume by muscle shows muscleId, not display name (muscle catalog not yet on mobile)
- Empty state shown when exercises list is empty, even if adherenceScore exists
