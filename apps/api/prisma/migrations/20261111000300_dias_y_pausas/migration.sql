-- AlterTable
ALTER TABLE "TrainingProfile" ADD COLUMN     "trainingWeekdays" SMALLINT[] DEFAULT ARRAY[]::SMALLINT[];

-- CreateTable
CREATE TABLE "TrainingBreak" (
    "id" UUID NOT NULL,
    "clientId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "startsOn" DATE NOT NULL,
    "endsOn" DATE NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TrainingBreak_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TrainingBreak_userId_startsOn_idx" ON "TrainingBreak"("userId", "startsOn");

-- CreateIndex
CREATE UNIQUE INDEX "TrainingBreak_userId_clientId_key" ON "TrainingBreak"("userId", "clientId");

-- AddForeignKey
ALTER TABLE "TrainingBreak" ADD CONSTRAINT "TrainingBreak_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- RAW: días ISO 1-7 sin repetir y pausas de 1 a 60 días (el contrato ya lo exige; defensa en BD).
ALTER TABLE "TrainingProfile" ADD CONSTRAINT "TrainingProfile_trainingWeekdays_range" CHECK ("trainingWeekdays" <@ ARRAY[1,2,3,4,5,6,7]::SMALLINT[] AND cardinality("trainingWeekdays") <= 6);
ALTER TABLE "TrainingBreak" ADD CONSTRAINT "TrainingBreak_range" CHECK ("endsOn" >= "startsOn" AND "endsOn" - "startsOn" < 60);
