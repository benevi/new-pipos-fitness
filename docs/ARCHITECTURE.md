# Architecture

## System Overview

Pipos Fitness is an AI-powered mobile application for personalized training and nutrition. The system consists of:

- **Mobile app (Flutter)**: User interface, workout/nutrition display, tracking, analytics, AI assistant.
- **API (NestJS)**: REST API, orchestration, data access. No business logic; delegates to engine-rules.
- **Worker**: Background jobs (BullMQ). Processes async tasks; uses engine-rules for decisions.
- **Engine-rules**: Pure, deterministic business logic. No DB, no framework.
- **Contracts**: Shared Zod schemas for requests/responses and validation.

AI assists and explains; it does not control business logic. Deterministic engines produce plans; AI may augment explanations.

## Module Boundaries

| Module        | Responsibility                    | Allowed dependencies        |
|---------------|------------------------------------|-----------------------------|
| contracts     | Schemas, enums, validation         | Zod only                    |
| engine-rules  | Training/nutrition logic (pure)   | contracts                   |
| api           | HTTP, Prisma, orchestration       | contracts, engine-rules      |
| worker        | Queues, job execution             | contracts, engine-rules      |
| mobile        | UI, API client                    | contracts (shared types)    |

API and worker must not contain business rules; they call engine-rules and persist results.

## Dependency Flow

Dependencies must only point downward. This avoids AI and human errors (e.g. importing backend into contracts).

```
contracts
   ↑
engine-rules
   ↑
backend  (api + worker)
   ↑
mobile
```

- **contracts** — No internal package dependencies (only Zod).
- **engine-rules** — May depend on `contracts` only.
- **backend** (api, worker) — May depend on `contracts` and `engine-rules`. Never the reverse.
- **mobile** — May depend on `contracts` (and later API client). Never on engine-rules or api code directly.

## Folder Structure

```
apps/
  api/          # NestJS app
  worker/       # BullMQ worker
  mobile/       # Flutter app
packages/
  contracts/    # Zod schemas, enums
  engine-rules/ # Pure functions (training, nutrition)
docs/
scripts/
.github/workflows/
```

## Monorepo Strategy

- pnpm workspaces; shared `tsconfig.base.json`.
- Each app/package has its own `package.json`, `tsconfig.json`, and scripts.
- CI runs install, lint, typecheck, and tests for all packages.

## Engine Isolation

- All business logic lives in `packages/engine-rules`.
- Functions are pure: same inputs → same outputs; no I/O, no globals.
- Fully unit tested; no database or HTTP in tests.
- NestJS/worker only: load data → call engine → persist/respond.

## Contract-First Design

- All API request/response shapes and shared types live in `packages/contracts`.
- Schemas are Zod; used for validation and (where needed) codegen.
- API changes require contract updates first; no ad-hoc DTOs in apps.

## Versioning Philosophy

- Critical objects (e.g. plans) are immutable and versioned (later phases).
- History is append-only; no in-place edits of plan content.

## Authentication Layer

- **JWT access tokens** (short-lived, e.g. 15 minutes) for API authorization. Payload includes `userId` and `email`.
- **Refresh tokens** (long-lived, e.g. 7 days) stored hashed in the database; rotation on use (old token invalidated when a new one is issued).
- **Password hashing** with bcrypt before storing. No plaintext passwords or refresh tokens.
- **Protected routes** use a JWT guard; the current user is attached to the request and available via a `CurrentUser` decorator.
- Auth endpoints: `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout`. User profile: `GET /me`, `PUT /me/profile`, `PUT /me/preferences`, `PUT /me/goals`, `PUT /me/muscle-focus`.
- **Refresh token rotation:** Each refresh token is single-use. After use it is marked revoked (`revokedAt`). Reuse of a revoked token returns `401` with code `AUTH_REFRESH_REUSED`. Logout revokes the given refresh token.

## Exercise Catalog System

