import { describe, expect, it } from 'vitest';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { parseEnv } from '../../config/env';
import type { PrismaService } from '../../prisma/prisma.service';
import { FixedClock, prismaMock, rejectsWithCode, UID } from '../../test/unit/support';
import { AuditService } from '../audit/audit.service';
import { AuthService, hashRefreshToken, normalizeEmail } from './auth.service';

const env = parseEnv({ DATABASE_URL: 'postgresql://x@localhost/db', JWT_ACCESS_SECRET: 'x'.repeat(40) });
const user = { id: UID, email: 'A@b.com', emailNormalized: 'a@b.com', passwordHash: '', role: 'user', locale: 'es' };

function setup() {
  const prisma = prismaMock();
  const clock = new FixedClock();
  const audit = new AuditService(prisma as unknown as PrismaService, clock);
  const service = new AuthService(prisma as unknown as PrismaService, new JwtService({ secret: 's'.repeat(40) }), clock, env, audit);
  return { prisma, clock, service };
}

describe('AuthService', () => {
  it('normaliza el email y hashea el refresh token', () => {
    expect(normalizeEmail('  A@B.Com ')).toBe('a@b.com');
    expect(hashRefreshToken('t')).toMatch(/^[0-9a-f]{64}$/);
  });

  it('register: 409 si existe; si no, crea usuario y emite familia nueva', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValueOnce({ id: 'x' });
    await rejectsWithCode(service.register({ email: 'a@b.com', password: 'password123' }), 'AUTH_EMAIL_TAKEN', 409);

    prisma.user.findUnique.mockResolvedValueOnce(null);
    prisma.user.create.mockResolvedValueOnce(user);
    const res = await service.register({ email: ' A@b.com ', password: 'password123' });
    expect(res.user).toEqual({ id: UID, email: 'A@b.com' });
    const token = prisma.refreshToken.create.mock.calls[0][0].data;
    expect(token.familyId).toBe(token.id);
  });

  it('login: credenciales inválidas → 401 AUTH_INVALID_CREDENTIALS', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValue(null);
    await rejectsWithCode(service.login({ email: 'a@b.com', password: 'x' }), 'AUTH_INVALID_CREDENTIALS', 401);
    prisma.user.findUnique.mockResolvedValue({ ...user, passwordHash: await bcrypt.hash('good-pass', 4) });
    await rejectsWithCode(service.login({ email: 'a@b.com', password: 'bad-pass' }), 'AUTH_INVALID_CREDENTIALS');
    const ok = await service.login({ email: 'a@b.com', password: 'good-pass' });
    expect(ok.accessToken).toEqual(expect.any(String));
    // Auditoría (issue #17): email desconocido sin userId; contraseña mala con userId; éxito.
    expect(prisma.auditEvent.create.mock.calls.map((c) => c[0].data)).toEqual([
      expect.objectContaining({ type: 'login_failed', userId: null }),
      expect.objectContaining({ type: 'login_failed', userId: UID }),
      expect.objectContaining({ type: 'login_succeeded', userId: UID }),
    ]);
    expect(JSON.stringify(prisma.auditEvent.create.mock.calls)).not.toContain('a@b.com');
  });

  it('verifyPassword', async () => {
    const { prisma, service } = setup();
    prisma.user.findUnique.mockResolvedValueOnce({ passwordHash: await bcrypt.hash('pw', 4) });
    expect(await service.verifyPassword(UID, 'pw')).toBe(true);
    prisma.user.findUnique.mockResolvedValueOnce(null);
    expect(await service.verifyPassword(UID, 'pw')).toBe(false);
  });

  describe('refresh', () => {
    const stored = (over: Record<string, unknown> = {}) => ({
      id: 't1', userId: UID, familyId: 't1', expiresAt: new Date('2027-01-01'), rotatedAt: null, revokedAt: null, revokedReason: null, user, ...over,
    });

    it('desconocido o caducado → AUTH_REFRESH_INVALID', async () => {
      const { prisma, service } = setup();
      prisma.refreshToken.findUnique.mockResolvedValueOnce(null);
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_INVALID', 401);
      prisma.refreshToken.findUnique.mockResolvedValueOnce(stored({ expiresAt: new Date('2020-01-01') }));
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_INVALID');
    });

    it('rota: revoca el viejo, hereda la familia y enlaza el nuevo', async () => {
      const { prisma, service } = setup();
      prisma.refreshToken.findUnique.mockResolvedValueOnce(stored());
      prisma.refreshToken.updateMany.mockResolvedValueOnce({ count: 1 });
      prisma.refreshToken.create.mockResolvedValueOnce({ id: 't2' });
      const res = await service.refresh('x');
      expect(res.refreshToken).toHaveLength(64);
      expect(prisma.refreshToken.updateMany.mock.calls[0][0].data.revokedReason).toBe('rotated');
      expect(prisma.refreshToken.create.mock.calls[0][0].data.familyId).toBe('t1');
      expect(prisma.refreshToken.update).toHaveBeenCalledWith({ where: { id: 't1' }, data: { replacedById: 't2' } });
    });

    it('rotado hace menos de la ventana → AUTH_REFRESH_RACE sin revocar', async () => {
      const { prisma, clock, service } = setup();
      prisma.refreshToken.findUnique.mockResolvedValueOnce(
        stored({ revokedAt: clock.now(), rotatedAt: new Date(clock.now().getTime() - 3000), revokedReason: 'rotated' }),
      );
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_RACE', 401);
      expect(prisma.refreshToken.updateMany).not.toHaveBeenCalled();
    });

    it('reutilización fuera de la ventana (o tras logout) → revoca todo y AUTH_REFRESH_REUSED', async () => {
      const { prisma, clock, service } = setup();
      prisma.refreshToken.findUnique.mockResolvedValueOnce(
        stored({ revokedAt: clock.now(), rotatedAt: new Date(clock.now().getTime() - 60_000), revokedReason: 'rotated' }),
      );
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_REUSED');
      expect(prisma.refreshToken.updateMany.mock.calls[0][0]).toMatchObject({
        where: { userId: UID, revokedAt: null },
        data: { revokedReason: 'reuse_detected' },
      });
      expect(prisma.auditEvent.create.mock.calls[0][0].data).toMatchObject({ type: 'refresh_reuse_detected', userId: UID });
      prisma.refreshToken.findUnique.mockResolvedValueOnce(stored({ revokedAt: clock.now(), revokedReason: 'logout' }));
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_REUSED');
    });

    it('carrera perdida en la transacción → relee y decide (RACE)', async () => {
      const { prisma, clock, service } = setup();
      prisma.refreshToken.findUnique
        .mockResolvedValueOnce(stored())
        .mockResolvedValueOnce(stored({ revokedAt: clock.now(), rotatedAt: clock.now(), revokedReason: 'rotated' }));
      prisma.refreshToken.updateMany.mockResolvedValueOnce({ count: 0 });
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_RACE');
    });

    it('carrera perdida y el token ya no existe → REUSED; otros errores se propagan', async () => {
      const { prisma, service } = setup();
      prisma.refreshToken.findUnique.mockResolvedValueOnce(stored()).mockResolvedValueOnce(null);
      prisma.refreshToken.updateMany.mockResolvedValueOnce({ count: 0 });
      await rejectsWithCode(service.refresh('x'), 'AUTH_REFRESH_REUSED');

      prisma.refreshToken.findUnique.mockResolvedValueOnce(stored());
      prisma.$transaction.mockRejectedValueOnce(new Error('db down'));
      await expect(service.refresh('x')).rejects.toThrow('db down');
    });
  });

  it('logout revoca con motivo', async () => {
    const { prisma, service } = setup();
    await service.logout('tok');
    expect(prisma.refreshToken.updateMany.mock.calls[0][0].data.revokedReason).toBe('logout');
  });

  it('isWithinGrace', () => {
    const { service } = setup();
    const now = new Date();
    expect(service.isWithinGrace({ revokedReason: 'logout', rotatedAt: now }, now)).toBe(false);
    expect(service.isWithinGrace({ revokedReason: 'rotated', rotatedAt: null }, now)).toBe(false);
    expect(service.isWithinGrace({ revokedReason: 'rotated', rotatedAt: now }, now)).toBe(true);
  });
});
