-- CreateEnum
CREATE TYPE "TrainingLocation" AS ENUM ('home', 'gym', 'calisthenics');

-- AlterTable
ALTER TABLE "User" ADD COLUMN "passwordHash" TEXT NOT NULL DEFAULT '',
ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN "heightCm" DOUBLE PRECISION,
ADD COLUMN "weightKg" DOUBLE PRECISION,
ADD COLUMN "age" INTEGER,
ADD COLUMN "sex" TEXT,
ADD COLUMN "trainingLevel" TEXT,
ADD COLUMN "preferredTrainingDays" INTEGER,
ADD COLUMN "availableEquipment" JSONB,
ADD COLUMN "trainingLocation" "TrainingLocation",
ADD COLUMN "goals" JSONB,
ADD COLUMN "muscleFocus" JSONB;

-- CreateTable
CREATE TABLE "RefreshToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RefreshToken_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "RefreshToken_userId_idx" ON "RefreshToken"("userId");

-- AddForeignKey
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
