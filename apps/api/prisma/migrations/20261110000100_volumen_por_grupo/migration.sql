-- Volumen semanal por grupo con la regla del motor (PROGRAMACION.md §16.1: por serie, la
-- máxima fracción de los músculos del ejercicio en ese grupo). Proyección nueva: tras
-- desplegar, ejecutar `pnpm --filter @pipos/api analytics:rebuild` para rellenarla desde
-- SetLog (docs/DEPLOY_CHECKLIST.md).

-- CreateEnum
CREATE TYPE "VolumeGroup" AS ENUM ('chest', 'back', 'shoulders', 'biceps', 'triceps', 'quads', 'hamstrings', 'glutes', 'calves', 'core');

-- CreateTable
CREATE TABLE "WeeklyGroupVolume" (
    "userId" UUID NOT NULL,
    "weekStart" DATE NOT NULL,
    "group" "VolumeGroup" NOT NULL,
    "effectiveSets" DECIMAL(6,2) NOT NULL,
    "formulaVersion" VARCHAR(16) NOT NULL,
    "computedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WeeklyGroupVolume_pkey" PRIMARY KEY ("userId","weekStart","group")
);

-- AddForeignKey
ALTER TABLE "WeeklyGroupVolume" ADD CONSTRAINT "WeeklyGroupVolume_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
