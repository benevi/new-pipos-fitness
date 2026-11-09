# Phase 8.1 — Nutrition Engine Hardening — Summary

## Scope

No new product features. Correctness and quality improvements only: dynamic activity factor, macro clamping, meal template rotation.

## Files modified

- **packages/contracts/src/schemas/nutrition-engine.ts** — `NutritionEngineUserSchema`: added `preferredTrainingDays` (0–7). `NutritionEngineOutputMetadataSchema`: added optional `macrosClamped`.
- **packages/engine-rules/src/nutrition/calorie-calculation.ts** — Added `getActivityFactor(trainingDaysPerWeek)`; mapping 0–1→1.2, 2–3→1.375, 4–5→1.55, 6–7→1.725. `calculateTDEE` / `calculateDailyCalorieTarget` still take optional activity factor (engine passes it).
- **packages/engine-rules/src/nutrition/macro-calculation.ts** — `calculateMacroTargets` now returns `{ macroTarget, clamped }`. Carbs = max(0, remainder); `clamped` true when remainder ≤ 0. Added `getMacroTarget` for backward compatibility.
- **packages/engine-rules/src/nutrition/meal-generation.ts** — `generateMealsForDay` accepts `dayIndex`; valid templates rotated by `(dayIndex + mealIndex) % validTemplates.length` so the same template is not repeated every day when multiple exist.
- **packages/engine-rules/src/nutrition/nutrition-engine.ts** — Uses `getActivityFactor(user.preferredTrainingDays ?? 3)`; uses `calculateMacroTargets` result (macroTarget + clamped); sets `metadata.macrosClamped`; passes `dayIndex` to `generateMealsForDay`.
- **packages/engine-rules/src/nutrition/nutrition-types.ts** — `NutritionUser`: optional `preferredTrainingDays`.
- **packages/engine-rules/src/nutrition/index.ts** — Export `getActivityFactor`, `getMacroTarget`, `MacroResult`.
- **packages/engine-rules/src/nutrition/*.test.ts** — Activity factor tests; macro clamping and edge-case tests; meal rotation and determinism tests.
- **apps/api/src/modules/nutrition-plans/nutrition-plans.service.ts** — Pass `user.preferredTrainingDays` in engine input; `toGenerateResponse` accepts and forwards optional `macrosClamped`.
- **docs/ENGINE_RULES.md** — Phase 8.1: dynamic activity factor, carb clamping, meal rotation.
- **docs/PHASE_8_1_SUMMARY.md** — This file.

## Calorie logic changes

- **Before:** Fixed activity factor 1.375.
- **After:** Activity factor from `preferredTrainingDays`: 0–1 → 1.2, 2–3 → 1.375, 4–5 → 1.55, 6–7 → 1.725. Fallback 3 (1.375) when missing. API passes `user.preferredTrainingDays` from `getMe`.

## Macro safety changes

- **Before:** `remainingCal = max(0, ...)` so carbs could already be 0; no flag.
- **After:** `calculateMacroTargets` returns `{ macroTarget, clamped }`. Carbs never negative; when protein+fat calories ≥ target, carbs = 0 and `clamped = true`. Metadata includes optional `macrosClamped` (only when true). API response version object includes `macrosClamped` when set.

## Meal rotation behavior

- **Before:** Same templates in same order every day (first N valid templates).
- **After:** Valid templates (sorted by id) are indexed; for day `d`, meal slot `m`, template index = `(d + m) % validTemplates.length`. Reduces identical template repetition across 7 days when multiple templates exist. Single valid template still repeats (allowed). Deterministic; dislikedFoodIds unchanged.

## Example edge-case output

- **Very low calorie target (e.g. 400 kcal):** protein 140 g, fat 56 g, carbs 0 g; `macrosClamped: true`.
- **Activity factor:** User with `preferredTrainingDays: 5` → factor 1.55 → higher TDEE and calorie target than with 3 days.
- **Rotation:** 3 templates, 3 meals/day: day 0 meals = [t0, t1, t2], day 1 = [t1, t2, t0], day 2 = [t2, t0, t1], etc.

## Known limitations

- Activity factor uses training days only; no separate “sedentary/active” flag.
- Rotation is per-day slot; no global variety optimization across the week.
- `getMacroTarget` remains for compatibility; new code should use `calculateMacroTargets().macroTarget`.

## Commands

- **Lint:** `pnpm lint`
- **Typecheck:** `pnpm typecheck`
- **Tests:** `pnpm test`
- **Tag:** `git tag phase-8-1-nutrition-hardening` (do not push)
