import { vi, type Mock } from 'vitest';
import { loadCatalog } from '@pipos/catalog';
import { loadImplement } from '@pipos/engine-rules';
import { HEALTH_CONSENT_POLICY, sortExerciseMuscles } from '@pipos/contracts';
import type { TrainingProfile } from '@prisma/client';
import { Clock } from '../../common/clock';
import type { CatalogEntry, EngineCatalog } from '../../modules/catalog/catalog.service';

/**
 * Doble de PrismaClient para tests UNITARIOS de servicios (los e2e usan Postgres real).
 * Cualquier `prisma.modelo.metodo` es un `vi.fn()` creado bajo demanda; `$transaction`
 * ejecuta el callback con el propio doble.
 */
export type PrismaMock = Record<string, Record<string, Mock>> & {
  $transaction: Mock;
  $queryRaw: Mock;
  $executeRaw: Mock;
};

export function prismaMock(): PrismaMock {
  const models = new Map<string, Record<string, Mock>>();
  const special = new Map<string, Mock>();

  const model = (name: string) => {
    let m = models.get(name);
    if (!m) {
      const fns = new Map<string, Mock>();
      m = new Proxy({} as Record<string, Mock>, {
        get: (_t, method: string) => {
          // `findMany` devuelve [] por defecto: una tabla sin filas (las lecturas nuevas no rompen
          // los tests que no las configuran).
          if (!fns.has(method)) fns.set(method, method === 'findMany' ? vi.fn().mockResolvedValue([]) : vi.fn());
          return fns.get(method);
        },
      });
      models.set(name, m);
    }
    return m;
  };
  const root: PrismaMock = new Proxy({} as PrismaMock, {
    get: (_t, prop: string | symbol) => {
      if (typeof prop === 'symbol' || prop === 'then') return undefined;
      if (prop.startsWith('$')) {
        if (!special.has(prop)) {
          special.set(
            prop,
            prop === '$transaction'
              ? vi.fn(async (arg: unknown) => (typeof arg === 'function' ? arg(root) : Promise.all(arg as unknown[])))
              : vi.fn().mockResolvedValue([]),
          );
        }
        return special.get(prop);
      }
      return model(prop);
    },
  });
  return root;
}

export class FixedClock extends Clock {
  constructor(public date = new Date('2026-11-09T10:00:00.000Z')) {
    super();
  }
  now(): Date {
    return new Date(this.date);
  }
}

export const UID = '11111111-1111-4111-8111-111111111111';

/** Catálogo real de @pipos/catalog con ids deterministas (`id:<slug>`). */
export function fakeEngineCatalog(): EngineCatalog {
  const exercises = [...loadCatalog()];
  const entries: CatalogEntry[] = exercises.map((e) => ({
    id: `id:${e.slug}`,
    slug: e.slug,
    nameEs: e.nameEs,
    movementPattern: e.movementPattern,
    loadType: e.loadType,
    isUnilateral: e.isUnilateral,
    cuesEs: e.cuesEs,
    muscles: e.muscles.map((m) => ({ muscle: m.muscle, fraction: m.fraction })),
    muscleRefs: sortExerciseMuscles(e.muscles),
    loadImplement: loadImplement(e),
    hasVideo: e.media.some((m) => m.kind === 'youtube'),
  }));
  return { exercises, bySlug: new Map(entries.map((e) => [e.slug, e])), byId: new Map(entries.map((e) => [e.id, e])) };
}

export function catalogServiceMock(catalog = fakeEngineCatalog()) {
  return {
    engineCatalog: vi.fn().mockResolvedValue(catalog),
    refs: vi.fn(async (ids: string[]) => {
      const map = new Map();
      for (const id of ids) {
        const e = catalog.byId.get(id);
        if (e) map.set(id, { id, slug: e.slug, nameEs: e.nameEs });
      }
      return map;
    }),
    invalidate: vi.fn(),
  };
}

export function profileRow(overrides: Partial<TrainingProfile> = {}): TrainingProfile {
  return {
    userId: UID,
    goal: 'hypertrophy',
    level: 'beginner',
    daysPerWeek: 3,
    minutesPerSession: 45,
    equipment: ['barbell', 'dumbbell', 'bench', 'squat_rack', 'cable', 'machine', 'pull_up_bar'],
    priorityMuscles: [],
    timezone: 'Europe/Madrid',
    activityLevel: null,
    limitations: [],
    trainingWeekdays: [],
    weightKg: null,
    heightCm: null,
    birthYear: null,
    sex: null,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
    ...overrides,
  } as TrainingProfile;
}

export function grantedEvent(version: string = HEALTH_CONSENT_POLICY.version) {
  return {
    id: 'c1',
    userId: UID,
    purpose: 'health_data_processing',
    action: 'granted',
    policyVersion: version,
    textHash: 'a'.repeat(64),
    locale: 'es',
    occurredAt: new Date('2026-11-01T00:00:00Z'),
  };
}

export async function rejectsWithCode(promise: Promise<unknown>, code: string, status?: number): Promise<void> {
  const error = await promise.then(
    () => {
      throw new Error(`expected rejection with ${code}`);
    },
    (e: unknown) => e,
  );
  const body = (error as { getResponse?: () => { code?: string } }).getResponse?.();
  if (body?.code !== code) throw new Error(`expected code ${code}, got ${JSON.stringify(body ?? String(error))}`);
  if (status !== undefined && (error as { getStatus: () => number }).getStatus() !== status) {
    throw new Error(`expected status ${status}, got ${(error as { getStatus: () => number }).getStatus()}`);
  }
}
