-- AlterTable
ALTER TABLE "PlanVersion" ADD COLUMN     "idempotencyHash" CHAR(64),
ADD COLUMN     "idempotencyKey" VARCHAR(128);

-- CreateIndex
CREATE UNIQUE INDEX "PlanVersion_userId_idempotencyKey_key" ON "PlanVersion"("userId", "idempotencyKey");