- **Catalog** provides the curated exercise list used by the app and (later) the training engine.
- **Models:** Muscle (id, name, region, meshRegionId), EquipmentItem (id, name, category), Exercise (slug, name, description, difficulty, movementPattern, place), ExerciseMuscle (exercise–muscle with role), ExerciseEquipment (exercise–equipment), ExerciseVariant, ExerciseMediaYouTube (YouTube video, curation status), YouTubeChannel.
- **Public endpoints:** `GET /muscles`, `GET /equipment-items`, `GET /exercises` (filters: muscleId, equipmentId, difficulty, movementPattern, place, search; pagination), `GET /exercises/:id`, `GET /exercises/:id/media` (approved media only).
- **Admin endpoints:** `POST /admin/exercises`, `PUT /admin/exercises/:id`, `POST /admin/exercises/:id/media`, `PUT /admin/exercise-media/:id/approve`, `PUT /admin/exercise-media/:id/reject`. No admin auth in Phase 3 (placeholder).

## Training Plan Versioning

- **Models:** TrainingPlan (userId, currentVersionId), TrainingPlanVersion (planId, version, engineVersion, objectiveScore), TrainingSession (planVersionId, sessionIndex, name, targetDurationMinutes), TrainingSessionExercise (sessionId, exerciseId, sets, repRangeMin/Max, restSeconds, rirTarget).
- **Generation:** `POST /training-plans/generate` (authenticated). API gathers user profile and preferences, loads catalog snapshot from DB, calls `generateTrainingPlan(input)` from engine-rules, then persists a new plan version and sessions/exercises, and sets the plan’s currentVersionId.
- **Retrieval:** `GET /training-plans/current` (latest plan snapshot), `GET /training-plans/versions` (list of versions), `GET /training-plans/versions/:id` (specific version). All require authentication and are scoped to the current user’s plan.

## Workout Tracking

- **Models:** WorkoutSession (userId, optional planSessionId FK to TrainingSession, optional planVersionId FK to TrainingPlanVersion, startedAt, completedAt, durationMinutes, notes), WorkoutExercise (workoutSessionId, exerciseId, order), WorkoutSet (workoutExerciseId, setIndex, weightKg, reps, rir, completed). When a workout is started with planSessionId, the API resolves TrainingSession.planVersionId and stores it on WorkoutSession.planVersionId so adherence is tied directly to the versioned plan.
- **Set logging ownership:** `POST /workouts/:id/exercises/:workoutExerciseId/sets` validates: (1) workout session exists and belongs to the authenticated user (404/403), (2) workout exercise exists, belongs to that session, and session belongs to user. Set logging is attached to WorkoutExercise (not catalog Exercise) because sets are recorded per instance of an exercise within a specific workout; the same catalog exercise can appear in multiple workouts with different set logs. Returns 404 "Workout exercise not found" when the exercise does not exist or does not belong to the given session (avoids leaking existence of other users’ data).
- **Endpoints (all JWT-protected):** `POST /workouts/start` (optional body: planSessionId) — start session, returns WorkoutSession (planVersionId set when planSessionId provided); `POST /workouts/:id/exercises` (body: exerciseId) — add exercise (exerciseId must reference catalog Exercise); `POST /workouts/:id/exercises/:workoutExerciseId/sets` (body: weightKg, reps, rir, completed) — log set; `POST /workouts/:id/finish` (body: durationMinutes, notes) — finish session; `GET /workouts/history` — recent sessions for current user.

## Adaptive Training Engine

