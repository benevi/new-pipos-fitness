import { Test } from '@nestjs/testing';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { randomUUID } from 'crypto';
import { HEALTH_CONSENT_POLICY, type ProfileUpsertRequest } from '@pipos/contracts';
import { AppModule } from '../../app.module';
import { configureApp } from '../../app.setup';
import { Clock } from '../../common/clock';
import { parseEnv } from '../../config/env';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Utilidades e2e: app Nest completa (AppModule real + configureApp de producción)
 * contra un Postgres real. PROHIBIDO sobrescribir PrismaService con mocks
 * (lo comprueba src/test/e2e/no-prisma-mocks.spec.ts y una regla de ESLint).
 * Sí se puede fijar el reloj (Clock) para simular fechas.
 */
export interface TestContext {
  app: INestApplication;
  prisma: PrismaService;
  clock: FakeClock;
}

/** Reloj controlable: por defecto la hora real; `set()` la fija. */
export class FakeClock extends Clock {
  private fixed: Date | null = null;
  now(): Date {
    return this.fixed ? new Date(this.fixed) : new Date();
  }
  set(date: Date | string | null): void {
    this.fixed = date === null ? null : new Date(date);
  }
}

export async function createTestApp(envOverrides: Record<string, string> = {}): Promise<TestContext> {
  const previous: Record<string, string | undefined> = {};
  for (const [key, value] of Object.entries(envOverrides)) {
    previous[key] = process.env[key];
    process.env[key] = value;
  }
  try {
    const clock = new FakeClock();
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(Clock)
      .useValue(clock)
      .compile();
    const app = moduleRef.createNestApplication({ logger: false });
    configureApp(app, parseEnv(process.env));
    await app.init();
    return { app, prisma: app.get(PrismaService), clock };
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

/** Tablas del catálogo: las siembra global-setup una vez y no se vacían entre tests. */
const CATALOG_TABLES = new Set(['Exercise', 'ExerciseMuscle', 'ExerciseRiskTag', 'ExerciseMedia', 'SubstitutionGroup']);

/** Vacía todas las tablas de datos de usuario (no toca el catálogo ni _prisma_migrations). */
export async function truncateAll(prisma: PrismaService): Promise<void> {
  const rows = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'
  `;
  const tables = rows.filter((r) => !CATALOG_TABLES.has(r.tablename)).map((r) => `"public"."${r.tablename}"`);
  if (tables.length === 0) return;
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tables.join(', ')} RESTART IDENTITY CASCADE`);
}

export interface RegisteredUser {
  id: string;
  email: string;
  password: string;
  accessToken: string;
  refreshToken: string;
}

export async function registerUser(
  app: INestApplication,
  email = `user-${randomUUID()}@example.com`,
  password = 'password123',
): Promise<RegisteredUser> {
  const res = await request(app.getHttpServer()).post('/auth/register').send({ email, password }).expect(201);
  return {
    id: res.body.user.id,
    email,
    password,
    accessToken: res.body.accessToken,
    refreshToken: res.body.refreshToken,
  };
}

export function bearer(token: string): { Authorization: string } {
  return { Authorization: `Bearer ${token}` };
}

/** Perfil de Laura (SPEC_V1): principiante, 3 días, 45 min, gimnasio de barrio. */
export const BEGINNER_GYM: ProfileUpsertRequest = {
  goal: 'hypertrophy',
  level: 'beginner',
  daysPerWeek: 3,
  minutesPerSession: 45,
  equipment: ['barbell', 'dumbbell', 'bench', 'squat_rack', 'cable', 'machine', 'pull_up_bar'],
  timezone: 'Europe/Madrid',
};

/** Perfil de Andrés: intermedio en casa, mancuernas, banco y barra; 4 días, 40 min. */
export const HOME_INTERMEDIATE: ProfileUpsertRequest = {
  goal: 'hypertrophy',
  level: 'intermediate',
  daysPerWeek: 4,
  minutesPerSession: 40,
  equipment: ['dumbbell', 'bench', 'pull_up_bar'],
  timezone: 'Europe/Madrid',
};

export async function grantHealthConsent(app: INestApplication, token: string): Promise<void> {
  await request(app.getHttpServer())
    .post('/me/consents/health')
    .set(bearer(token))
    .send({ version: HEALTH_CONSENT_POLICY.version })
    .expect(200);
}

export async function putProfile(app: INestApplication, token: string, profile: ProfileUpsertRequest = BEGINNER_GYM) {
  return request(app.getHttpServer()).put('/me/profile').set(bearer(token)).send(profile).expect(200);
}

export async function generatePlan(app: INestApplication, token: string) {
  return request(app.getHttpServer()).post('/plans/generate').set(bearer(token)).expect(201);
}

/** Usuario con perfil y plan generado, listo para entrenar. */
export async function userWithPlan(app: INestApplication, profile: ProfileUpsertRequest = BEGINNER_GYM) {
  const user = await registerUser(app);
  await putProfile(app, user.accessToken, profile);
  const plan = await generatePlan(app, user.accessToken);
  return { user, plan: plan.body };
}

/** Empieza el entrenamiento de hoy y devuelve la sesión de hoy y el entrenamiento. */
export async function startToday(app: INestApplication, token: string, startedAt = new Date().toISOString()) {
  const today = await request(app.getHttpServer()).get('/sessions/today').set(bearer(token)).expect(200);
  const workout = await request(app.getHttpServer())
    .post('/workouts')
    .set(bearer(token))
    .send({ clientId: randomUUID(), planSessionId: today.body.planSessionId, startedAt })
    .expect(201);
  return { today: today.body, workout: workout.body };
}

export function setBody(
  exercise: { planExerciseId: string; exercise: { id: string } },
  overrides: Partial<{ clientId: string; setIndex: number; reps: number; loadKg: number; rir: number | null; completedAt: string }> = {},
) {
  return {
    clientId: randomUUID(),
    planExerciseId: exercise.planExerciseId,
    exerciseId: exercise.exercise.id,
    setIndex: 0,
    reps: 10,
    loadKg: 40,
    rir: 2,
    completedAt: new Date().toISOString(),
    ...overrides,
  };
}
