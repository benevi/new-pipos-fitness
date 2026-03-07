# Phase 4 — Training Engine (Optimization-Based) — Summary

## Files created

### packages/contracts

- `src/schemas/training-engine.ts` — Zod schemas: `CatalogExerciseSnapshot`, `TrainingEngineInput`, `TrainingEngineOutput`, `PlanSession`, `PlanExercise`, `ConstraintViolation`, etc.
- `src/schemas/training-engine.test.ts` — Zod tests for training-engine schemas.

### packages/engine-rules

- `src/training/model.ts` — Constants and type re-exports.
- `src/training/utils.ts` — Stable sort, tie-break by `exerciseId`.
- `src/training/duration.ts` — `estimateSessionDurationMinutesSimple`, `estimateSessionDurationMinutes`.
- `src/training/volume.ts` — `computeWeeklySetsByMuscle` (role-weighted).
- `src/training/constraints.ts` — `buildCatalogMap`, `getCompatibleExercises`, `validatePlan`.
- `src/training/scoring.ts` — `scorePlan`, `defaultPlanExercise`; objective components (muscle, duration, movement, variety, difficulty).
- `src/training/initial-solution.ts` — `buildInitialPlan` (greedy, deterministic).
- `src/training/local-search.ts` — `improvePlan` (swap/move, hill-climb, no randomness).
- `src/training/engine.ts` — `generateTrainingPlan`, `getTrainingEngineVersion`.
- `src/training/engine.test.ts` — Engine, determinism, constraints, edge cases.
- `src/training/duration.test.ts` — Duration estimation.
- `src/training/volume.test.ts` — Weekly sets by muscle.
- `src/training/constraints.test.ts` — Catalog map, validatePlan (e.g. MIN_COMPOUND).
- `src/training/utils.test.ts` — Sort helpers.

## Files modified

- `packages/contracts/src/schemas/index.ts` — Export `training-engine.js`.
- `packages/engine-rules/src/training/index.ts` — Export `generateTrainingPlan`, `getTrainingEngineVersion`, `validatePlan`, `buildCatalogMap`, `getCompatibleExercises`.
- `docs/ENGINE_RULES.md` — Phase 4 optimization overview, objective/constraints, determinism requirement.
- `docs/FUTURE_TASKS.md` — Phase 4 done; future: weight tuning, ILP solver, workout logs.

## Engine I/O contract summary

- **Input (`TrainingEngineInput`):** `user` (trainingLevel, optional sex/height/weight/age), `preferences` (daysPerWeek 1..7, minutesPerSession 20..120, trainingLocation, availableEquipmentIds, optional dislikedExerciseIds), optional `goals`, optional `muscleFocus`, `catalog.exercises[]` (id, name, difficulty, movementPattern, place, equipmentIds, muscles).
- **Output (`TrainingEngineOutput`):** `metadata` (engineVersion, objectiveScore, constraintViolations[]), `weekPlan.sessions[]` (sessionIndex, name, targetDurationMinutes, exercises[] with exerciseId, sets, repRangeMin/Max, restSeconds, rirTarget). Output is returned even when invalid; `constraintViolations` non-empty means plan is invalid.

## Objective and constraints

- **Objective:** Maximize weighted sum of: muscle alignment with goals/muscleFocus (0.3), duration fit (0.2), movement balance (0.2), variety (0.15), difficulty fit (0.15).
- **Hard constraints:** Session duration ≤ minutesPerSession (estimated), equipment/location compatibility, weekly weighted sets per muscle ≤ cap by level (12/16/20), avoid muscles ≤ 2 weighted sets, ≤ 10 exercises per session, ≥ 1 compound per session.
- **Validation:** `validatePlan(plan, input, catalog)` returns `{ ok, violations }`; `ok === true` only when `violations.length === 0`.

## Determinism

- No `Math.random()` or external randomness. Greedy build uses fixed order (compatible list sorted by `exerciseId`). Local search tries swaps/moves in fixed order; first improving step is taken. Tie-breaking: lexicographic by `exerciseId`; `sortPlanExercises` is stable. Same input ⇒ same output.

## How to run engine unit tests

From repo root:

```bash
pnpm --filter @pipos/engine-rules test
```

Or from `packages/engine-rules`:

```bash
pnpm test
```

Run contract schema tests:

```bash
pnpm --filter @pipos/contracts test
```

## Verification (local)

- `pnpm lint`
- `pnpm typecheck`
- `pnpm test`

(Tests could not be run in the authoring environment due to pnpm/offline restrictions; run locally to confirm.)

## Known limitations

- No backend plan endpoints or DB persistence (Phase 5+).
- Catalog is in-memory only; no Prisma/DB in engine.
- Local search is limited to swap/move; no sets-adjustment in neighborhood (can be added later).
- Fixed objective weights; no user-configurable weights.
- No workout log or completion data in optimization.

## Git tag

When Phase 4 is complete and verified locally:

```bash
git tag phase-4-training-engine-optimizer
```

Do not push automatically.
