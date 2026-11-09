-- Ficha del ejercicio (ADR-0014, Fase 2): errores comunes. La descripción usa la columna
-- existente "descriptionEs".
-- AlterTable
ALTER TABLE "Exercise" ADD COLUMN     "mistakesEs" TEXT[] DEFAULT ARRAY[]::TEXT[];
