import { describe, expect, it, vi } from 'vitest';
import { HEALTH_CONSENT_POLICY, ProfileUpsertRequestSchema } from '@pipos/contracts';
import type { PrismaService } from '../../prisma/prisma.service';
import {
  catalogServiceMock,
  FixedClock,
  grantedEvent,
  prismaMock,
  profileRow,
  rejectsWithCode,
  UID,
} from '../../test/unit/support';
import type { AnalyticsService } from '../analytics/analytics.service';
import type { CatalogService } from '../catalog/catalog.service';
import { EngineInputService } from '../plans/engine-input.service';
import type { PlansService } from '../plans/plans.service';
import { healthConsentStatus } from './consent-status';
import { ConsentService } from './consent.service';
import { healthFieldsWithValue, ProfileService, stableStringify } from './profile.service';

const input = ProfileUpsertRequestSchema.parse({
  goal: 'hypertrophy',
  level: 'beginner',
  daysPerWeek: 3,
  minutesPerSession: 45,
  equipment: ['barbell', 'dumbbell', 'bench', 'squat_rack', 'cable', 'machine', 'pull_up_bar'],
  timezone: 'Europe/Madrid',
});

function setup() {
  const prisma = prismaMock();
  const clock = new FixedClock();
  const catalog = catalogServiceMock();
  const engineInput = new EngineInputService(prisma as unknown as PrismaService, clock);
  const plans = {
    hasActivePlan: vi.fn().mockResolvedValue(false),
    prepare: vi.fn().mockResolvedValue({ draft: {}, snapshot: {}, sessions: [] }),
    persistVersion: vi.fn().mockResolvedValue({ id: 'v2', version: 2 }),
    withVersionRetry: vi.fn(async (work: (tx: unknown) => unknown) => work(prisma)),
  };
  const analytics = { lockUser: vi.fn(), rebuildUser: vi.fn() } as unknown as AnalyticsService;
  const profiles = new ProfileService(
    prisma as unknown as PrismaService,
    catalog as unknown as CatalogService,
    engineInput,
    plans as unknown as PlansService,
    clock,
    analytics,
  );
  const consents = new ConsentService(prisma as unknown as PrismaService, engineInput, plans as unknown as PlansService, clock, analytics);
  prisma.userExercisePreference.findMany.mockResolvedValue([]);
  return { prisma, plans, profiles, consents };
}

describe('helpers de perfil', () => {
  it('stableStringify ignora el orden de claves y los undefined', () => {
    expect(stableStringify({ b: 1, a: [1, { d: undefined, c: 2 }] })).toBe(stableStringify({ a: [1, { c: 2 }], b: 1 }));
  });
  it('healthFieldsWithValue lista los campos art. 9 con valor', () => {
    expect(healthFieldsWithValue({ limitations: [], weightKg: null, heightCm: null })).toEqual([]);
    expect(healthFieldsWithValue({ limitations: ['knee'], weightKg: 1, heightCm: 2 }).map((i) => i.path)).toEqual([
      'body.limitations',
      'body.weightKg',
      'body.heightCm',
    ]);
  });
  it('healthConsentStatus: versión antigua no vale', () => {
    expect(healthConsentStatus(null)).toMatchObject({ granted: false, version: null });
    expect(healthConsentStatus(grantedEvent() as never).granted).toBe(true);
    expect(healthConsentStatus(grantedEvent('health-old') as never)).toMatchObject({ granted: false, version: 'health-old' });
  });
});

