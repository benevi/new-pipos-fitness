-- CreateEnum
CREATE TYPE "AuditEventType" AS ENUM ('login_succeeded', 'login_failed', 'refresh_reuse_detected', 'health_consent_granted', 'health_consent_withdrawn', 'health_profile_changed', 'body_measurement_saved', 'body_measurement_deleted', 'account_deleted');

-- CreateTable
CREATE TABLE "AuditEvent" (
    "id" UUID NOT NULL,
    "type" "AuditEventType" NOT NULL,
    "userId" UUID,
    "subjectRef" UUID,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "AuditEvent_userId_createdAt_idx" ON "AuditEvent"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditEvent_createdAt_idx" ON "AuditEvent"("createdAt");

-- AddForeignKey
ALTER TABLE "AuditEvent" ADD CONSTRAINT "AuditEvent_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- RAW: registro append-only (issue #17). Prisma no expresa triggers: escrito a mano.
-- Se permite INSERT y DELETE (retención y borrado de la cuenta en cascada); nunca UPDATE.
CREATE FUNCTION audit_event_append_only() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'AuditEvent is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_event_no_update
  BEFORE UPDATE ON "AuditEvent"
  FOR EACH ROW EXECUTE FUNCTION audit_event_append_only();
