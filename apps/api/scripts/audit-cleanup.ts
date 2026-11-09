/**
 * Retención del registro de auditoría (issue #17): borra los AuditEvent con más de
 * AUDIT_RETENTION_DAYS días. Idempotente; pensado para ejecutarse a diario.
 *   pnpm --filter @pipos/api audit:cleanup
 */
import 'reflect-metadata';
import { Clock } from '../src/common/clock';
import { AUDIT_RETENTION_DAYS, AuditService } from '../src/modules/audit/audit.service';
import { loadDotEnv } from '../src/config/dotenv';
import { PrismaService } from '../src/prisma/prisma.service';

async function main(): Promise<void> {
  loadDotEnv();
  const prisma = new PrismaService();
  try {
    const deleted = await new AuditService(prisma, new Clock()).cleanup();
    console.log(JSON.stringify({ level: 'info', message: 'audit events cleaned up', retentionDays: AUDIT_RETENTION_DAYS, deleted }));
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(JSON.stringify({ level: 'error', message: 'audit cleanup failed', name: (error as Error)?.name }));
  process.exit(1);
});
