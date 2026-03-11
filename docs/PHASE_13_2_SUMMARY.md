# Phase 13.2 — Nutrition Production Polish

## Files Modified

### Backend
- `apps/api/src/modules/catalog/foods/foods.controller.ts` — added optional `limit` and `cursor` query params
- `apps/api/src/modules/catalog/foods/foods.service.ts` — cursor-based pagination with Prisma

### Mobile
- `apps/mobile/lib/features/nutrition/food_catalog_provider.dart` — `Map<String, String>` storage, `_lastFetchedAt` tracking, `refreshIfStale()`, `refresh()`, `isStale` getter, `foodDisplayName()` helper
- `apps/mobile/lib/features/nutrition/nutrition_view_model_provider.dart` — uses `Map<String, String>` and `foodDisplayName()`
- `apps/mobile/lib/features/nutrition/nutrition_screen.dart` — calls `refreshIfStale()` on build, includes food catalog in pull-to-refresh
- `apps/mobile/test/features/nutrition/nutrition_state_test.dart` — updated for `Map<String, String>` catalog and `foodDisplayName` fallback

### Docs
- `docs/ARCHITECTURE.md` — Phase 13.2 section
- `docs/PHASE_13_2_SUMMARY.md` — this file

## Food Catalog Pagination

- `GET /foods?limit=500&cursor=<id>` — cursor-based pagination ordered by id
- `limit` defaults to 500, clamped 1–1000
- `cursor` optional; when provided, returns items after that id
- Response shape unchanged: `[{ id, name }]`
- Mobile client calls without parameters (fetches all in one page for typical catalog sizes)

## Provider Refresh Strategy

- `keepAlive()` prevents disposal on tab switch
- `_lastFetchedAt` timestamp recorded after each fetch
- `refreshIfStale()` checks if cache older than 1 hour, auto-refreshes if so
- `refresh()` forces immediate refetch
- No refetch loops: `refreshIfStale()` is a no-op when cache is fresh

## Fallback Display Behavior

Priority:
1. Catalog food name (from `Map<String, String>`)
2. `"Food item"` (safe fallback, no raw IDs in UI)

`foodDisplayName(catalog, foodId)` implements this logic.

## Memory Optimization

- Provider stores `Map<String, String>` instead of `Map<String, Food>`
- `Food` Freezed model kept for API response decoding, converted immediately to `String` values
- Reduces per-entry memory from Food object to single String

## Known Limitations

- Mobile fetches all foods in single request (no client-side pagination). Adequate for typical catalog sizes (<500 items).
- `refreshIfStale()` called during widget build — safe because it's a no-op when fresh, but triggers async work from build.
