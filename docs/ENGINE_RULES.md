# Engine Rules

Placeholder sections for training and nutrition engine rules. To be expanded in later phases.

## Training Engine Rules

- (Phase 4) Rules for generating and adjusting training plans.
- (Phase 4) Inputs: user profile, goals, constraints, available exercises.
- (Phase 4) Outputs: structured plan (immutable, versioned in Phase 5).
- Safety: intensity caps, progression limits, rest requirements (to be defined).

### Phase 4 — Optimization-based training engine

- **Approach:** Greedy initial solution + deterministic local search (hill-climb). No randomness.
- **Objective (maximize):** Muscle coverage vs goals/muscleFocus, duration fit, movement balance, variety, difficulty fit. Weights: muscleAlignment 0.3, durationFit 0.2, movementBalance 0.2, variety 0.15, difficultyFit 0.15.
- **Hard constraints:** Session duration cap, equipment/location compatibility, weekly sets per muscle by level (beginner 12, intermediate 16, advanced 20), avoid-muscle cap (2 weighted sets), max 10 exercises per session, at least 1 compound (movementPattern) per session.
- **Determinism:** Same input always produces the same output. Tie-breaking by lexicographic exerciseId; stable sorting.

### Phase 7.1 — Localized adaptation

- **Adaptation:** Uses catalog ExerciseMuscle mapping. When progress indicates fatigue (per-exercise fatigueScore > 0.5 in exerciseHistory), only exercises that target those fatigued muscles have their sets reduced. When adherenceScore < threshold (0.7), all exercises are reduced (global deload). Deterministic.

## Nutrition Engine Rules (Phase 8)

- **Calories:** Mifflin-St Jeor BMR (sex, weight, height, age). TDEE = BMR × activity factor (default 1.375). Goal: lose_fat −15%, build_muscle +10%, maintain baseline.
- **Macros:** Protein 2 g/kg, fat 0.8 g/kg; carbs from remaining calories.
- **Meal generation:** From MealTemplate catalog; scale portions to daily calorie target; respect dislikedFoodIds; deterministic (stable sort by template id).
- **Inputs:** user (sex, heightCm, weightKg, age), goal (lose_fat | build_muscle | maintain), dislikedFoodIds, catalog (foods, mealTemplates).
- **Outputs:** weekPlan (7 days, each with meals and items), metadata (engineVersion, dailyCalorieTarget, dailyMacroTarget).
- **Determinism:** Same input → same output; no randomness.

## Safety Guardrails

- (To be defined per engine) Max/min values, rate of change limits, validation thresholds.
- All engine outputs must pass schema validation from contracts.

## Validation Philosophy

- Inputs to engine functions must be validated with Zod (contracts) before calling.
- Engine functions may assume validated input; they should still validate internal invariants where appropriate.
- Invalid or out-of-range inputs must be rejected at the boundary (API/worker), not inside engine core.

## Determinism requirement

- Training engine (Phase 4) must be deterministic: same `TrainingEngineInput` always yields the same `TrainingEngineOutput`.
- No random seeds, no `Math.random()`; use stable sorts and lexicographic tie-breaking (e.g. by `exerciseId`).
