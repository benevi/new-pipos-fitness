-- CreateTable
CREATE TABLE "PlanExerciseOverride" (
    "planExerciseId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlanExerciseOverride_pkey" PRIMARY KEY ("planExerciseId")
);

-- CreateIndex
CREATE INDEX "PlanExerciseOverride_userId_idx" ON "PlanExerciseOverride"("userId");

-- CreateIndex
CREATE INDEX "PlanExerciseOverride_exerciseId_idx" ON "PlanExerciseOverride"("exerciseId");

-- AddForeignKey
ALTER TABLE "PlanExerciseOverride" ADD CONSTRAINT "PlanExerciseOverride_planExerciseId_fkey" FOREIGN KEY ("planExerciseId") REFERENCES "PlanExercise"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanExerciseOverride" ADD CONSTRAINT "PlanExerciseOverride_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlanExerciseOverride" ADD CONSTRAINT "PlanExerciseOverride_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

