import { describe, expect, it } from 'vitest';
import type { PrismaService } from '../../prisma/prisma.service';
import { FixedClock, prismaMock, UID } from '../../test/unit/support';
import { AUDIT_RETENTION_DAYS, AuditService } from './audit.service';

const NOW = new Date('2026-11-09T10:00:00.000Z');

function setup() {
  const prisma = prismaMock();
  return { prisma, audit: new AuditService(prisma as unknown as PrismaService, new FixedClock(NOW)) };
}

describe('AuditService (issue #17)', () => {
  it('record: solo tipo, usuario y fecha (en la transacción que se le pase)', async () => {
    const { prisma, audit } = setup();
    await audit.record('login_failed', null);
    expect(prisma.auditEvent.create).toHaveBeenCalledWith({ data: { type: 'login_failed', userId: null, createdAt: NOW } });
    const tx = prismaMock();
    await audit.record('health_profile_changed', UID, tx as never);
    expect(tx.auditEvent.create).toHaveBeenCalledWith({ data: { type: 'health_profile_changed', userId: UID, createdAt: NOW } });
  });

  it('recordAccountDeleted: sin userId, con un id aleatorio distinto cada vez', async () => {
    const { prisma, audit } = setup();
    const a = await audit.recordAccountDeleted();
    const b = await audit.recordAccountDeleted();
    expect(a).not.toBe(b);
    expect(prisma.auditEvent.create.mock.calls[0][0].data).toEqual({ type: 'account_deleted', userId: null, subjectRef: a, createdAt: NOW });
  });

  it('forExport: tipo y fecha, sin ids', async () => {
    const { prisma, audit } = setup();
    prisma.auditEvent.findMany.mockResolvedValueOnce([{ type: 'login_succeeded', createdAt: NOW }]);
    expect(await audit.forExport(UID)).toEqual([{ type: 'login_succeeded', occurredAt: NOW.toISOString() }]);
    expect(prisma.auditEvent.findMany.mock.calls[0][0].where).toEqual({ userId: UID });
  });

  it(`cleanup: borra lo anterior a ${AUDIT_RETENTION_DAYS} días`, async () => {
    const { prisma, audit } = setup();
    prisma.auditEvent.deleteMany.mockResolvedValueOnce({ count: 3 });
    expect(await audit.cleanup()).toBe(3);
    const cutoff: Date = prisma.auditEvent.deleteMany.mock.calls[0][0].where.createdAt.lt;
    expect(cutoff.toISOString()).toBe('2026-05-13T10:00:00.000Z');
  });
});
