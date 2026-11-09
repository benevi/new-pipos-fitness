# Phase 8 — Nutrition Engine — Summary

## Scope

Nutrition engine only: DB models, engine-rules (calorie, macro, meal generation), API endpoints for plan generation and retrieval. No UI, notifications, AI assistant, Flutter app, or nutrition tracking.

## Files created

- **apps/api/prisma:** (schema changes) Food, MealTemplate, MealTemplateFood, NutritionPlan, NutritionPlanVersion, NutritionDay, NutritionMeal, NutritionMealItem; User.dislikedFoodIds, User.nutritionPlans.
- **apps/api/src/modules/nutrition-plans:** nutrition-plans.module.ts, nutrition-plans.service.ts, nutrition-plans.controller.ts.
- **packages/contracts/src/schemas/nutrition-engine.ts:** FoodSnapshot, MealTemplateSnapshot, NutritionEngineInput/Output, NutritionGoalType usage.
- **packages/contracts/src/enums:** NutritionGoalType (lose_fat, build_muscle, maintain).
- **packages/engine-rules/src/nutrition:** nutrition-types.ts, calorie-calculation.ts, macro-calculation.ts, meal-generation.ts, nutrition-engine.ts; tests: calorie-calculation.test.ts, macro-calculation.test.ts, meal-generation.test.ts, nutrition-engine.test.ts; index.ts and index.test.ts updated.
- **docs/PHASE_8_SUMMARY.md:** This file.

## Files modified

- **apps/api/prisma/schema.prisma** — Added nutrition models and User.dislikedFoodIds, User.nutritionPlans.
- **apps/api/src/app.module.ts** — Import NutritionPlansModule.
- **apps/api/src/modules/users/users.service.ts** — getMe selects dislikedFoodIds.
- **packages/contracts/src/enums/index.ts** — NutritionGoalType.
- **packages/contracts/src/schemas/index.ts** — Export nutrition-engine.
- **packages/engine-rules/src/nutrition/index.ts** — Export engine and helpers.
- **packages/engine-rules/src/nutrition/index.test.ts** — Extended tests.
- **docs/ARCHITECTURE.md** — Nutrition Engine section.

## Database

- **Food:** id, name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g; @@index([name]).
- **MealTemplate:** id, name; @@index([name]).
- **MealTemplateFood:** id, mealTemplateId, foodId, quantityG; @@unique([mealTemplateId, foodId]); @@index([mealTemplateId]), @@index([foodId]).
- **NutritionPlan:** id, userId, currentVersionId; @@index([userId]).
- **NutritionPlanVersion:** id, planId, version, createdAt, engineVersion; @@unique([planId, version]); @@index([planId]).
- **NutritionDay:** id, planVersionId, dayIndex; @@unique([planVersionId, dayIndex]); @@index([planVersionId]).
- **NutritionMeal:** id, nutritionDayId, mealIndex, name, templateId (FK MealTemplate, SetNull); @@index([nutritionDayId]), @@index([templateId]).
- **NutritionMealItem:** id, nutritionMealId, foodId, quantityG; @@index([nutritionMealId]), @@index([foodId]).
- **User:** dislikedFoodIds (Json?), nutritionPlans (relation).

**Migration:** Run `cd apps/api && pnpm prisma migrate dev --name phase-8-nutrition-models`.

## Engine

- **Calorie:** Mifflin-St Jeor BMR; TDEE = BMR × 1.375; goal: lose_fat 0.85×, build_muscle 1.1×, maintain 1×.
- **Macros:** Protein = 2 g/kg, fat = 0.8 g/kg; carbs = (dailyCal − proteinCal − fatCal) / 4.
- **Meals:** generateMealsForDay(templates, foods, dislikedFoodIds, dailyCalorieTarget, mealsPerDay); scales each template to target calories per meal; skips templates that reference only disliked foods; deterministic (templates sorted by id).

## API

- **POST /nutrition-plans/generate** — Body: `{ goal?: 'lose_fat' | 'build_muscle' | 'maintain' }`. Default goal from user goals (fat_loss → lose_fat, muscle_gain → build_muscle, else maintain). Returns plan + current version with days/meals/items and metadata (dailyCalorieTarget, dailyMacroTarget).
- **GET /nutrition-plans/current** — Returns current plan and version with full day/meal/item tree.
- **GET /nutrition-plans/versions** — Returns list of version summaries (id, planId, version, createdAt, engineVersion).

## Tests

- **engine-rules:** calorie-calculation (BMR null/ male/female, TDEE, daily target by goal), macro-calculation (null cases, protein/fat/carbs), meal-generation (scale, disliked, deterministic), nutrition-engine (version, 7 days, invalid input, goal affects calories), index (exports and generateMealsForDay).

## Git tag

`git tag phase-8-nutrition-engine` (do not push automatically).

## Known limitations

- No seed data for Food/MealTemplate; empty catalog yields empty meals.
- Activity factor fixed at 1.375; not yet user-configurable.
- No GET /nutrition-plans/versions/:id for a single version snapshot (can be added later).