- **Progress analytics (Phase 7):** Engine input may include optional `progress`: exerciseHistory (per-exercise e1RM, volume, trend, fatigueScore), weeklyVolume, adherenceScore, fatigueScore. Analytics are computed from WorkoutSet data: e1RM = weightKg × (1 + reps/30), weekly volume per exercise and per muscle (via ExerciseMuscle), adherence = completed_sets / planned_sets, fatigue when rir ≤ 0 or reps drop > 20% across sets. **Adherence is session-based:** computed over the last 7 days; only WorkoutSessions with `planSessionId != null` are included. For each such workout, planned sets = sum of sets defined in the linked TrainingSession (TrainingSessionExercise.sets); completed sets = WorkoutSets with `completed = true` in that workout. No version-level aggregation; no over-counting. Workouts without planSessionId are excluded from adherence.
- **Adaptation:** When generating a plan, the API loads progress via the analytics module and passes it to the engine. The engine performs **localized adaptation**: it identifies exercises associated with fatigued muscles (from exerciseHistory and catalog ExerciseMuscle mapping) and reduces sets only for those exercises; unrelated exercises are unchanged. When adherenceScore < 0.7 (deload threshold), sets are reduced for all exercises.
- **Models:** ExerciseProgress (userId, exerciseId, estimated1RM, volumeLastWeek, volumeTrend, fatigueScore, lastUpdated). **ExerciseProgress is a derived analytics projection;** source of truth remains WorkoutSession, WorkoutExercise, and WorkoutSet. Progress is recomputed from that source and upserted for read use; it is not authoritative for history.
- **Endpoints:** `GET /analytics/progress` — user exercise progress metrics (e1RM, volume, trend, fatigue, adherence); `GET /analytics/volume` — weekly volume by exercise and by muscle.

## Nutrition Engine (Phase 8)

- **Models:** Food (name, caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g), MealTemplate (name), MealTemplateFood (mealTemplateId, foodId, quantityG), NutritionPlan (userId, currentVersionId), NutritionPlanVersion (planId, version, engineVersion), NutritionDay (planVersionId, dayIndex), NutritionMeal (nutritionDayId, mealIndex, name, templateId), NutritionMealItem (nutritionMealId, foodId, quantityG). User has optional dislikedFoodIds (JSON array of food ids).
- **Calories:** Mifflin-St Jeor BMR; TDEE = BMR × activity factor. Goal adjustment: lose_fat −15%, build_muscle +10%, maintain baseline.
- **Macros:** Protein 2 g/kg, fat 0.8 g/kg; carbs from remaining calories.
- **Meal generation:** From MealTemplate catalog; scales portions to meet daily calorie target; respects dislikedFoodIds and calorie/macro targets. Deterministic (stable sort by template id).
- **Endpoints (JWT-protected):** `POST /nutrition-plans/generate` (optional body: goal) — generate weekly plan; `GET /nutrition-plans/current` — current plan snapshot; `GET /nutrition-plans/versions` — version history.

## AI Coach (Phase 9)

- **Scope:** AI coach infrastructure only. It answers questions and may return structured proposals, but it does not write to database business entities or execute automatic plan changes.
- **Module:** `apps/api/src/modules/ai-coach` with `ai-coach.module.ts`, `ai-coach.controller.ts`, `ai-coach.service.ts`, `context-builder.ts`, and `response-validator.ts`.
- **Endpoint:** `POST /ai-coach/ask` (JWT-protected). Input: `AIQuestionRequest` (`{ question: string }`). Output: `AIResponse` (`responseType`, `content`, optional `proposal`).
- **Context builder:** Loads trimmed context from existing modules only: user profile (`UsersService`), training plan summary (`TrainingPlansService`), nutrition plan summary (`NutritionPlansService`), and progress metrics (`AnalyticsService`).
- **Structured proposals:** Current proposal shape supports `exercise_swap` with `fromExerciseId` and `toExerciseId`.
- **Validation guardrail:** `response-validator` rejects invalid proposals when exercise ids are invalid, required equipment is unavailable, or replacement would break plan constraints (location/movement-pattern/difficulty checks).
- **Boundary rule:** AI coach is advisory. Final business decisions remain in deterministic engines and explicit API workflows.

### AI Coach Safety Model (Phase 9.1)

