-- Vídeos e imágenes del catálogo (ADR-0014, Fase 4). Las imágenes son ficheros del paquete
-- del catálogo con crédito y licencia declarados; los vídeos, un videoId concreto de YouTube.
-- AlterTable
ALTER TABLE "ExerciseMedia" ADD COLUMN     "credit" VARCHAR(120),
ADD COLUMN     "file" VARCHAR(96),
ADD COLUMN     "licence" VARCHAR(32);

-- RAW: una imagen necesita fichero (o URL), crédito y licencia; un vídeo, su videoId.
ALTER TABLE "ExerciseMedia" DROP CONSTRAINT media_source_chk;
ALTER TABLE "ExerciseMedia" ADD CONSTRAINT media_source_chk CHECK (
  ("kind" = 'youtube' AND "externalId" IS NOT NULL)
  OR ("kind" = 'image' AND ("file" IS NOT NULL OR "url" IS NOT NULL) AND "credit" IS NOT NULL AND "licence" IS NOT NULL)
);
