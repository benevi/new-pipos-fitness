# Phase 15 — Exercise Catalog UI + Videos

## Summary

Production-grade exercise catalog in the Flutter app: browse, search, filter, exercise detail, and curated YouTube links via `url_launcher`. Uses existing backend `GET /exercises`, `GET /exercises/:id`, `GET /muscles`, `GET /equipment-items`. No plan editing, AI coach changes, or offline mode.

## Files Created

- **apps/mobile/lib/features/exercises/exercises_screen.dart** — Catalog screen: search, filter bar, list with refresh and pagination, loading/error/empty states.
- **apps/mobile/lib/features/exercises/exercise_detail_screen.dart** — Detail: name, description, metadata chips, muscles, videos section with fallback "No video available yet".
- **apps/mobile/lib/features/exercises/exercise_detail_provider.dart** — `AsyncNotifierProvider.family` for `GET /exercises/:id` → `ExerciseDetail`.
- **apps/mobile/lib/features/exercises/exercise_filters_provider.dart** — `NotifierProvider` for search, difficulty, place, muscleId; `toQueryParams(page, limit)` for API.
- **apps/mobile/lib/features/exercises/filtered_exercises_provider.dart** — `AsyncNotifierProvider`: watches filters, fetches paginated list, `refresh()` and `loadMore()`.
- **apps/mobile/lib/features/exercises/widgets/exercise_list_item.dart** — Card row: name + `ExerciseMetadataChips`, `InkWell` for tap.
- **apps/mobile/lib/features/exercises/widgets/exercise_filter_bar.dart** — Search field, place chips (All/Gym/Home/Calisthenics), difficulty bottom sheet.
- **apps/mobile/lib/features/exercises/widgets/exercise_metadata_chips.dart** — Difficulty, place, movement pattern chips.
- **apps/mobile/lib/features/exercises/widgets/exercise_video_card.dart** — Media card: label (channel or "Watch on YouTube"), tap opens YouTube via `url_launcher`.
- **apps/mobile/lib/models/exercise_detail.dart** — Freezed: Exercise fields + `muscles`, `media`.
- **apps/mobile/lib/models/exercise_media.dart** — Freezed: id, exerciseId, youtubeVideoId, channelName, isPrimary, startSeconds, endSeconds, curationStatus.
- **apps/mobile/lib/models/exercise_muscle.dart** — Freezed: exerciseId, muscleId, role, muscle (optional).
- **apps/mobile/lib/models/equipment_item.dart** — Freezed: id, name, category.
- **apps/mobile/test/features/exercises/exercise_filters_provider_test.dart** — Filter state and notifier tests.
- **apps/mobile/test/features/exercises/filtered_exercises_provider_test.dart** — Catalog provider success, error, refresh, loadMore.
- **apps/mobile/test/features/exercises/exercise_detail_provider_test.dart** — Detail provider success, null id, error.
- **apps/mobile/test/features/exercises/exercise_detail_screen_test.dart** — Detail screen: no-media fallback, approved media shown.
- **apps/mobile/test/features/exercises/exercise_list_item_test.dart** — List item name and onTap.

## Files Modified

- **apps/mobile/lib/app/router.dart** — Added `GoRoute` `/exercises` → `ExercisesScreen`, `/exercises/:id` → `ExerciseDetailScreen(exerciseId)`.
- **apps/mobile/lib/features/profile/profile_screen.dart** — Added "Exercise library" list tile → `context.push('/exercises')`.
- **apps/mobile/pubspec.yaml** — Added `url_launcher: ^6.2.0`.

## Provider Architecture

- **exerciseFiltersProvider** — NotifierProvider; state: search, difficulty?, place?, muscleId?. Methods: setSearch, setDifficulty, setPlace, setMuscleId, clear. Used by filter bar and by `filteredExercisesProvider`.
- **filteredExercisesProvider** — AsyncNotifierProvider. `build()` watches `exerciseFiltersProvider`, calls `GET /exercises` with `toQueryParams(1, 20)`. State: items, totalCount, page, isLoadingMore; hasMore = items.length < totalCount. `refresh()` refetches page 1; `loadMore()` fetches next page and appends. Exercises screen listens to filter changes and invalidates this provider so list refetches.
- **exerciseDetailProvider(id)** — AsyncNotifierProvider.family. Fetches `GET /exercises/:id` and maps to `ExerciseDetail` (includes muscles and media from backend). Detail screen shows only media with `curationStatus == 'approved'`.

## Search / Filter Behavior

- Search: free text; sent as `search` query param when non-empty (trimmed).
- Place: All (no param), Gym, Home, Calisthenics.
- Difficulty: optional 1–5 or Any (no param); chosen via bottom sheet.
- Muscle: optional muscleId if supported by backend (filter bar / provider support it).
- Changing any filter invalidates `filteredExercisesProvider` so the list refetches. Empty results show "No exercises match your filters" and "Clear filters"; no crash.

## Detail Screen Structure

- AppBar "Exercise".
- Body: `detailAsync.when(loading | error | data)`. Error: retry button. Data: scroll view with name, `ExerciseMetadataChips`, description (if present), muscles (if any), "Videos" section.
- Videos: if no approved media, show card "No video available yet"; else one `ExerciseVideoCard` per approved media.

## Media Handling

- Detail uses `ExerciseDetail.media` from `GET /exercises/:id`. Only items with `curationStatus == 'approved'` are shown.
- **ExerciseVideoCard**: label = channelName ?? "Watch on YouTube"; tap calls `url_launcher` with `https://www.youtube.com/watch?v=${youtubeVideoId}` (external app). No in-app video player.
- If detail fetch fails or media fetch is not used, UI shows error or partial data; no crash (defensive handling in provider/screen).

## Known Limitations

- No custom video playback; YouTube opens externally.
- Muscle filter in UI is supported by state/API params but may need backend support for filtering by muscle.
- Detail does not call `GET /exercises/:id/media` separately; relies on findOne including media and filters by curationStatus on client.
- Empty filter results are handled; backend returning empty list is not treated as an error.

## Commands

```bash
cd apps/mobile
dart run build_runner build --delete-conflicting-outputs   # if models change
flutter analyze
flutter test
```

## Git Tag

```bash
git tag phase-15-exercise-catalog-ui
```

(Do not push automatically.)