- **LLM cannot modify database:** The AI coach pipeline is read-only with respect to business entities. The only write is the `AIInteraction` audit record.
- **Proposals must pass validator:** Every proposal goes through `ResponseValidatorService` which checks exercise existence, equipment availability, location, movement-pattern, and difficulty constraints. Invalid proposals are returned with `proposalStatus: "rejected"` — never silently dropped.
- **Proposals are not automatically applied:** The API returns proposals to the client. The user or a separate explicit workflow must confirm and apply them.
- **Interactions are audited:** Each `POST /ai-coach/ask` call persists a lightweight `AIInteraction` record (question, responseType, proposalType, proposalValid, context/response summaries). Full LLM prompts/responses are NOT stored.
- **Output normalization:** Before validation, raw AI output passes through `AIResponseNormalizerService` which enforces schema conformance and falls back to a safe default response on parse failure.
- **Context minimization:** `ContextBuilderService` sends only fitness-relevant profile fields. It explicitly excludes passwords, tokens, emails, and full plan/workout data. Lists are capped.

## Mobile App (Phase 10)

- **Framework:** Flutter with Material 3.
- **State management:** Riverpod (StateNotifier for auth, AsyncNotifier for data).
- **Routing:** GoRouter with auth redirect guard and ShellRoute bottom navigation.
- **API client:** Dio with `AuthInterceptor` (automatic Bearer token attachment, 401 refresh retry).
- **Token storage:** `flutter_secure_storage` for access and refresh tokens.
- **Models:** Freezed + json_serializable for immutable, serializable data classes (User, TrainingPlan, NutritionPlan, ProgressMetrics, AIResponse).
- **Base URL:** Compile-time configurable via `--dart-define=API_BASE_URL=...`. Default: `http://10.0.2.2:3000`.

### Mobile App Hardening (Phase 10.1)

