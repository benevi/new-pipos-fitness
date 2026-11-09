-- CreateTable
CREATE TABLE "ThrottlerRecord" (
    "key" VARCHAR(128) NOT NULL,
    "hits" INTEGER NOT NULL,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "blockedUntil" TIMESTAMPTZ(3),

    CONSTRAINT "ThrottlerRecord_pkey" PRIMARY KEY ("key")
);

-- CreateIndex
CREATE INDEX "ThrottlerRecord_expiresAt_idx" ON "ThrottlerRecord"("expiresAt");

