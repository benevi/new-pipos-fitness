-- CreateEnum
CREATE TYPE "Role" AS ENUM ('user', 'admin');

-- CreateEnum
CREATE TYPE "Locale" AS ENUM ('es', 'en');

-- CreateEnum
CREATE TYPE "Sex" AS ENUM ('male', 'female', 'other');

-- CreateEnum
CREATE TYPE "TrainingGoal" AS ENUM ('strength', 'hypertrophy', 'general_health', 'fat_loss', 'muscular_endurance');

-- CreateEnum
CREATE TYPE "TrainingLevel" AS ENUM ('beginner', 'intermediate', 'advanced');

-- CreateEnum
CREATE TYPE "ActivityLevel" AS ENUM ('sedentary_light', 'active', 'vigorous');

-- CreateEnum
CREATE TYPE "Equipment" AS ENUM ('bodyweight', 'barbell', 'ez_bar', 'trap_bar', 'dumbbell', 'kettlebell', 'weight_plate', 'bench', 'squat_rack', 'cable', 'machine', 'smith_machine', 'pull_up_bar', 'dip_station', 'gymnastic_rings', 'suspension_trainer', 'resistance_band', 'medicine_ball', 'plyo_box');

-- CreateEnum
CREATE TYPE "BodyZone" AS ENUM ('shoulder', 'elbow', 'wrist', 'lumbar', 'hip', 'knee', 'ankle');

-- CreateEnum
CREATE TYPE "Muscle" AS ENUM ('chest', 'front_delts', 'side_delts', 'rear_delts', 'lats', 'upper_back', 'traps', 'biceps', 'triceps', 'forearms', 'abs', 'obliques', 'lower_back', 'glutes', 'quads', 'hamstrings', 'adductors', 'abductors', 'calves');

-- CreateEnum
CREATE TYPE "MuscleRole" AS ENUM ('primary', 'secondary');

-- CreateEnum
CREATE TYPE "MovementPattern" AS ENUM ('squat', 'hinge', 'lunge', 'horizontal_push', 'vertical_push', 'horizontal_pull', 'vertical_pull', 'elbow_flexion', 'elbow_extension', 'shoulder_isolation', 'knee_extension', 'knee_flexion', 'hip_isolation', 'calf_raise', 'core_anti_extension', 'core_anti_rotation', 'core_flexion', 'carry');

-- CreateEnum
CREATE TYPE "LoadType" AS ENUM ('weighted', 'unweighted');

-- CreateEnum
CREATE TYPE "RiskLevel" AS ENUM ('caution', 'avoid');

-- CreateEnum
CREATE TYPE "ExercisePreferenceKind" AS ENUM ('banned', 'favourite');

-- CreateEnum
CREATE TYPE "MediaKind" AS ENUM ('youtube', 'image');

-- CreateEnum
CREATE TYPE "ModerationStatus" AS ENUM ('pending', 'approved', 'rejected', 'unavailable');

-- CreateEnum
CREATE TYPE "ConsentPurpose" AS ENUM ('health_data_processing');

-- CreateEnum
CREATE TYPE "ConsentAction" AS ENUM ('granted', 'withdrawn');

-- CreateEnum
CREATE TYPE "RefreshTokenRevokeReason" AS ENUM ('rotated', 'logout', 'reuse_detected', 'password_changed', 'account_deleted', 'admin');

-- CreateEnum
CREATE TYPE "PlanStatus" AS ENUM ('active', 'archived');

-- CreateEnum
CREATE TYPE "SessionKind" AS ENUM ('full_body', 'upper', 'lower', 'push', 'pull', 'legs');

-- CreateEnum
CREATE TYPE "ExerciseRole" AS ENUM ('main', 'secondary', 'accessory', 'core');

