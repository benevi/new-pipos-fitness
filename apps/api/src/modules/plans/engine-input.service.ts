import { Injectable } from '@nestjs/common';
import type { Prisma, TrainingProfile } from '@prisma/client';
import type { engineV2, HealthConsentStatus } from '@pipos/contracts';
import { Clock } from '../../common/clock';
import { localDate } from '../../common/time';
import { PrismaService, type TransactionClient } from '../../prisma/prisma.service';
import { healthConsentStatus, latestHealthConsent } from '../profile/consent-status';

export type Db = PrismaService | TransactionClient;

export interface UserTrainingContext {
  profile: TrainingProfile;
  bannedSlugs: string[];
  favouriteSlugs: string[];
  consent: HealthConsentStatus;
  /** Perfil de entrada del motor SIN historial (es el `inputSnapshot` de la versión). */
  engineProfile: engineV2.EngineProfileInput;
}

/** Días de historial que se pasan al motor (cargas iniciales por e1RM). */
export const HISTORY_DAYS = 180;
export const HISTORY_MAX_SETS = 5000;

export function ageFrom(birthYear: number | null, now: Date, timezone: string): number | null {
  if (birthYear === null) return null;
  return Number(localDate(now, timezone).slice(0, 4)) - birthYear;
}

/**
 * Perfil del motor a partir de la BD. Los datos de salud (limitaciones, peso, altura) solo
 * entran con consentimiento vigente: sin él el plan se genera sin ellos (ADR-0011).
 */
export function buildEngineProfile(
  profile: TrainingProfile,
  bannedSlugs: string[],
  favouriteSlugs: string[],
  healthAllowed: boolean,
  now: Date,
): engineV2.EngineProfileInput {
  const body: engineV2.BodyData = {};
  if (healthAllowed && profile.weightKg !== null) body.weightKg = Number(profile.weightKg);
  if (healthAllowed && profile.heightCm !== null) body.heightCm = Number(profile.heightCm);
  const age = ageFrom(profile.birthYear, now, profile.timezone);
  if (age !== null && age >= 14 && age <= 100) body.age = age;
  if (profile.sex !== null) body.sex = profile.sex;
  return {
    goal: profile.goal,
    level: profile.level,
    daysPerWeek: profile.daysPerWeek,
    minutesPerSession: profile.minutesPerSession,
    equipment: [...profile.equipment],
    limitations: healthAllowed ? [...profile.limitations] : [],
    priorityMuscles: [...profile.priorityMuscles],
    bannedExerciseIds: [...bannedSlugs].sort(),
    favouriteExerciseIds: [...favouriteSlugs].sort(),
    ...(Object.keys(body).length > 0 ? { body } : {}),
  };
}

type HistoryRow = {
  workoutSessionId: string;
  reps: number;
  loadKg: Prisma.Decimal | number;
  rir: number | null;
  isWarmup: boolean;
  exercise: { slug: string };
  workoutSession: { startedAt: Date };
};

/** Agrupa series por (entrenamiento, ejercicio) en entradas del historial del motor. */
export function toTrainingHistory(rows: readonly HistoryRow[], timezone: string): engineV2.TrainingHistory {
  const entries = new Map<string, engineV2.ExerciseSessionLog>();
  for (const r of rows) {
    const key = `${r.workoutSessionId}:${r.exercise.slug}`;
    let entry = entries.get(key);
    if (!entry) {
      entry = { date: localDate(r.workoutSession.startedAt, timezone), exerciseId: r.exercise.slug, sets: [] };
      entries.set(key, entry);
    }
    entry.sets.push({
      reps: r.reps,
      loadKg: Number(r.loadKg),
      ...(r.rir !== null ? { rir: r.rir } : {}),
      ...(r.isWarmup ? { isWarmup: true } : {}),
    });
  }
  return { entries: [...entries.values()] };
}

@Injectable()
export class EngineInputService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  async load(userId: string, db: Db = this.prisma): Promise<UserTrainingContext | null> {
    const profile = await db.trainingProfile.findUnique({ where: { userId } });
    if (!profile) return null;
    const [prefs, latest] = await Promise.all([
      db.userExercisePreference.findMany({
        where: { userId },
        select: { kind: true, exercise: { select: { slug: true } } },
      }),
      latestHealthConsent(db, userId),
    ]);
    const consent = healthConsentStatus(latest);
    const bannedSlugs = prefs.filter((p) => p.kind === 'banned').map((p) => p.exercise.slug);
    const favouriteSlugs = prefs.filter((p) => p.kind === 'favourite').map((p) => p.exercise.slug);
    return {
      profile,
      bannedSlugs,
      favouriteSlugs,
      consent,
      engineProfile: buildEngineProfile(profile, bannedSlugs, favouriteSlugs, consent.granted, this.clock.now()),
    };
  }

  /** Historial reciente (series no borradas de entrenamientos no abandonados). */
  async history(
    userId: string,
    timezone: string,
    options: { exerciseIds?: string[]; excludeWorkoutId?: string } = {},
    db: Db = this.prisma,
  ): Promise<engineV2.TrainingHistory> {
    const since = new Date(this.clock.now().getTime() - HISTORY_DAYS * 86_400_000);
    const rows = await db.setLog.findMany({
      where: {
        userId,
        deletedAt: null,
        completedAt: { gte: since },
        ...(options.exerciseIds ? { exerciseId: { in: options.exerciseIds } } : {}),
        workoutSession: {
          status: { not: 'abandoned' },
          ...(options.excludeWorkoutId ? { id: { not: options.excludeWorkoutId } } : {}),
        },
      },
      select: {
        workoutSessionId: true,
        reps: true,
        loadKg: true,
        rir: true,
        isWarmup: true,
        exercise: { select: { slug: true } },
        workoutSession: { select: { startedAt: true } },
      },
      orderBy: [{ completedAt: 'desc' }, { setIndex: 'asc' }],
      take: HISTORY_MAX_SETS,
    });
    return toTrainingHistory(rows, timezone);
  }
}
