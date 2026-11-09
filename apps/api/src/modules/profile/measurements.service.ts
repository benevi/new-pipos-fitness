import { HttpStatus, Injectable } from '@nestjs/common';
import type { BodyMeasurement } from '@prisma/client';
import { bmi, navyBodyFat, NOT_A_DIAGNOSIS, weightTrend } from '@pipos/engine-rules';
import {
  BODY_MEASUREMENT_FIELDS,
  CIRCUMFERENCE_FIELDS,
  HEALTH_CONSENT_POLICY,
  type BodyMeasurementListQuery,
  type BodyMeasurementListResponse,
  type BodyMeasurementResponse,
  type BodyProgressResponse,
  type CircumferenceTrend,
  type FieldIssue,
  type HealthDataScope,
  type UpsertBodyMeasurement,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { addDays, dateColumn, fromDateColumn, localDate } from '../../common/time';
import { PrismaService } from '../../prisma/prisma.service';
import { AnalyticsService } from '../analytics/analytics.service';
import { AuditService } from '../audit/audit.service';
import { ageFrom } from '../plans/engine-input.service';
import { coversScopes, healthConsentStatus, latestHealthConsent } from './consent-status';

const num = (v: { toString(): string } | null): number | null => (v === null ? null : Number(v));

export function toMeasurementResponse(row: BodyMeasurement): BodyMeasurementResponse {
  return {
    measuredOn: fromDateColumn(row.measuredOn),
    weightKg: num(row.weightKg),
    waistCm: num(row.waistCm),
    neckCm: num(row.neckCm),
    hipCm: num(row.hipCm),
    chestCm: num(row.chestCm),
    armCm: num(row.armCm),
    thighCm: num(row.thighCm),
    updatedAt: row.updatedAt.toISOString(),
  };
}

/** Ámbitos del consentimiento que necesita guardar estas medidas. */
export function scopesFor(input: Pick<UpsertBodyMeasurement, (typeof BODY_MEASUREMENT_FIELDS)[number]>): HealthDataScope[] {
  const scopes: HealthDataScope[] = [];
  if (input.weightKg !== null) scopes.push('weight');
  if (CIRCUMFERENCE_FIELDS.some((f) => input[f] !== null)) scopes.push('body_measurements');
  return scopes;
}

/** Valor de la medida más reciente en o antes de `date` (o null). `rows` en orden ascendente. */
function valueAtOrBefore(rows: readonly BodyMeasurementResponse[], field: (typeof CIRCUMFERENCE_FIELDS)[number], date: string) {
  for (let i = rows.length - 1; i >= 0; i--) {
    const v = rows[i][field];
    if (rows[i].measuredOn <= date && v !== null) return v;
  }
  return null;
}

/** Ventana de lectura de GET /progress/body y por defecto de GET /me/measurements. */
export const BODY_HISTORY_DAYS = 365;

/**
 * Medidas corporales (idea 7, ADR-0013): datos de salud (art. 9). Escribir exige que el
 * consentimiento vigente cubra el ámbito de cada medida; la retirada del consentimiento borra el
 * registro entero (ConsentService.withdraw). Nunca se registran en logs.
 */
@Injectable()
export class MeasurementsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly analytics: AnalyticsService,
    private readonly clock: Clock,
    private readonly audit: AuditService,
  ) {}

  private async profileOf(userId: string) {
    const profile = await this.prisma.trainingProfile.findUnique({
      where: { userId },
      select: { timezone: true, goal: true, sex: true, heightCm: true, birthYear: true },
    });
    if (!profile) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    return profile;
  }

  private consentError(needed: HealthDataScope[], input: UpsertBodyMeasurement): ApiError {
    const issues: FieldIssue[] = BODY_MEASUREMENT_FIELDS.filter((f) => input[f] !== null)
      .filter((f) => needed.includes(f === 'weightKg' ? 'weight' : 'body_measurements'))
      .map((f) => ({ path: `body.${f}`, message: `Requires health data consent version ${HEALTH_CONSENT_POLICY.version}` }));
    return new ApiError(
      HttpStatus.CONFLICT,
      'HEALTH_CONSENT_REQUIRED',
      `Body measurements require an active health consent covering them (version ${HEALTH_CONSENT_POLICY.version}): POST /me/consents/health`,
      issues,
    );
  }

  async upsert(userId: string, input: UpsertBodyMeasurement): Promise<BodyMeasurementResponse> {
    const profile = await this.profileOf(userId);
    const today = localDate(this.clock.now(), profile.timezone);
    if (input.measuredOn > today) {
      throw ApiError.validation([{ path: 'body.measuredOn', message: 'measuredOn cannot be in the future' }]);
    }
    const needed = scopesFor(input);
    const missing = (status: ReturnType<typeof healthConsentStatus>) => needed.filter((s) => !coversScopes(status, [s]));
    const before = missing(healthConsentStatus(await latestHealthConsent(this.prisma, userId)));
    if (before.length > 0) throw this.consentError(before, input);

    const data = {
      weightKg: input.weightKg,
      waistCm: input.waistCm,
      neckCm: input.neckCm,
      hipCm: input.hipCm,
      chestCm: input.chestCm,
      armCm: input.armCm,
      thighCm: input.thighCm,
    };
    return this.prisma.$transaction(async (tx) => {
      // Mismo candado por usuario que la retirada del consentimiento: o se guarda antes (y la
      // retirada lo borra) o se ve la retirada y no se guarda nada.
      await this.analytics.lockUser(tx, userId);
      const now = missing(healthConsentStatus(await latestHealthConsent(tx, userId)));
      if (now.length > 0) throw this.consentError(now, input);
      const measuredOn = dateColumn(input.measuredOn);
      const row = await tx.bodyMeasurement.upsert({
        where: { userId_measuredOn: { userId, measuredOn } },
        create: { userId, measuredOn, ...data },
        update: data,
      });
      if (input.weightKg !== null) {
        // El peso más reciente pasa al perfil: los objetivos nutricionales lo usan.
        const newer = await tx.bodyMeasurement.count({
          where: { userId, measuredOn: { gt: measuredOn }, weightKg: { not: null } },
        });
        if (newer === 0) await tx.trainingProfile.update({ where: { userId }, data: { weightKg: input.weightKg } });
      }
      await this.audit.record('body_measurement_saved', userId, tx);
      return toMeasurementResponse(row);
    });
  }

  async list(userId: string, query: BodyMeasurementListQuery): Promise<BodyMeasurementListResponse> {
    const profile = await this.profileOf(userId);
    const to = query.to ?? localDate(this.clock.now(), profile.timezone);
    const from = query.from ?? addDays(to, -BODY_HISTORY_DAYS);
    const rows = await this.prisma.bodyMeasurement.findMany({
      where: { userId, measuredOn: { gte: dateColumn(from), lte: dateColumn(to) } },
      orderBy: { measuredOn: 'asc' },
      take: 400,
    });
    return { items: rows.map(toMeasurementResponse) };
  }

  /** Borrado idempotente de las medidas de un día. El peso del perfil no cambia. */
  async remove(userId: string, date: string): Promise<void> {
    await this.prisma.$transaction(async (tx) => {
      const { count } = await tx.bodyMeasurement.deleteMany({ where: { userId, measuredOn: dateColumn(date) } });
      if (count > 0) await this.audit.record('body_measurement_deleted', userId, tx);
    });
  }

  /** GET /progress/body: se calcula al leer con funciones puras del motor (no escribe nada). */
  async progress(userId: string): Promise<BodyProgressResponse> {
    const profile = await this.profileOf(userId);
    const consent = healthConsentStatus(await latestHealthConsent(this.prisma, userId));
    const today = localDate(this.clock.now(), profile.timezone);
    const rows = (
      await this.prisma.bodyMeasurement.findMany({
        where: { userId, measuredOn: { gte: dateColumn(addDays(today, -BODY_HISTORY_DAYS)) } },
        orderBy: { measuredOn: 'asc' },
      })
    ).map(toMeasurementResponse);

    const weights = rows.flatMap((r) => (r.weightKg !== null ? [{ date: r.measuredOn, weightKg: r.weightKg }] : []));
    const latestWeight = weights.at(-1) ?? null;
    const derived = coversScopes(consent, ['derived_estimates']);
    const heightCm = profile.heightCm === null ? null : Number(profile.heightCm);
    const age = ageFrom(profile.birthYear, this.clock.now(), profile.timezone);

    // IMC (OMS): peso más reciente y altura del perfil.
    let bmiBlock: BodyProgressResponse['bmi'];
    if (!derived) bmiBlock = { status: 'consent_required', measuredOn: null, result: null, series: [] };
    else if (!latestWeight || heightCm === null) bmiBlock = { status: 'insufficient_data', measuredOn: null, result: null, series: [] };
    else {
      const result = bmi(latestWeight.weightKg, heightCm, age);
      bmiBlock = {
        status: result.status,
        measuredOn: latestWeight.date,
        result,
        series: weights.slice(-84).flatMap((w) => {
          const r = bmi(w.weightKg, heightCm, age);
          return r.value === null ? [] : [{ date: w.date, value: r.value }];
        }),
      };
    }

    // % de grasa (Marina): medidas del mismo día.
    const navyInput = (r: BodyMeasurementResponse) => ({
      sex: profile.sex,
      heightCm,
      neckCm: r.neckCm,
      waistCm: r.waistCm,
      hipCm: r.hipCm,
    });
    const complete = rows.filter((r) => r.waistCm !== null && r.neckCm !== null && (profile.sex !== 'female' || r.hipCm !== null));
    let fatBlock: BodyProgressResponse['bodyFat'];
    if (!derived) fatBlock = { status: 'consent_required', measuredOn: null, result: null, series: [] };
    else if (profile.sex !== 'male' && profile.sex !== 'female') {
      fatBlock = { status: 'not_applicable', measuredOn: null, result: navyBodyFat({ sex: profile.sex, heightCm, neckCm: null, waistCm: null }), series: [] };
    } else if (complete.length === 0 || heightCm === null) {
      fatBlock = { status: 'insufficient_data', measuredOn: null, result: null, series: [] };
    } else {
      const last = complete[complete.length - 1];
      const result = navyBodyFat(navyInput(last));
      fatBlock = {
        status: result.status,
        measuredOn: last.measuredOn,
        result,
        series: complete.flatMap((r) => {
          const x = navyBodyFat(navyInput(r));
          return x.percent === null ? [] : [{ date: r.measuredOn, percent: x.percent }];
        }),
      };
    }

    const circumferences: CircumferenceTrend[] = CIRCUMFERENCE_FIELDS.map((field) => {
      const withValue = rows.filter((r) => r[field] !== null);
      const last = withValue.at(-1);
      if (!last) return { field, latest: null, change4w: null, change12w: null };
      const value = last[field]!;
      const change = (days: number) => {
        const past = valueAtOrBefore(withValue, field, addDays(last.measuredOn, -days));
        return past === null ? null : Math.round((value - past) * 10) / 10;
      };
      return { field, latest: { date: last.measuredOn, value }, change4w: change(28), change12w: change(84) };
    });

    return {
      timezone: profile.timezone,
      weight: {
        latest: latestWeight ? { date: latestWeight.date, value: latestWeight.weightKg } : null,
        trend: weightTrend(weights, profile.goal),
      },
      bmi: bmiBlock,
      bodyFat: fatBlock,
      circumferences,
      disclaimer: NOT_A_DIAGNOSIS,
    };
  }
}
