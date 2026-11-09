-- AlterTable
ALTER TABLE "WorkoutSession" ADD COLUMN     "adjustedMinutes" SMALLINT,
ADD COLUMN     "reducedVolume" BOOLEAN NOT NULL DEFAULT false;


-- RAW: minutos disponibles dentro del rango del contrato (15-90).
ALTER TABLE "WorkoutSession" ADD CONSTRAINT "WorkoutSession_adjustedMinutes_range" CHECK ("adjustedMinutes" IS NULL OR "adjustedMinutes" BETWEEN 15 AND 90);
