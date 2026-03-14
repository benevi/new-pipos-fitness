# Phase 15.1 — Catalog Hardening

## Summary

Catalog hardening only: no new product features. Exercise catalog is made robust with muscle filter end-to-end, decoupled media fetch, muscle catalog resolution, and stable behavior under partial failures.

## Files Created

- **apps/mobile/lib/features/exercises/exercise_media_provider.dart** — `AsyncNotifierProvider.family<ExerciseMediaNotifier, List<ExerciseMedia>, String>`. Fetches `GET /exercises/:id/media` only; used by detail screen for the Videos section.
- **apps/mobile/test/features/exercises/exercise_media_provider_test.dart** — Tests: empty exerciseId, success with list, null response, API error.

## Files Modified

- **apps/mobile/lib/features/exercises/exercise_detail_screen.dart** — Detail content uses `exerciseMediaProvider(exerciseId)` for Videos section (loading / error / data). Uses `muscleCatalogProvider` and `muscleName(muscleCatalog, em.muscleId)` for muscle labels. Added `_NoVideoCard`, `_MediaErrorCard`. `_ExerciseDetailContent` is now a `ConsumerWidget` and takes `exerciseId`.
- **apps/mobile/lib/features/exercises/widgets/exercise_filter_bar.dart** — Added muscle filter: `_MuscleChip` and `_showMuscleMenu`. Muscle list from `muscleCatalogProvider`; bottom sheet with “Any muscle” + sorted muscles; if catalog fails or is empty, sheet shows “Could not load muscles”. Uses `muscleCatalogProvider` and `Muscle` import.a
- **apps/mobile/test/features/exercises/exercise_detail_screen_test.dart** — Fakes now distinguish detail vs media: `_FakeDetailAndMediaApi` with `detailResponse`, `mediaResponse`, `mediaFails`. Tests: media empty, media present, detail visible when media fails (“Couldn’t load videos”).

## Backend Muscle Filter

- **No backend change.** `GET /exercises` already supports `muscleId` via `ExerciseFilterQuerySchema` and `exercises.service.ts` (`where.muscles = { some: { muscleId } }`).
- Mobile already sent `muscleId` in `toQueryParams`; the filter bar did not expose it. Phase 15.1 adds the muscle filter UI and keeps using the same API.

## Exercise Media Provider

- **exerciseMediaProvider(exerciseId)** — Family async notifier. Calls `GET /exercises/:id/media`. Returns `List<ExerciseMedia>`. Backend returns only approved media; no client-side curation filter.
- Detail screen no longer uses `detail.media` from `GET /exercises/:id`. It only uses this provider for the Videos section, so:
  - Detail can load and render even if the media request fails.
  - Media section has its own loading, error (with retry), and empty states.

## Muscle Catalog Resolution

- **Reused** existing `muscleCatalogProvider` from `lib/features/dashboard/muscle_catalog_provider.dart` (GET /muscles → `Map<String, Muscle>`; `muscleName(catalog, id)` for fallback).
- **Detail screen:** Muscle labels use `em.muscle?.name ?? muscleName(muscleCatalog, em.muscleId)` so backend-embedded muscle is preferred, then catalog, then raw id.
- **Filter bar:** Muscle chip and muscle menu use `muscleCatalogProvider`. Chip label is “Muscle” or the selected muscle name from the catalog; if catalog fails, sheet shows “Could not load muscles” and no selection is applied.

## Partial-Failure Behavior

- **Detail succeeds, media fails:** Detail (name, description, muscles, etc.) is shown; Videos section shows “Couldn’t load videos” and Retry (invalidates `exerciseMediaProvider`).
- **Detail succeeds, muscle catalog fails:** Muscles still shown via `em.muscle` from detail response or raw `em.muscleId`.
- **Detail succeeds, media empty:** Videos section shows “No video available yet”.
- **Filters return no exercises:** Unchanged; empty state and “Clear filters” in list screen.
- Defensive handling lives in providers and screen composition (separate async for detail vs media); widgets assume data can be missing.

## Known Limitations

- Muscle filter sheet shows “Could not load muscles” if catalog fails; user cannot filter by muscle until catalog loads.
- Equipment names are not resolved in this feature (no equipment filter or display in catalog).
- Backend `findOne` still returns media; mobile simply does not use it for the Videos section.

## Commands

```bash
cd apps/mobile
flutter analyze
flutter test
```

No `build_runner` required for this phase.

## Git Tag

```bash
git tag phase-15-1-catalog-hardening
```

(Do not push automatically.)