describe('ProfileService', () => {
  it('get: 404 PROFILE_REQUIRED sin perfil', async () => {
    const { prisma, profiles } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(null);
    await rejectsWithCode(profiles.get(UID), 'PROFILE_REQUIRED', 404);
  });

  it('upsert sin consentimiento con datos de salud → 409 y no escribe', async () => {
    const { prisma, profiles } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(null);
    prisma.consentEvent.findFirst.mockResolvedValue(null);
    await rejectsWithCode(profiles.upsert(UID, { ...input, weightKg: 80 }), 'HEALTH_CONSENT_REQUIRED', 409);
    expect(prisma.trainingProfile.upsert).not.toHaveBeenCalled();
  });

  it('upsert con ejercicio desconocido → 422', async () => {
    const { prisma, profiles } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(null);
    prisma.consentEvent.findFirst.mockResolvedValue(null);
    await rejectsWithCode(profiles.upsert(UID, { ...input, bannedExerciseSlugs: ['nope'] }), 'UNKNOWN_EXERCISE', 422);
  });

  it('primer perfil: guarda perfil y preferencias, sin plan que regenerar', async () => {
    const { prisma, plans, profiles } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValueOnce(null).mockResolvedValue(profileRow());
    prisma.consentEvent.findFirst.mockResolvedValue(null);
    const res = await profiles.upsert(UID, { ...input, bannedExerciseSlugs: ['sentadilla-trasera-barra'] });
    expect(prisma.trainingProfile.upsert).toHaveBeenCalled();
    expect(prisma.userExercisePreference.createMany.mock.calls[0][0].data).toEqual([
      { userId: UID, exerciseId: 'id:sentadilla-trasera-barra', kind: 'banned' },
    ]);
    expect(plans.prepare).not.toHaveBeenCalled();
    expect(res.planVersion).toBeNull();
    expect(res.profile.goal).toBe('hypertrophy');
  });

  it('cambio relevante con plan activo → nueva versión en la misma transacción; sin cambios → no', async () => {
    const { prisma, plans, profiles } = setup();
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow());
    prisma.consentEvent.findFirst.mockResolvedValue(grantedEvent());
    plans.hasActivePlan.mockResolvedValue(true);
    const changed = await profiles.upsert(UID, { ...input, daysPerWeek: 4, limitations: ['knee'] });
    expect(plans.prepare).toHaveBeenCalledTimes(1);
    expect(changed.planVersion).toEqual({ id: 'v2', version: 2 });
    const same = await profiles.upsert(UID, { ...input, timezone: 'Europe/Lisbon' });
    expect(plans.prepare).toHaveBeenCalledTimes(1);
    expect(same.planVersion).toBeNull();
  });
});

describe('ConsentService', () => {
  it('grant: versión incorrecta → 422; ya concedido → no duplica; si no, registra el evento', async () => {
    const { prisma, consents } = setup();
    await rejectsWithCode(consents.grant(UID, { version: 'x', locale: 'es' }), 'HEALTH_CONSENT_VERSION_MISMATCH', 422);
    prisma.consentEvent.findFirst.mockResolvedValueOnce(grantedEvent());
    await consents.grant(UID, { version: HEALTH_CONSENT_POLICY.version, locale: 'es' });
    expect(prisma.consentEvent.create).not.toHaveBeenCalled();

    prisma.consentEvent.findFirst.mockResolvedValueOnce(null).mockResolvedValueOnce(grantedEvent());
    const status = await consents.grant(UID, { version: HEALTH_CONSENT_POLICY.version, locale: 'en' });
    expect(status.granted).toBe(true);
    const data = prisma.consentEvent.create.mock.calls[0][0].data;
    expect(data).toMatchObject({ action: 'granted', locale: 'en' });
    expect(data).not.toHaveProperty('ip');
    expect(data).not.toHaveProperty('userAgent');
    expect(data.textHash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('withdraw: registra la retirada, borra salud, redacta y regenera si hay plan', async () => {
    const { prisma, plans, consents } = setup();
    prisma.consentEvent.findFirst.mockResolvedValueOnce(grantedEvent()).mockResolvedValueOnce(grantedEvent()).mockResolvedValue(null);
    prisma.trainingProfile.findUnique.mockResolvedValue(profileRow({ limitations: ['knee'] }));
    plans.hasActivePlan.mockResolvedValue(true);
    const res = await consents.withdraw(UID);
    expect(prisma.consentEvent.create.mock.calls[0][0].data).toMatchObject({ action: 'withdrawn' });
    expect(prisma.trainingProfile.updateMany.mock.calls[0][0].data).toEqual({ limitations: [], weightKg: null, heightCm: null });
    expect(prisma.$executeRaw).toHaveBeenCalled();
    expect(plans.prepare.mock.calls[0][1].limitations).toEqual([]);
    expect(res.planVersion).toEqual({ id: 'v2', version: 2 });
  });

  it('withdraw sin consentimiento ni plan: idempotente, sin evento ni versión', async () => {
    const { prisma, plans, consents } = setup();
    prisma.consentEvent.findFirst.mockResolvedValue(null);
    prisma.trainingProfile.findUnique.mockResolvedValue(null);
    const res = await consents.withdraw(UID);
    expect(prisma.consentEvent.create).not.toHaveBeenCalled();
    expect(plans.prepare).not.toHaveBeenCalled();
    expect(res).toMatchObject({ planVersion: null, healthConsent: { granted: false } });
  });
});
