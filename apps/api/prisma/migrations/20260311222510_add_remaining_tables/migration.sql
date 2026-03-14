-- CreateEnum
CREATE TYPE "VolumeTrend" AS ENUM ('up', 'down', 'stable');

-- DropIndex
DROP INDEX "RefreshToken_userId_idx";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "dislikedFoodIds" JSONB,
ALTER COLUMN "passwordHash" DROP DEFAULT,
ALTER COLUMN "updatedAt" DROP DEFAULT;

-- CreateTable
CREATE TABLE "ExerciseProgress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "estimated1RM" DOUBLE PRECISION,
    "volumeLastWeek" DOUBLE PRECISION,
    "volumeTrend" "VolumeTrend",
    "fatigueScore" DOUBLE PRECISION,
    "lastUpdated" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExerciseProgress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingPlan" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "currentVersionId" TEXT,

    CONSTRAINT "TrainingPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingPlanVersion" (
    "id" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "engineVersion" TEXT NOT NULL,
    "objectiveScore" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "TrainingPlanVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingSession" (
    "id" TEXT NOT NULL,
    "planVersionId" TEXT NOT NULL,
    "sessionIndex" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "targetDurationMinutes" INTEGER NOT NULL,

    CONSTRAINT "TrainingSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "planSessionId" TEXT,
    "planVersionId" TEXT,
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),
    "durationMinutes" INTEGER,
    "notes" TEXT,

    CONSTRAINT "WorkoutSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutExercise" (
    "id" TEXT NOT NULL,
    "workoutSessionId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "order" INTEGER NOT NULL,

    CONSTRAINT "WorkoutExercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutSet" (
    "id" TEXT NOT NULL,
    "workoutExerciseId" TEXT NOT NULL,
    "setIndex" INTEGER NOT NULL,
    "weightKg" DOUBLE PRECISION,
    "reps" INTEGER,
    "rir" INTEGER,
    "completed" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "WorkoutSet_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingSessionExercise" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "exerciseId" TEXT NOT NULL,
    "sets" INTEGER NOT NULL,
    "repRangeMin" INTEGER NOT NULL,
    "repRangeMax" INTEGER NOT NULL,
    "restSeconds" INTEGER NOT NULL,
    "rirTarget" INTEGER NOT NULL,

    CONSTRAINT "TrainingSessionExercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Food" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "caloriesPer100g" DOUBLE PRECISION NOT NULL,
    "proteinPer100g" DOUBLE PRECISION NOT NULL,
    "carbsPer100g" DOUBLE PRECISION NOT NULL,
    "fatPer100g" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "Food_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealTemplate" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "MealTemplate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MealTemplateFood" (
    "id" TEXT NOT NULL,
    "mealTemplateId" TEXT NOT NULL,
    "foodId" TEXT NOT NULL,
    "quantityG" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "MealTemplateFood_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionPlan" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "currentVersionId" TEXT,

    CONSTRAINT "NutritionPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionPlanVersion" (
    "id" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "version" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "engineVersion" TEXT NOT NULL,

    CONSTRAINT "NutritionPlanVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionDay" (
    "id" TEXT NOT NULL,
    "planVersionId" TEXT NOT NULL,
    "dayIndex" INTEGER NOT NULL,

    CONSTRAINT "NutritionDay_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionMeal" (
    "id" TEXT NOT NULL,
    "nutritionDayId" TEXT NOT NULL,
    "mealIndex" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "templateId" TEXT,

    CONSTRAINT "NutritionMeal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NutritionMealItem" (
    "id" TEXT NOT NULL,
    "nutritionMealId" TEXT NOT NULL,
    "foodId" TEXT NOT NULL,
    "quantityG" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "NutritionMealItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ExerciseProgress_userId_idx" ON "ExerciseProgress"("userId");

-- CreateIndex
CREATE INDEX "ExerciseProgress_userId_lastUpdated_idx" ON "ExerciseProgress"("userId", "lastUpdated");

-- CreateIndex
CREATE UNIQUE INDEX "ExerciseProgress_userId_exerciseId_key" ON "ExerciseProgress"("userId", "exerciseId");

-- CreateIndex
CREATE INDEX "TrainingPlan_userId_idx" ON "TrainingPlan"("userId");

-- CreateIndex
CREATE INDEX "TrainingPlanVersion_planId_idx" ON "TrainingPlanVersion"("planId");

-- CreateIndex
CREATE UNIQUE INDEX "TrainingPlanVersion_planId_version_key" ON "TrainingPlanVersion"("planId", "version");

-- CreateIndex
CREATE INDEX "TrainingSession_planVersionId_idx" ON "TrainingSession"("planVersionId");

-- CreateIndex
CREATE UNIQUE INDEX "TrainingSession_planVersionId_sessionIndex_key" ON "TrainingSession"("planVersionId", "sessionIndex");

-- CreateIndex
CREATE INDEX "WorkoutSession_userId_idx" ON "WorkoutSession"("userId");

-- CreateIndex
CREATE INDEX "WorkoutSession_userId_startedAt_idx" ON "WorkoutSession"("userId", "startedAt");

-- CreateIndex
CREATE INDEX "WorkoutSession_planSessionId_idx" ON "WorkoutSession"("planSessionId");

-- CreateIndex
CREATE INDEX "WorkoutSession_planVersionId_idx" ON "WorkoutSession"("planVersionId");

-- CreateIndex
CREATE INDEX "WorkoutExercise_workoutSessionId_idx" ON "WorkoutExercise"("workoutSessionId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkoutExercise_workoutSessionId_order_key" ON "WorkoutExercise"("workoutSessionId", "order");

-- CreateIndex
CREATE INDEX "WorkoutSet_workoutExerciseId_idx" ON "WorkoutSet"("workoutExerciseId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkoutSet_workoutExerciseId_setIndex_key" ON "WorkoutSet"("workoutExerciseId", "setIndex");

-- CreateIndex
CREATE INDEX "TrainingSessionExercise_sessionId_idx" ON "TrainingSessionExercise"("sessionId");

-- CreateIndex
CREATE INDEX "Food_name_idx" ON "Food"("name");

-- CreateIndex
CREATE INDEX "MealTemplate_name_idx" ON "MealTemplate"("name");

-- CreateIndex
CREATE INDEX "MealTemplateFood_mealTemplateId_idx" ON "MealTemplateFood"("mealTemplateId");

-- CreateIndex
CREATE INDEX "MealTemplateFood_foodId_idx" ON "MealTemplateFood"("foodId");

-- CreateIndex
CREATE UNIQUE INDEX "MealTemplateFood_mealTemplateId_foodId_key" ON "MealTemplateFood"("mealTemplateId", "foodId");

-- CreateIndex
CREATE INDEX "NutritionPlan_userId_idx" ON "NutritionPlan"("userId");

-- CreateIndex
CREATE INDEX "NutritionPlanVersion_planId_idx" ON "NutritionPlanVersion"("planId");

-- CreateIndex
CREATE UNIQUE INDEX "NutritionPlanVersion_planId_version_key" ON "NutritionPlanVersion"("planId", "version");

-- CreateIndex
CREATE INDEX "NutritionDay_planVersionId_idx" ON "NutritionDay"("planVersionId");

-- CreateIndex
CREATE UNIQUE INDEX "NutritionDay_planVersionId_dayIndex_key" ON "NutritionDay"("planVersionId", "dayIndex");

-- CreateIndex
CREATE INDEX "NutritionMeal_nutritionDayId_idx" ON "NutritionMeal"("nutritionDayId");

-- CreateIndex
CREATE INDEX "NutritionMeal_templateId_idx" ON "NutritionMeal"("templateId");

-- CreateIndex
CREATE INDEX "NutritionMealItem_nutritionMealId_idx" ON "NutritionMealItem"("nutritionMealId");

-- CreateIndex
CREATE INDEX "NutritionMealItem_foodId_idx" ON "NutritionMealItem"("foodId");

-- AddForeignKey
ALTER TABLE "ExerciseProgress" ADD CONSTRAINT "ExerciseProgress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingPlan" ADD CONSTRAINT "TrainingPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingPlan" ADD CONSTRAINT "TrainingPlan_currentVersionId_fkey" FOREIGN KEY ("currentVersionId") REFERENCES "TrainingPlanVersion"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingPlanVersion" ADD CONSTRAINT "TrainingPlanVersion_planId_fkey" FOREIGN KEY ("planId") REFERENCES "TrainingPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingSession" ADD CONSTRAINT "TrainingSession_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "TrainingPlanVersion"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_planSessionId_fkey" FOREIGN KEY ("planSessionId") REFERENCES "TrainingSession"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "TrainingPlanVersion"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutExercise" ADD CONSTRAINT "WorkoutExercise_workoutSessionId_fkey" FOREIGN KEY ("workoutSessionId") REFERENCES "WorkoutSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutExercise" ADD CONSTRAINT "WorkoutExercise_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSet" ADD CONSTRAINT "WorkoutSet_workoutExerciseId_fkey" FOREIGN KEY ("workoutExerciseId") REFERENCES "WorkoutExercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingSessionExercise" ADD CONSTRAINT "TrainingSessionExercise_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "TrainingSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealTemplateFood" ADD CONSTRAINT "MealTemplateFood_mealTemplateId_fkey" FOREIGN KEY ("mealTemplateId") REFERENCES "MealTemplate"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MealTemplateFood" ADD CONSTRAINT "MealTemplateFood_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "Food"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionPlan" ADD CONSTRAINT "NutritionPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionPlan" ADD CONSTRAINT "NutritionPlan_currentVersionId_fkey" FOREIGN KEY ("currentVersionId") REFERENCES "NutritionPlanVersion"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionPlanVersion" ADD CONSTRAINT "NutritionPlanVersion_planId_fkey" FOREIGN KEY ("planId") REFERENCES "NutritionPlan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionDay" ADD CONSTRAINT "NutritionDay_planVersionId_fkey" FOREIGN KEY ("planVersionId") REFERENCES "NutritionPlanVersion"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionMeal" ADD CONSTRAINT "NutritionMeal_nutritionDayId_fkey" FOREIGN KEY ("nutritionDayId") REFERENCES "NutritionDay"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionMeal" ADD CONSTRAINT "NutritionMeal_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES "MealTemplate"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionMealItem" ADD CONSTRAINT "NutritionMealItem_nutritionMealId_fkey" FOREIGN KEY ("nutritionMealId") REFERENCES "NutritionMeal"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "NutritionMealItem" ADD CONSTRAINT "NutritionMealItem_foodId_fkey" FOREIGN KEY ("foodId") REFERENCES "Food"("id") ON DELETE CASCADE ON UPDATE CASCADE;
