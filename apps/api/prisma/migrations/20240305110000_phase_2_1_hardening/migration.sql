-- AlterTable User: add emailNormalized
ALTER TABLE "User" ADD COLUMN "emailNormalized" TEXT;

UPDATE "User" SET "emailNormalized" = LOWER(TRIM("email")) WHERE "emailNormalized" IS NULL;

ALTER TABLE "User" ALTER COLUMN "emailNormalized" SET NOT NULL;

DROP INDEX IF EXISTS "User_email_key";

CREATE UNIQUE INDEX "User_emailNormalized_key" ON "User"("emailNormalized");

-- AlterTable RefreshToken: revocation and rotation
ALTER TABLE "RefreshToken" ADD COLUMN "revokedAt" TIMESTAMP(3),
ADD COLUMN "replacedByTokenId" TEXT,
ADD COLUMN "createdByIp" TEXT,
ADD COLUMN "userAgent" TEXT;

-- AddForeignKey (self-relation for rotation)
ALTER TABLE "RefreshToken" ADD CONSTRAINT "RefreshToken_replacedByTokenId_fkey" 
  FOREIGN KEY ("replacedByTokenId") REFERENCES "RefreshToken"("id") ON DELETE SET NULL ON UPDATE CASCADE;
