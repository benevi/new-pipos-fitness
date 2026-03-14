# Database status summary

## Configuration

- **DATABASE_URL:** Configured via `apps/api/.env` (loaded by Prisma). Not committed to repo.
- **Location:** Prisma reads `env("DATABASE_URL")` from `schema.prisma` (datasource `db`).
- **Database:** PostgreSQL at `localhost:5432`, database `pipos_fitness`, schema `public`.

## Prisma setup

- **Schema:** `apps/api/prisma/schema.prisma`
- **Scripts (apps/api/package.json):**
  - `prisma:generate` — generate Prisma client
  - `prisma:migrate` — run `prisma migrate dev`
  - `prisma:studio` — open Prisma Studio

## Migration status

- **Before verification:** 5 migrations applied; schema had more tables than migrations (drift).
- **Action taken:** Created and applied migration `20260311222510_add_remaining_tables` so the database matches the current schema.
- **After verification:** 6 migrations in `prisma/migrations`; **database schema is up to date.**

## Migrations in `prisma/migrations`

1. `20240305000000_init` — User
2. `20240305100000_auth_and_user_profile` — RefreshToken, User columns
3. `20240305110000_phase_2_1_hardening` — User emailNormalized, RefreshToken revocation
4. `20240306000000_exercise_catalog` — Muscle, EquipmentItem, Exercise, ExerciseMuscle, ExerciseEquipment, ExerciseVariant, ExerciseMediaYouTube, YouTubeChannel
5. `20260309000000_add_ai_interaction` — AIInteraction
6. `20260311222510_add_remaining_tables` — VolumeTrend enum, ExerciseProgress, TrainingPlan, TrainingPlanVersion, TrainingSession, TrainingSessionExercise, WorkoutSession, WorkoutExercise, WorkoutSet, Food, MealTemplate, MealTemplateFood, NutritionPlan, NutritionPlanVersion, NutritionDay, NutritionMeal, NutritionMealItem; User/RefreshToken alterations

## Core tables (expected after migrations)

| Table | Purpose |
|-------|---------|
| User | Auth and profile |
| RefreshToken | JWT refresh tokens |
| Exercise | Exercise catalog |
| Muscle | Muscle catalog |
| EquipmentItem | Equipment catalog |
| TrainingPlan | User training plan |
| TrainingPlanVersion | Plan version |
| TrainingSession | Session in a plan |
| TrainingSessionExercise | Exercise in a session |
| WorkoutSession | Logged workout |
| WorkoutExercise | Exercise in a workout |
| WorkoutSet | Set in a workout |
| ExerciseProgress | User exercise analytics |
| Food | Food catalog |
| NutritionPlan | User nutrition plan |
| NutritionPlanVersion | Plan version |
| NutritionDay | Day in a plan |
| NutritionMeal | Meal in a day |
| NutritionMealItem | Food item in a meal |
| AIInteraction | AI coach history |

Supporting/junction tables also present: ExerciseMuscle, ExerciseEquipment, ExerciseVariant, ExerciseMediaYouTube, YouTubeChannel, MealTemplate, MealTemplateFood.

## Commands run

1. `npx prisma generate` — failed with EPERM (file lock on query engine DLL; dev server or another process may be holding it).
2. `npx prisma migrate status` — confirmed 5 migrations, DB “up to date” for those 5.
3. `npx prisma migrate dev --name add_remaining_tables --create-only` — created migration for schema drift.
4. `npx prisma migrate dev --name add_remaining_tables` — applied migration; DB now in sync with schema.
5. `npx prisma migrate status` — confirmed 6 migrations, database schema up to date.

## Blocking issues

- **None.** Database is correctly configured and all migrations are applied.
- **EPERM on generate:** If `prisma generate` fails with “operation not permitted, rename … query_engine-windows.dll.node”, stop any process using the API (e.g. `pnpm start:dev`) and run `pnpm prisma:generate` again. This is an environment/lock issue, not a missing table or config issue.

## Summary

| Item | Status |
|------|--------|
| DATABASE_URL configured | Yes (via apps/api/.env) |
| Migrations applied | Yes (6/6) |
| Tables match schema | Yes |
| Tables exist | Yes (all core tables created by migrations above) |
