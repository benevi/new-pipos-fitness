import { Test } from '@nestjs/testing';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { randomUUID } from 'crypto';
import { AppModule } from '../../app.module';
import { configureApp } from '../../app.setup';
import { parseEnv } from '../../config/env';
import { PrismaService } from '../../prisma/prisma.service';

/**
 * Utilidades e2e: app Nest completa (AppModule real + configureApp de producción)
 * contra un Postgres real. PROHIBIDO sobrescribir PrismaService con mocks
 * (lo comprueba src/test/e2e/no-prisma-mocks.spec.ts y una regla de ESLint).
 */
export interface TestContext {
  app: INestApplication;
  prisma: PrismaService;
}

export async function createTestApp(envOverrides: Record<string, string> = {}): Promise<TestContext> {
  const previous: Record<string, string | undefined> = {};
  for (const [key, value] of Object.entries(envOverrides)) {
    previous[key] = process.env[key];
    process.env[key] = value;
  }
  try {
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
    const app = moduleRef.createNestApplication();
    configureApp(app, parseEnv(process.env));
    await app.init();
    return { app, prisma: app.get(PrismaService) };
  } finally {
    for (const [key, value] of Object.entries(previous)) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  }
}

/** Vacía todas las tablas de la aplicación (no toca _prisma_migrations). */
export async function truncateAll(prisma: PrismaService): Promise<void> {
  const rows = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'
  `;
  if (rows.length === 0) return;
  const tables = rows.map((r) => `"public"."${r.tablename}"`).join(', ');
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tables} RESTART IDENTITY CASCADE`);
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
  const res = await request(app.getHttpServer())
    .post('/auth/register')
    .send({ email, password })
    .expect(201);
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

/** Crea un ejercicio de catálogo con un músculo primario. */
export async function createExercise(
  prisma: PrismaService,
  overrides: Partial<{ slug: string; name: string; movementPattern: string; place: 'home' | 'gym' | 'calisthenics' }> = {},
) {
  const slug = overrides.slug ?? `exercise-${randomUUID()}`;
  const muscle = await prisma.muscle.upsert({
    where: { id: 'muscle-chest' },
    create: { id: 'muscle-chest', name: 'Chest', region: 'upper' },
    update: {},
  });
  return prisma.exercise.create({
    data: {
      slug,
      name: overrides.name ?? slug,
      difficulty: 2,
      movementPattern: overrides.movementPattern ?? 'push',
      place: overrides.place ?? 'gym',
      muscles: { create: [{ muscleId: muscle.id, role: 'primary' }] },
    },
  });
}

/**
 * Crea directamente en BD un plan de entrenamiento del usuario con una versión y una
 * sesión planificada (con un ejercicio de `sets` series). Devuelve ids útiles.
 */
export async function createPlanSession(
  prisma: PrismaService,
  userId: string,
  exerciseId: string,
  sets = 3,
) {
  const plan = await prisma.trainingPlan.create({ data: { userId } });
  const version = await prisma.trainingPlanVersion.create({
    data: { planId: plan.id, version: 1, engineVersion: 'test', objectiveScore: 0 },
  });
  await prisma.trainingPlan.update({
    where: { id: plan.id },
    data: { currentVersionId: version.id },
  });
  const session = await prisma.trainingSession.create({
    data: {
      planVersionId: version.id,
      sessionIndex: 0,
      name: 'Day 1',
      targetDurationMinutes: 45,
      exercises: {
        create: [
          { exerciseId, sets, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
        ],
      },
    },
  });
  return { planId: plan.id, planVersionId: version.id, planSessionId: session.id };
}
