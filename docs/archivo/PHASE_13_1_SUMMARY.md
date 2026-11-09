# Phase 13.1 — Nutrition Data Hardening

## Files Created

### Backend
- `apps/api/src/modules/catalog/foods/foods.controller.ts` — `GET /foods` returning `{ id, name }[]`
- `apps/api/src/modules/catalog/foods/foods.service.ts` — Prisma query selecting `id` and `name` only
- `apps/api/src/modules/catalog/foods/foods.module.ts` — NestJS module

### Mobile
- `apps/mobile/lib/models/food.dart` — Freezed model with `id` + `name`
- `apps/mobile/lib/features/nutrition/food_catalog_provider.dart` — `AsyncNotifier<Map<String, Food>>`, keepAlive, with `foodName` helper

## Files Modified

- `apps/api/src/modules/catalog/catalog.module.ts` — registered `FoodsModule`
- `apps/mobile/lib/features/nutrition/nutrition_view_model_provider.dart` — integrated food catalog, added `displayName` to `NutritionMealItemVM`, extracted `buildNutritionViewModel` for testability, improved empty/partial data handling
- `apps/mobile/lib/features/nutrition/widgets/meal_card.dart` — uses `item.displayName` instead of `item.foodId`
- `apps/mobile/test/features/nutrition/nutrition_state_test.dart` — expanded with food catalog, partial data, and display safety tests

## Food Catalog Provider Architecture

- `foodCatalogProvider` fetches `GET /foods`, builds `Map<String, Food>`, uses `ref.keepAlive()`
- `foodName(catalog, foodId)` helper returns human name or falls back to foodId
- `nutritionViewModelProvider` watches `foodCatalogProvider` and resolves display names in the ViewModel layer

## Summary Fallback Rules

Priority order:
1. Explicit `dailyCalorieTarget` / `dailyMacroTarget` from backend response
2. `null` with graceful display (summary card shows `--` for missing values)

Derived computation from food nutritional data is not implemented because `GET /nutrition-plans/current` does not include per-food macro data. Limitation documented.

## Meal Item Display Behavior

- `NutritionMealItemVM` now has `displayName` resolved via food catalog
- Falls back to `foodId` when catalog unavailable or food not found
- `MealCard` renders `displayName` with `TextOverflow.ellipsis` for long names

## Known Limitations

- `GET /nutrition-plans/current` does not return `dailyCalorieTarget` or `dailyMacroTarget` — only available from `POST /nutrition-plans/generate`. Summary shows `--` when null.
- Per-food macro data (calories, protein, carbs, fat) not included in plan response — meal-level calorie/macro totals cannot be computed client-side without additional API changes.
- `GET /foods` returns only `id` + `name` (minimal payload). Full nutritional data per food would require a separate endpoint or response expansion.
