# Phase 13 — Nutrition UI

## Files Created

- `apps/mobile/lib/features/nutrition/nutrition_versions_provider.dart`
- `apps/mobile/lib/features/nutrition/nutrition_view_model_provider.dart`
- `apps/mobile/lib/features/nutrition/widgets/nutrition_summary_card.dart`
- `apps/mobile/lib/features/nutrition/widgets/day_selector.dart`
- `apps/mobile/lib/features/nutrition/widgets/meal_card.dart`
- `apps/mobile/lib/features/nutrition/widgets/nutrition_versions_sheet.dart`
- `apps/mobile/test/features/nutrition/nutrition_state_test.dart`

## Files Modified

- `apps/mobile/lib/models/nutrition_plan.dart` — restructured to match backend response shape (`plan` + `version` wrapper), added `NutritionPlanInfo`, `NutritionMacroTarget`, `NutritionVersionSummary`, nullable calorie/macro target fields
- `apps/mobile/lib/features/nutrition/nutrition_plan_provider.dart` — updated to match new model shape
- `apps/mobile/lib/features/nutrition/nutrition_screen.dart` — full rewrite from placeholder to production screen

## Provider Architecture

- `nutritionPlanProvider` — fetches `GET /nutrition-plans/current`, keepAlive, supports refresh/generate
- `nutritionVersionsProvider` — fetches `GET /nutrition-plans/versions`, keepAlive
- `selectedDayProvider` — `StateProvider<int>` for day selector state
- `nutritionViewModelProvider` — synchronous `Provider<NutritionViewModel>` combining plan + versions + selected day into UI-ready data

## Nutrition Screen Structure

1. **Summary Card** — daily calorie target, protein/carbs/fat macro targets, version badge
2. **Day Selector** — horizontal chip row (Mon–Sun), updates `selectedDayProvider`
3. **Meal Cards** — each meal shows name, item count, food items with quantity in grams
4. **Versions Sheet** — bottom sheet listing all plan versions with version number, engine version, date

## Day Selection

- Horizontal `ChoiceChip` list, one per day in the plan
- Selection stored in `selectedDayProvider` (simple `StateProvider<int>`)
- Clamped to valid range when plan data changes
- Meal list updates reactively on day switch

## Versions UI

- History icon in app bar (visible only when versions loaded)
- Opens `ModalBottomSheet` with scrollable list
- Each version shows: version number, engine version, creation date
- Gracefully shows empty message if no versions

## Known Limitations

- `GET /nutrition-plans/current` does not return `dailyCalorieTarget` or `dailyMacroTarget` — these fields are only populated when the plan is freshly generated. The summary card handles null targets gracefully.
- Meal items display `foodId` instead of human-readable food names — a food catalog provider would be needed to resolve names (out of scope).
- No meal-level calorie/macro totals — the backend does not include food nutritional data in the plan response.
- Version list is read-only; selecting a version to view its full plan is not implemented.
