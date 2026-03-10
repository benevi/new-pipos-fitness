# Phase 12.1 — Dashboard Hardening

## Goal

Improve dashboard data consistency, architecture clarity, and display quality. No new features.

## Files Created

- `apps/mobile/lib/models/muscle.dart` — Freezed model for Muscle (id, name, region, meshRegionId)
- `apps/mobile/lib/features/dashboard/muscle_catalog_provider.dart` — AsyncNotifier fetching `GET /muscles`, builds `Map<String, Muscle>`, keepAlive
- `apps/mobile/lib/features/dashboard/dashboard_provider.dart` — `DashboardViewModel` + `dashboardProvider` composing all data sources
- `apps/mobile/lib/features/dashboard/widgets/dashboard_summary_card.dart` — Reusable metric card widget
- `apps/mobile/lib/features/dashboard/widgets/fatigue_banner.dart` — Fatigue status banner widget
- `apps/mobile/lib/features/dashboard/widgets/progress_list_item.dart` — Exercise progress row widget
- `apps/mobile/lib/features/dashboard/widgets/volume_summary_card.dart` — Weekly volume card widget
- `docs/PHASE_12_1_SUMMARY.md`

## Files Modified

- `apps/mobile/lib/features/dashboard/dashboard_screen.dart` — Rewritten to consume `DashboardViewModel`, uses extracted widgets
- `apps/mobile/test/features/dashboard/dashboard_state_test.dart` — Comprehensive tests for VM composition, empty-state, partial data, catalogs
- `docs/ARCHITECTURE.md` — Added Phase 12.1 section

## Dashboard Provider Architecture

```
progressProvider ──┐
volumeProvider ────┤
exerciseCatalog ───┼──> dashboardProvider (Provider<DashboardViewModel>)
muscleCatalog ─────┘
```

- `dashboardProvider` is a synchronous `Provider` that watches all four async providers via `.valueOrNull`
- Produces a single `DashboardViewModel` with pre-resolved display names and computed totals
- Dashboard screen only renders the ViewModel — no data-composition logic in UI

## Muscle Catalog Provider

- `muscleCatalogProvider` — `AsyncNotifier<Map<String, Muscle>>`
- Fetches `GET /muscles`, maps `muscleId → Muscle`
- `muscleName(catalog, muscleId)` helper resolves display name or falls back to ID
- `keepAlive()` for session caching

## Empty-State Logic Change

**Before:** Empty when `progress == null || progress.exercises.isEmpty`

**After:** Empty only when ALL of:
- No exercise progress data
- No volume data (byExercise and byMuscle both empty)
- No adherenceScore

Any meaningful analytics data renders the dashboard normally.

## Partial-Data Rendering

| Scenario | Behavior |
|----------|----------|
| Progress loads, volume fails | Summary cards + exercise list shown; volume card hidden |
| Volume loads, progress fails | Volume card shown; summary shows defaults |
| Catalogs unavailable | Exercise/muscle IDs shown as fallback |
| Some fields null | Graceful omission (no crash) |

## Known Limitations

- Muscle names depend on `GET /muscles` availability; fallback to IDs
- No historical volume comparison
- Dashboard refreshes progress + volume but not catalogs (already keepAlive)
- ViewModel recomputes on every provider change (lightweight, no caching needed)
