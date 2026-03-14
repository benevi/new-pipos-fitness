# Phase 13.3 — Nutrition Seed & Readiness

## Summary

Phase 13.3 adds seed data for the nutrition system so that `GET /foods`, `POST /nutrition-plans/generate`, and `GET /nutrition-plans/current` work in development and test environments. No new product features.

---

## What was seeded

### Foods (30)

Deterministic ids (`food-*`). All include: id, name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g.

| Category | Foods |
|----------|--------|
| Protein | Chicken breast, Beef lean, Tuna canned, Turkey breast, Salmon, Egg whole, Tofu firm |
| Carbs | Rice white cooked, Oatmeal, Pasta cooked, Whole grain bread, Quinoa cooked, Lentils cooked, Sweet potato, Black beans cooked |
| Fats | Avocado, Olive oil, Almonds |
| Dairy/alt | Greek yogurt, Milk semi-skimmed, Cottage cheese |
| Fruits | Banana, Apple, Orange, Blueberries |
| Vegetables | Broccoli, Spinach raw, Tomato, Carrot |
| Other | Hummus |

### Meal templates (12)

Deterministic ids (`tpl-*`). Each template has 2–4 foods with plausible quantities (quantityG).

| Id | Name |
|----|------|
| tpl-breakfast-oatmeal | Breakfast: Oatmeal & fruit |
| tpl-breakfast-eggs | Breakfast: Eggs & toast |
| tpl-breakfast-yogurt | Breakfast: Yogurt & fruit |
| tpl-lunch-chicken-rice | Lunch: Chicken & rice |
| tpl-lunch-salmon-veg | Lunch: Salmon & vegetables |
| tpl-lunch-beans-rice | Lunch: Beans & rice |
| tpl-dinner-beef-veg | Dinner: Beef & vegetables |
| tpl-dinner-tofu | Dinner: Tofu stir-fry |
| tpl-dinner-pasta | Dinner: Pasta & vegetables |
| tpl-snack-banana-nuts | Snack: Banana & nuts |
| tpl-snack-apple-cheese | Snack: Apple & cottage cheese |
| tpl-snack-hummus-veg | Snack: Hummus & vegetables |

### MealTemplateFood

36 links total. Every template has multiple foods; quantities are in grams. Disliked-food filtering still leaves enough valid templates for testing.

---

## Idempotency

- **Food:** `upsert` by `id`.
- **MealTemplate:** `upsert` by `id`.
- **MealTemplateFood:** `upsert` by `mealTemplateId_foodId` (compound unique).

Re-running the seed does not duplicate rows and is safe to run multiple times.

---

## Commands

### Run seed

```bash
cd apps/api
pnpm exec prisma db seed
```

### Verify nutrition generation

With API running (`pnpm start:dev`):

1. **GET /foods** — Should return an array of foods (30 items with seeded data).
2. **POST /nutrition-plans/generate** — With valid JWT (e.g. after login). Should return `plan`, `version`, `days`, `meals`, `items`.
3. **GET /nutrition-plans/current** — With same user. Should return current plan snapshot with days and meals.

Example (after login, using token in header):

```bash
# Login, then:
curl -H "Authorization: Bearer <accessToken>" http://localhost:3000/foods
curl -X POST -H "Authorization: Bearer <accessToken>" -H "Content-Type: application/json" http://localhost:3000/nutrition-plans/generate
curl -H "Authorization: Bearer <accessToken>" http://localhost:3000/nutrition-plans/current
```

---

## Known limitations

- Seed is for dev/test only; production data must be managed separately.
- Meal names and portions are generic; real plans may require more templates and foods.
- No seed verification script is included; verification is manual or via existing E2E/API tests.

---

## Files modified

- `apps/api/prisma/seed.ts` — Added Food (30), MealTemplate (12), MealTemplateFood (36 links). All idempotent with deterministic ids.
- `apps/api/src/modules/nutrition-plans/nutrition-plans.service.ts` — Response mapping: use optional chaining for `createdAt` (NutritionPlan model has no `createdAt` in schema) so `toGenerateResponse` and `getCurrent` do not throw.
- `apps/api/src/modules/analytics/analytics.e2e-spec.ts` — Lint fix: use unused mock parameter so eslint passes.
