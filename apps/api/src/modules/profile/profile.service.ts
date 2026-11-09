import { HttpStatus, Injectable } from '@nestjs/common';
import type { Prisma, TrainingProfile } from '@prisma/client';
import type {
  FieldIssue,
  HealthConsentStatus,
  ProfileResponse,
  ProfileUpdateResponse,
  ProfileUpsert,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { CatalogService } from '../catalog/catalog.service';
import { buildEngineProfile, EngineInputService } from '../plans/engine-input.service';
import { PlansService } from '../plans/plans.service';
import { healthConsentStatus, latestHealthConsent } from './consent-status';

/** JSON con claves ordenadas: compara perfiles del motor sin depender del orden de claves. */
export function stableStringify(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableStringify).join(',')}]`;
  if (value && typeof value === 'object') {
    const entries = Object.entries(value as Record<string, unknown>)
      .filter(([, v]) => v !== undefined)
      .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
    return `{${entries.map(([k, v]) => `${JSON.stringify(k)}:${stableStringify(v)}`).join(',')}}`;
  }
  return JSON.stringify(value);
}

/** Campos de salud con valor (art. 9) en una petición. */
export function healthFieldsWithValue(input: Pick<ProfileUpsert, 'limitations' | 'weightKg' | 'heightCm'>): FieldIssue[] {
  const issues: FieldIssue[] = [];
  if (input.limitations.length > 0) issues.push({ path: 'body.limitations', message: 'Requires health data consent' });
  if (input.weightKg !== null) issues.push({ path: 'body.weightKg', message: 'Requires health data consent' });
  if (input.heightCm !== null) issues.push({ path: 'body.heightCm', message: 'Requires health data consent' });
  return issues;
}

export function toProfileResponse(
  row: TrainingProfile,
  bannedSlugs: string[],
  favouriteSlugs: string[],
  consent: HealthConsentStatus,
): ProfileResponse {
  return {
    goal: row.goal,
    level: row.level,
    daysPerWeek: row.daysPerWeek,
    minutesPerSession: row.minutesPerSession,
    equipment: row.equipment,
    priorityMuscles: row.priorityMuscles,
    timezone: row.timezone,
    activityLevel: row.activityLevel,
    birthYear: row.birthYear,
    sex: row.sex,
    bannedExerciseSlugs: [...bannedSlugs].sort(),
    favouriteExerciseSlugs: [...favouriteSlugs].sort(),
    limitations: row.limitations,
    weightKg: row.weightKg === null ? null : Number(row.weightKg),
    heightCm: row.heightCm === null ? null : Number(row.heightCm),
    healthConsent: consent,
    updatedAt: row.updatedAt.toISOString(),
    trainingWeekdays: [...(row.trainingWeekdays ?? [])].sort((a, b) => a - b),
  };
}

@Injectable()
export class ProfileService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly catalog: CatalogService,
    private readonly engineInput: EngineInputService,
    private readonly plans: PlansService,
    private readonly clock: Clock,
    private readonly analytics: AnalyticsService,
  ) {}

  async find(userId: string): Promise<ProfileResponse | null> {
    const ctx = await this.engineInput.load(userId);
    return ctx ? toProfileResponse(ctx.profile, ctx.bannedSlugs, ctx.favouriteSlugs, ctx.consent) : null;
  }

  async get(userId: string): Promise<ProfileResponse> {
    const profile = await this.find(userId);
    if (!profile) throw new ApiError(HttpStatus.NOT_FOUND, 'PROFILE_REQUIRED', 'No training profile yet');
    return profile;
  }

  /**
   * Sustituye el perfil. Si el usuario ya tiene plan y cambia algo que lo afecta (material,
   * días, minutos, limitaciones…), en la MISMA transacción se crea una versión nueva; las
   * anteriores y el historial quedan intactos (CUJ-6).
   */
  async upsert(userId: string, input: ProfileUpsert): Promise<ProfileUpdateResponse> {
    const before = await this.engineInput.load(userId);
    const consent = before?.consent ?? healthConsentStatus(await latestHealthConsent(this.prisma, userId));
    if (!consent.granted) {
      const issues = healthFieldsWithValue(input);
      if (issues.length > 0) {
        throw new ApiError(
          HttpStatus.CONFLICT,
          'HEALTH_CONSENT_REQUIRED',
          'Health data (limitations, weight, height) requires an active health consent: POST /me/consents/health',
          issues,
        );
      }
    }

    const catalog = await this.catalog.engineCatalog();
    const unknown: FieldIssue[] = [];
    const resolve = (slugs: string[], field: string) =>
      slugs.map((slug, i) => {
        const entry = catalog.bySlug.get(slug);
        if (!entry) unknown.push({ path: `body.${field}.${i}`, message: `Unknown exercise "${slug}"` });
        return entry?.id ?? '';
      });
    const bannedIds = resolve(input.bannedExerciseSlugs, 'bannedExerciseSlugs');
    const favouriteIds = resolve(input.favouriteExerciseSlugs, 'favouriteExerciseSlugs');
    if (unknown.length > 0) {
      throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'UNKNOWN_EXERCISE', 'Unknown exercises', unknown);
    }

    const data = {
      goal: input.goal,
      level: input.level,
      daysPerWeek: input.daysPerWeek,
      minutesPerSession: input.minutesPerSession,
      equipment: input.equipment,
      priorityMuscles: input.priorityMuscles,
      timezone: input.timezone,
      activityLevel: input.activityLevel,
      birthYear: input.birthYear,
      sex: input.sex,
      limitations: input.limitations,
      weightKg: input.weightKg,
      heightCm: input.heightCm,
    } satisfies Omit<Prisma.TrainingProfileUncheckedCreateInput, 'userId'>;

    const now = this.clock.now();
    const after = buildEngineProfile(
      { ...data, userId, createdAt: now, updatedAt: now } as unknown as TrainingProfile,
      input.bannedExerciseSlugs,
      input.favouriteExerciseSlugs,
      consent.granted,
      now,
    );
    const changed = !before || stableStringify(before.engineProfile) !== stableStringify(after);
    const prepared =
      changed && (await this.plans.hasActivePlan(userId)) ? await this.plans.prepare(userId, after, input.timezone) : null;

    const planVersion = await this.plans.withVersionRetry(async (tx) => {
      // La comprobación de arriba es optimista (el motor corre fuera de la transacción). Con el
      // candado por usuario —el mismo que toma la retirada del consentimiento— se vuelve a leer
      // el consentimiento: si se retiró entretanto, no se guardan datos de salud ni un plan
      // calculado con ellos.
      await this.analytics.lockUser(tx, userId);
      if (!healthConsentStatus(await latestHealthConsent(tx, userId)).granted) {
        const issues = healthFieldsWithValue(input);
        if (issues.length > 0) {
          throw new ApiError(
            HttpStatus.CONFLICT,
            'HEALTH_CONSENT_REQUIRED',
            'Health data (limitations, weight, height) requires an active health consent: POST /me/consents/health',
            issues,
          );
        }
      }
      // Los días de entreno (PATCH /me/profile/schedule) se conservan salvo que ya no quepan en
      // los días por semana nuevos: entonces se vacían (idea 6).
      const weekdays = before?.profile.trainingWeekdays ?? [];
      await tx.trainingProfile.upsert({
        where: { userId },
        create: { userId, ...data },
        update: { ...data, ...(weekdays.length > input.daysPerWeek ? { trainingWeekdays: [] } : {}) },
      });
      await tx.userExercisePreference.deleteMany({ where: { userId } });
      const prefs = [
        ...bannedIds.map((exerciseId) => ({ userId, exerciseId, kind: 'banned' as const })),
        ...favouriteIds.map((exerciseId) => ({ userId, exerciseId, kind: 'favourite' as const })),
      ];
      if (prefs.length > 0) await tx.userExercisePreference.createMany({ data: prefs });
      // La zona horaria fija los límites de semana de la analítica (ADR-0008): si cambia, las
      // proyecciones se reconstruyen desde SetLog en la misma transacción.
      if (before && before.profile.timezone !== input.timezone) await this.analytics.rebuildUser(tx, userId);
      return prepared ? this.plans.persistVersion(tx, userId, prepared) : null;
    });

    return { profile: await this.get(userId), planVersion };
  }
}
