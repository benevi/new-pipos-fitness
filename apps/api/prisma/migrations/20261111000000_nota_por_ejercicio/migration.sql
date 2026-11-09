-- CreateTable
CREATE TABLE "UserExerciseNote" (
    "userId" UUID NOT NULL,
    "exerciseId" UUID NOT NULL,
    "text" VARCHAR(280) NOT NULL,
    "clientUpdatedAt" TIMESTAMPTZ(3) NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "UserExerciseNote_pkey" PRIMARY KEY ("userId","exerciseId")
);

-- CreateIndex
CREATE INDEX "UserExerciseNote_exerciseId_idx" ON "UserExerciseNote"("exerciseId");

-- AddForeignKey
ALTER TABLE "UserExerciseNote" ADD CONSTRAINT "UserExerciseNote_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UserExerciseNote" ADD CONSTRAINT "UserExerciseNote_exerciseId_fkey" FOREIGN KEY ("exerciseId") REFERENCES "Exercise"("id") ON DELETE RESTRICT ON UPDATE CASCADE;


-- RAW: una nota no puede quedar en blanco (el contrato ya lo exige; defensa en BD).
ALTER TABLE "UserExerciseNote" ADD CONSTRAINT "UserExerciseNote_text_not_blank" CHECK (length(btrim("text")) > 0);
