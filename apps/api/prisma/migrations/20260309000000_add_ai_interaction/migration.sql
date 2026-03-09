-- CreateTable
CREATE TABLE "AIInteraction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "question" TEXT NOT NULL,
    "responseType" TEXT NOT NULL,
    "proposalType" TEXT,
    "proposalValid" BOOLEAN NOT NULL,
    "contextSummary" JSONB NOT NULL,
    "responseSummary" JSONB NOT NULL,

    CONSTRAINT "AIInteraction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AIInteraction_userId_createdAt_idx" ON "AIInteraction"("userId", "createdAt");

-- AddForeignKey
ALTER TABLE "AIInteraction" ADD CONSTRAINT "AIInteraction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