- **Auth state:** Explicit 5-state model (unknown → unauthenticated → loading → authenticated | error). Router guards depend on `isResolved` and `isAuthenticated`.
- **Refresh concurrency:** Completer-based lock ensures only one refresh request executes; concurrent 401s share the result.
- **Error handling:** `ApiFailure` model + `mapDioException()` mapper. Raw Dio exceptions never reach UI or providers.
- **Theme foundation:** Dark-first Material 3 theme with orange accent (#FF6D00), design tokens (AppSpacing, AppRadius, AppColors).
- **Provider caching:** Main-tab providers use `ref.keepAlive()` to survive tab switches without re-fetching.

### Auth/Session Consistency (Phase 10.2)

- **Session coordinator:** `AuthSessionCoordinator` bridges Dio interceptor → Riverpod auth state → protected provider invalidation. No circular dependencies.
- **Forced logout:** On refresh failure: interceptor clears tokens → coordinator sets auth state to unauthenticated + invalidates data providers → router redirects to /login. Re-entry guard prevents duplicates.
- **Provider invalidation:** `progressProvider`, `trainingPlanProvider`, `nutritionPlanProvider` are invalidated on both user-initiated and forced logout. No stale data after session loss.

### Workout Experience (Phase 11)

- **Flow:** Workouts tab → select session from training plan → start workout (POST /workouts/start) → log sets per exercise → finish (POST /workouts/:id/finish) → summary screen → dashboard.
- **Provider:** `workoutSessionProvider` (StateNotifier) manages workout lifecycle, exercise navigation, and set logging. Uses ApiClient with ApiFailure error mapping.
- **Routing:** `/workout-player` and `/workout-complete` are full-screen routes outside ShellRoute (no bottom nav bar during workout).

### Workout Hardening (Phase 11.1)

- **Atomic start:** Workout start + exercise addition is a single atomic operation in the provider. State transitions to `active` only after both succeed; on failure state is `error` with retry capability.
- **Exercise catalog:** `exerciseCatalogProvider` fetches and caches the full exercise list as `Map<String, Exercise>` with `keepAlive`. UI shows exercise names instead of IDs.
- **Resume:** On Workouts screen load, checks `GET /workouts/history` for incomplete sessions (`completedAt == null`). Prompts user to resume, restoring full workout state.

### Workout Resume Integrity (Phase 11.2)

- **Full session fetch:** `GET /workouts/:id` endpoint returns complete session with exercises and sets. Resume fetches this instead of relying on history data.
- **Retry initialization:** `retryAddExercises()` fetches current server state, determines missing exercises, adds only those. Does not create a duplicate session.
- **Multi-session guard:** If multiple incomplete sessions exist, the most recent (by startedAt) is chosen. Debug warning logged for multiples.
- **State restoration:** `_computeResumeIndex()` positions the player at the first exercise with no logged sets. Existing sets are preserved and displayed.

### Progress Dashboard (Phase 12)

- **Providers:** `progressProvider` (GET /analytics/progress) and `volumeProvider` (GET /analytics/volume), both keepAlive AsyncNotifiers. Exercise catalog provider supplies display names.
- **Sections:** Summary cards (adherence/exercises/fatigue), fatigue status banner, weekly volume card with muscle breakdown, per-exercise progress list with e1RM, volume, trend, and fatigue highlight.
- **States:** Loading, error (retry), empty (no data), loaded with pull-to-refresh.

### Dashboard Hardening (Phase 12.1)

- **ViewModel:** `dashboardProvider` (synchronous Provider) composes progressProvider, volumeProvider, exerciseCatalogProvider, and muscleCatalogProvider into a single `DashboardViewModel`. UI renders only the ViewModel.
- **Muscle catalog:** `muscleCatalogProvider` fetches `GET /muscles`, maps muscleId→Muscle, keepAlive. Volume chips show muscle names.
- **Empty-state:** Dashboard is empty only when no exercises AND no volume AND no adherenceScore. Partial data renders normally.
- **Widget extraction:** `DashboardSummaryCard`, `FatigueBanner`, `ProgressListItem`, `VolumeSummaryCard` extracted for readability.

### Nutrition UI (Phase 13)

- **Model update:** `NutritionPlan` restructured to match backend response shape (`plan` + `version` wrapper). Added `NutritionMacroTarget`, `NutritionVersionSummary`, nullable calorie/macro target fields on version.
- **Providers:** `nutritionPlanProvider` (current plan, keepAlive), `nutritionVersionsProvider` (version list, keepAlive), `selectedDayProvider` (day index state), `nutritionViewModelProvider` (synchronous composition into `NutritionViewModel`).
- **Screen:** Summary card (calories, macros, version), day selector (horizontal chips), meal cards (name, food items, quantities), versions bottom sheet.
- **States:** Loading, error (retry), empty (no plan), loaded with pull-to-refresh.

### Nutrition Data Hardening (Phase 13.1)

- **Food catalog:** `GET /foods` backend endpoint (id + name). `foodCatalogProvider` fetches, caches with keepAlive. `foodName` helper resolves display names with foodId fallback.
- **ViewModel:** `nutritionViewModelProvider` now watches `foodCatalogProvider`. `NutritionMealItemVM` has `displayName`. `buildNutritionViewModel` extracted as pure function for testability.
- **Display safety:** ViewModel handles null plan, null catalog, null targets, empty days, out-of-range selectedDay. UI renders `--` for missing summary values.

## Configuration

- **Production enforcement:** When `NODE_ENV=production`, the API will not start unless `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` are set. This avoids running production with default or missing secrets. Optionally enforce `BCRYPT_COST` (or other cost env) in the same way in a future iteration.

## AI Development Protocol

- **Contract-first:** Before changing or adding API behaviour, define or update schemas in `packages/contracts`. All request/response shapes and shared enums live there. No ad-hoc DTOs in apps.
- **Engine-first:** Business rules (training, nutrition, validation) are implemented only in `packages/engine-rules` as pure functions. API and worker orchestrate and persist; they do not contain business logic. Add or change behaviour in engine-rules first, then call from backend.
- **Phase tagging:** Work is scoped by phase. Each phase ends with a git tag (e.g. `phase-1-foundations`). Do not implement tasks from a later phase in the current phase. See [PHASES.md](PHASES.md) and [FUTURE_TASKS.md](FUTURE_TASKS.md).
