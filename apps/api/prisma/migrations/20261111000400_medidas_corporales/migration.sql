-- CreateTable
CREATE TABLE "BodyMeasurement" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "measuredOn" DATE NOT NULL,
    "weightKg" DECIMAL(5,2),
    "waistCm" DECIMAL(5,1),
    "neckCm" DECIMAL(5,1),
    "hipCm" DECIMAL(5,1),
    "chestCm" DECIMAL(5,1),
    "armCm" DECIMAL(5,1),
    "thighCm" DECIMAL(5,1),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "BodyMeasurement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "BodyMeasurement_userId_measuredOn_key" ON "BodyMeasurement"("userId", "measuredOn");

-- AddForeignKey
ALTER TABLE "BodyMeasurement" ADD CONSTRAINT "BodyMeasurement_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- RAW: al menos una medida por fila (el contrato ya lo exige; defensa en BD).
ALTER TABLE "BodyMeasurement" ADD CONSTRAINT "BodyMeasurement_any_value" CHECK (num_nonnulls("weightKg", "waistCm", "neckCm", "hipCm", "chestCm", "armCm", "thighCm") > 0);