-- CreateEnum
CREATE TYPE "WorkoutStatus" AS ENUM ('in_progress', 'completed', 'abandoned');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "emailNormalized" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'user',
    "locale" "Locale" NOT NULL DEFAULT 'es',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "familyId" UUID NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "rotatedAt" TIMESTAMPTZ(3),
    "revokedAt" TIMESTAMPTZ(3),
    "revokedReason" "RefreshTokenRevokeReason",
    "replacedById" UUID,
    "createdByIp" INET,
    "userAgent" VARCHAR(512),

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingProfile" (
    "userId" UUID NOT NULL,
    "goal" "TrainingGoal" NOT NULL,
    "level" "TrainingLevel" NOT NULL,
    "daysPerWeek" SMALLINT NOT NULL,
    "minutesPerSession" SMALLINT NOT NULL,
    "equipment" "Equipment"[],
    "priorityMuscles" "Muscle"[],
    "timezone" VARCHAR(64) NOT NULL,
    "activityLevel" "ActivityLevel",
    "limitations" "BodyZone"[] DEFAULT ARRAY[]::"BodyZone"[],
    "weightKg" DECIMAL(5,2),
    "heightCm" DECIMAL(5,1),
    "birthYear" SMALLINT,
    "sex" "Sex",
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "TrainingProfile_pkey" PRIMARY KEY ("userId")
);

-- CreateTable
CREATE TABLE "UserExercisePreference" (
    "userId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "kind" "ExercisePreferenceKind" NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserExercisePreference_pkey" PRIMARY KEY ("userId","exerciseId")
);

-- CreateTable
CREATE TABLE "ConsentEvent" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "purpose" "ConsentPurpose" NOT NULL,
    "action" "ConsentAction" NOT NULL,
    "policyVersion" VARCHAR(32) NOT NULL,
    "textHash" CHAR(64) NOT NULL,
    "locale" "Locale" NOT NULL,
    "occurredAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ip" INET,
    "userAgent" VARCHAR(512),

    CONSTRAINT "ConsentEvent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubstitutionGroup" (
    "id" UUID NOT NULL,
    "key" VARCHAR(64) NOT NULL,

    CONSTRAINT "SubstitutionGroup_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Exercise" (
    "id" UUID NOT NULL,
    "slug" VARCHAR(96) NOT NULL,
    "nameEs" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "descriptionEs" TEXT,
    "descriptionEn" TEXT,
    "movementPattern" "MovementPattern" NOT NULL,
    "isCompound" BOOLEAN NOT NULL,
    "isUnilateral" BOOLEAN NOT NULL DEFAULT false,
    "minLevel" "TrainingLevel" NOT NULL,
    "equipment" "Equipment"[],
    "loadType" "LoadType" NOT NULL,
    "substitutionGroupId" UUID,
    "cuesEs" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "cuesEn" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "deletedAt" TIMESTAMPTZ(3),

    CONSTRAINT "Exercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExerciseMuscle" (
    "exerciseId" UUID NOT NULL,
    "muscle" "Muscle" NOT NULL,
    "role" "MuscleRole" NOT NULL,
    "fraction" DECIMAL(3,2) NOT NULL,

    CONSTRAINT "ExerciseMuscle_pkey" PRIMARY KEY ("exerciseId","muscle")
);

-- CreateTable
CREATE TABLE "ExerciseRiskTag" (
    "exerciseId" UUID NOT NULL,
    "zone" "BodyZone" NOT NULL,
    "level" "RiskLevel" NOT NULL,

    CONSTRAINT "ExerciseRiskTag_pkey" PRIMARY KEY ("exerciseId","zone")
);

-- CreateTable
CREATE TABLE "ExerciseMedia" (
    "id" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "kind" "MediaKind" NOT NULL,
    "externalId" VARCHAR(64),
    "url" TEXT,
    "channelName" TEXT,
    "startSeconds" INTEGER,
    "endSeconds" INTEGER,
    "locale" "Locale",
    "isPrimary" BOOLEAN NOT NULL DEFAULT false,
    "moderationStatus" "ModerationStatus" NOT NULL DEFAULT 'pending',
    "moderatedById" UUID,
    "moderatedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExerciseMedia_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TrainingPlan" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "status" "PlanStatus" NOT NULL DEFAULT 'active',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "TrainingPlan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlanVersion" (
    "id" UUID NOT NULL,
    "planId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "engineVersion" VARCHAR(32) NOT NULL,
    "objectiveScore" DOUBLE PRECISION NOT NULL,
    "mesocycleWeeks" SMALLINT NOT NULL,
    "rationale" JSONB NOT NULL,
    "inputSnapshot" JSONB NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlanVersion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlanSession" (
    "id" UUID NOT NULL,
    "planVersionId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "dayIndex" SMALLINT NOT NULL,
    "order" SMALLINT NOT NULL,
    "kind" "SessionKind" NOT NULL,
    "name" TEXT NOT NULL,
    "targetMinutes" SMALLINT NOT NULL,
    "estimatedMinutes" DOUBLE PRECISION NOT NULL,
    "rationale" JSONB,

    CONSTRAINT "PlanSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlanExercise" (
    "id" UUID NOT NULL,
    "planSessionId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "order" SMALLINT NOT NULL,
    "role" "ExerciseRole" NOT NULL,
    "sets" SMALLINT NOT NULL,
    "repMin" SMALLINT NOT NULL,
    "repMax" SMALLINT NOT NULL,
    "targetRir" SMALLINT NOT NULL,
    "restSeconds" SMALLINT NOT NULL,
    "initialLoadKg" DECIMAL(6,2),
    "initialLoadIsEstimate" BOOLEAN NOT NULL DEFAULT true,
    "warmupSets" JSONB NOT NULL,
    "estimatedMinutes" DOUBLE PRECISION NOT NULL,
    "rationale" JSONB,

    CONSTRAINT "PlanExercise_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutSession" (
    "id" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "planSessionId" UUID NOT NULL,
    "status" "WorkoutStatus" NOT NULL DEFAULT 'in_progress',
    "startedAt" TIMESTAMPTZ(3) NOT NULL,
    "completedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "WorkoutSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SetLog" (
    "id" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "workoutSessionId" UUID NOT NULL,
    "planExerciseId" UUID,
    "exerciseId" UUID NOT NULL,
    "setIndex" SMALLINT NOT NULL,
    "reps" SMALLINT NOT NULL,
    "loadKg" DECIMAL(6,2) NOT NULL,
    "rir" SMALLINT,
    "isWarmup" BOOLEAN NOT NULL DEFAULT false,
    "completedAt" TIMESTAMPTZ(3) NOT NULL,
    "clientUpdatedAt" TIMESTAMPTZ(3) NOT NULL,
    "deletedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "SetLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WorkoutSubstitution" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "workoutSessionId" UUID NOT NULL,
    "planExerciseId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "WorkoutSubstitution_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExerciseE1rm" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "workoutSessionId" UUID NOT NULL,
    "performedOn" DATE NOT NULL,
    "e1rmKg" DECIMAL(6,2) NOT NULL,
    "sourceSetLogId" UUID,
    "formulaVersion" VARCHAR(16) NOT NULL,
    "computedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExerciseE1rm_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WeeklyMuscleVolume" (
    "userId" UUID NOT NULL,
    "weekStart" DATE NOT NULL,
    "muscle" "Muscle" NOT NULL,
    "effectiveSets" DECIMAL(6,2) NOT NULL,
    "tonnageKg" DECIMAL(10,2) NOT NULL,
    "formulaVersion" VARCHAR(16) NOT NULL,
    "computedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyMuscleVolume_pkey" PRIMARY KEY ("userId","weekStart","muscle")
);

-- CreateTable
CREATE TABLE "WeeklyAdherence" (
    "userId" UUID NOT NULL,
    "weekStart" DATE NOT NULL,
    "plannedSessions" SMALLINT NOT NULL,
    "completedSessions" SMALLINT NOT NULL,
    "plannedSets" SMALLINT NOT NULL,
    "completedSets" SMALLINT NOT NULL,
    "planVersionId" UUID,
    "computedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyAdherence_pkey" PRIMARY KEY ("userId","weekStart")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_emailNormalized_key" ON "User"("emailNormalized");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_tokenHash_key" ON "RefreshToken"("tokenHash");

-- CreateIndex
CREATE UNIQUE INDEX "RefreshToken_replacedById_key" ON "RefreshToken"("replacedById");

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- CreateIndex
CREATE INDEX "RefreshToken_familyId_idx" ON "RefreshToken"("familyId");

-- CreateIndex
CREATE INDEX "RefreshToken_expiresAt_idx" ON "RefreshToken"("expiresAt");

-- CreateIndex
CREATE INDEX "UserExercisePreference_exerciseId_idx" ON "UserExercisePreference"("exerciseId");

-- CreateIndex
CREATE INDEX "ConsentEvent_userId_purpose_occurredAt_idx" ON "ConsentEvent"("userId", "purpose", "occurredAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "SubstitutionGroup_key_key" ON "SubstitutionGroup"("key");

-- CreateIndex
CREATE UNIQUE INDEX "Exercise_slug_key" ON "Exercise"("slug");

-- CreateIndex
CREATE INDEX "Exercise_movementPattern_idx" ON "Exercise"("movementPattern");

-- CreateIndex
CREATE INDEX "Exercise_substitutionGroupId_idx" ON "Exercise"("substitutionGroupId");

-- CreateIndex
CREATE INDEX "Exercise_equipment_idx" ON "Exercise" USING GIN ("equipment");

-- CreateIndex
CREATE INDEX "ExerciseMuscle_muscle_role_idx" ON "ExerciseMuscle"("muscle", "role");

-- CreateIndex
CREATE INDEX "ExerciseRiskTag_zone_idx" ON "ExerciseRiskTag"("zone");

-- CreateIndex
CREATE INDEX "ExerciseMedia_exerciseId_moderationStatus_idx" ON "ExerciseMedia"("exerciseId", "moderationStatus");

-- CreateIndex
CREATE INDEX "ExerciseMedia_moderationStatus_createdAt_idx" ON "ExerciseMedia"("moderationStatus", "createdAt");

-- CreateIndex
CREATE INDEX "TrainingPlan_userId_status_idx" ON "TrainingPlan"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "TrainingPlan_id_userId_key" ON "TrainingPlan"("id", "userId");

-- CreateIndex
CREATE INDEX "PlanVersion_userId_createdAt_idx" ON "PlanVersion"("userId", "createdAt" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "PlanVersion_planId_version_key" ON "PlanVersion"("planId", "version");

-- CreateIndex
CREATE UNIQUE INDEX "PlanVersion_id_userId_key" ON "PlanVersion"("id", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "PlanSession_planVersionId_order_key" ON "PlanSession"("planVersionId", "order");

-- CreateIndex
CREATE UNIQUE INDEX "PlanSession_planVersionId_dayIndex_key" ON "PlanSession"("planVersionId", "dayIndex");

-- CreateIndex
CREATE UNIQUE INDEX "PlanSession_id_userId_key" ON "PlanSession"("id", "userId");

-- CreateIndex
CREATE INDEX "PlanExercise_exerciseId_idx" ON "PlanExercise"("exerciseId");

-- CreateIndex
CREATE UNIQUE INDEX "PlanExercise_planSessionId_order_key" ON "PlanExercise"("planSessionId", "order");

-- CreateIndex
CREATE INDEX "WorkoutSession_userId_startedAt_idx" ON "WorkoutSession"("userId", "startedAt" DESC);

-- CreateIndex
CREATE INDEX "WorkoutSession_planSessionId_idx" ON "WorkoutSession"("planSessionId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkoutSession_userId_clientId_key" ON "WorkoutSession"("userId", "clientId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkoutSession_id_userId_key" ON "WorkoutSession"("id", "userId");

-- CreateIndex
CREATE INDEX "SetLog_workoutSessionId_exerciseId_setIndex_idx" ON "SetLog"("workoutSessionId", "exerciseId", "setIndex");

-- CreateIndex
CREATE INDEX "SetLog_userId_exerciseId_completedAt_idx" ON "SetLog"("userId", "exerciseId", "completedAt" DESC);

-- CreateIndex
CREATE INDEX "SetLog_planExerciseId_idx" ON "SetLog"("planExerciseId");

-- CreateIndex
CREATE UNIQUE INDEX "SetLog_userId_clientId_key" ON "SetLog"("userId", "clientId");

-- CreateIndex
CREATE INDEX "WorkoutSubstitution_userId_idx" ON "WorkoutSubstitution"("userId");

-- CreateIndex
CREATE INDEX "WorkoutSubstitution_planExerciseId_idx" ON "WorkoutSubstitution"("planExerciseId");

-- CreateIndex
CREATE INDEX "WorkoutSubstitution_exerciseId_idx" ON "WorkoutSubstitution"("exerciseId");

-- CreateIndex
CREATE UNIQUE INDEX "WorkoutSubstitution_workoutSessionId_planExerciseId_key" ON "WorkoutSubstitution"("workoutSessionId", "planExerciseId");

-- CreateIndex
CREATE INDEX "ExerciseE1rm_userId_exerciseId_performedOn_idx" ON "ExerciseE1rm"("userId", "exerciseId", "performedOn" DESC);

-- CreateIndex
CREATE INDEX "ExerciseE1rm_workoutSessionId_idx" ON "ExerciseE1rm"("workoutSessionId");

-- CreateIndex
CREATE INDEX "ExerciseE1rm_exerciseId_idx" ON "ExerciseE1rm"("exerciseId");

-- CreateIndex
CREATE UNIQUE INDEX "ExerciseE1rm_userId_exerciseId_workoutSessionId_key" ON "ExerciseE1rm"("userId", "exerciseId", "workoutSessionId");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_replacedById_fkey" FOREIGN KEY ("replacedById") REFERENCES "RefreshToken"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingProfile" ADD CONSTRAINT "TrainingProfile_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserExercisePreference" ADD CONSTRAINT "UserExercisePreference_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserExercisePreference" ADD CONSTRAINT "UserExercisePreference_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ConsentEvent" ADD CONSTRAINT "ConsentEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Exercise" ADD CONSTRAINT "Exercise_substitutionGroupId_fkey" FOREIGN KEY ("substitutionGroupId") REFERENCES "SubstitutionGroup"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseMuscle" ADD CONSTRAINT "ExerciseMuscle_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseRiskTag" ADD CONSTRAINT "ExerciseRiskTag_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseMedia" ADD CONSTRAINT "ExerciseMedia_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseMedia" ADD CONSTRAINT "ExerciseMedia_moderatedById_fkey" FOREIGN KEY ("moderatedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TrainingPlan" ADD CONSTRAINT "TrainingPlan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanVersion" ADD CONSTRAINT "PlanVersion_planId_userId_fkey" FOREIGN KEY ("planId", "userId") REFERENCES "TrainingPlan"("id", "userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanSession" ADD CONSTRAINT "PlanSession_planVersionId_userId_fkey" FOREIGN KEY ("planVersionId", "userId") REFERENCES "PlanVersion"("id", "userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanExercise" ADD CONSTRAINT "PlanExercise_planSessionId_fkey" FOREIGN KEY ("planSessionId") REFERENCES "PlanSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanExercise" ADD CONSTRAINT "PlanExercise_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_planSessionId_userId_fkey" FOREIGN KEY ("planSessionId", "userId") REFERENCES "PlanSession"("id", "userId") ON DELETE NO ACTION ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SetLog" ADD CONSTRAINT "SetLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SetLog" ADD CONSTRAINT "SetLog_workoutSessionId_userId_fkey" FOREIGN KEY ("workoutSessionId", "userId") REFERENCES "WorkoutSession"("id", "userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SetLog" ADD CONSTRAINT "SetLog_planExerciseId_fkey" FOREIGN KEY ("planExerciseId") REFERENCES "PlanExercise"("id") ON DELETE NO ACTION ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SetLog" ADD CONSTRAINT "SetLog_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSubstitution" ADD CONSTRAINT "WorkoutSubstitution_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSubstitution" ADD CONSTRAINT "WorkoutSubstitution_workoutSessionId_userId_fkey" FOREIGN KEY ("workoutSessionId", "userId") REFERENCES "WorkoutSession"("id", "userId") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSubstitution" ADD CONSTRAINT "WorkoutSubstitution_planExerciseId_fkey" FOREIGN KEY ("planExerciseId") REFERENCES "PlanExercise"("id") ON DELETE NO ACTION ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WorkoutSubstitution" ADD CONSTRAINT "WorkoutSubstitution_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseE1rm" ADD CONSTRAINT "ExerciseE1rm_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseE1rm" ADD CONSTRAINT "ExerciseE1rm_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExerciseE1rm" ADD CONSTRAINT "ExerciseE1rm_workoutSessionId_fkey" FOREIGN KEY ("workoutSessionId") REFERENCES "WorkoutSession"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WeeklyMuscleVolume" ADD CONSTRAINT "WeeklyMuscleVolume_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WeeklyAdherence" ADD CONSTRAINT "WeeklyAdherence_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ─────────────────────────────────────────────────────────────
-- RAW: restricciones no expresables en Prisma (docs/MODELO_DATOS.md §6).
-- No generan deriva en `prisma migrate diff` porque Prisma no las modela.
-- ─────────────────────────────────────────────────────────────

-- Perfil
ALTER TABLE "TrainingProfile"
  ADD CONSTRAINT tp_days_chk       CHECK ("daysPerWeek" BETWEEN 2 AND 6),
  ADD CONSTRAINT tp_minutes_chk    CHECK ("minutesPerSession" BETWEEN 30 AND 90),
  ADD CONSTRAINT tp_weight_chk     CHECK ("weightKg" IS NULL OR "weightKg" BETWEEN 25 AND 400),
  ADD CONSTRAINT tp_height_chk     CHECK ("heightCm" IS NULL OR "heightCm" BETWEEN 100 AND 250),
  ADD CONSTRAINT tp_birth_year_chk CHECK ("birthYear" IS NULL OR "birthYear" BETWEEN 1900 AND 2100),
  ADD CONSTRAINT tp_priority_chk   CHECK (cardinality("priorityMuscles") <= 3),
  ADD CONSTRAINT tp_timezone_chk   CHECK (length("timezone") >= 1);

-- Catálogo
ALTER TABLE "Exercise" ADD CONSTRAINT ex_equipment_nonempty CHECK (cardinality("equipment") >= 1);
ALTER TABLE "ExerciseMuscle" ADD CONSTRAINT em_fraction_chk CHECK ("fraction" > 0 AND "fraction" <= 1);
ALTER TABLE "ExerciseMedia"
  ADD CONSTRAINT media_range_chk  CHECK ("endSeconds" IS NULL OR "startSeconds" IS NULL OR "endSeconds" > "startSeconds"),
  ADD CONSTRAINT media_source_chk CHECK (("kind" = 'youtube' AND "externalId" IS NOT NULL) OR ("kind" = 'image' AND "url" IS NOT NULL));
CREATE UNIQUE INDEX media_one_primary ON "ExerciseMedia"("exerciseId")
  WHERE "isPrimary" AND "moderationStatus" = 'approved';
CREATE INDEX exercise_active_level ON "Exercise"("minLevel", "movementPattern") WHERE "deletedAt" IS NULL;

-- Planes
CREATE UNIQUE INDEX plan_one_active_per_user ON "TrainingPlan"("userId") WHERE "status" = 'active';
ALTER TABLE "PlanVersion"
  ADD CONSTRAINT pv_meso_chk    CHECK ("mesocycleWeeks" BETWEEN 1 AND 16),
  ADD CONSTRAINT pv_version_chk CHECK ("version" >= 1);
ALTER TABLE "PlanSession"
  ADD CONSTRAINT ps_day_chk     CHECK ("dayIndex" BETWEEN 0 AND 6),
  ADD CONSTRAINT ps_minutes_chk CHECK ("targetMinutes" BETWEEN 30 AND 90);
ALTER TABLE "PlanExercise"
  ADD CONSTRAINT pe_sets_chk CHECK ("sets" BETWEEN 1 AND 10),
  ADD CONSTRAINT pe_reps_chk CHECK ("repMin" >= 1 AND "repMin" <= "repMax" AND "repMax" <= 50),
  ADD CONSTRAINT pe_rir_chk  CHECK ("targetRir" BETWEEN 0 AND 5),
  ADD CONSTRAINT pe_rest_chk CHECK ("restSeconds" BETWEEN 15 AND 600),
  ADD CONSTRAINT pe_load_chk CHECK ("initialLoadKg" IS NULL OR "initialLoadKg" >= 0);

-- Registro
ALTER TABLE "WorkoutSession" ADD CONSTRAINT ws_time_chk CHECK ("completedAt" IS NULL OR "completedAt" >= "startedAt");
CREATE UNIQUE INDEX ws_one_in_progress ON "WorkoutSession"("userId") WHERE "status" = 'in_progress';
ALTER TABLE "SetLog"
  ADD CONSTRAINT sl_reps_chk      CHECK ("reps" BETWEEN 0 AND 100),
  ADD CONSTRAINT sl_load_chk      CHECK ("loadKg" >= 0),
  ADD CONSTRAINT sl_rir_chk       CHECK ("rir" IS NULL OR "rir" BETWEEN 0 AND 10),
  ADD CONSTRAINT sl_set_index_chk CHECK ("setIndex" BETWEEN 0 AND 50);

-- Analítica
ALTER TABLE "WeeklyMuscleVolume" ADD CONSTRAINT wmv_sets_chk CHECK ("effectiveSets" >= 0 AND "tonnageKg" >= 0);
ALTER TABLE "WeeklyAdherence"
  ADD CONSTRAINT wa_counts_chk CHECK ("plannedSessions" >= 0 AND "completedSessions" >= 0 AND "plannedSets" >= 0 AND "completedSets" >= 0);
