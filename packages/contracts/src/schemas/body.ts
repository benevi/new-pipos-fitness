import { z } from 'zod';
import { BodyFatResultSchema, BmiResultSchema, WeightTrendSchema } from '../engine-v2/body.js';
import { CalendarDateSchema, DateTimeSchema } from './common.js';

/**
 * Medidas corporales (idea 7, ADR-0013). DATOS DE SALUD (RGPD art. 9): requieren un consentimiento
 * de salud vigente que cubra su ámbito (`HealthConsentStatus.scopes`): `weight` para el peso y
 * `body_measurements` para los perímetros. Sin él → 409 HEALTH_CONSENT_REQUIRED y no se guarda nada.
 *
 * Puntos de medida (una cinta métrica, siempre igual y en condiciones parecidas):
 * - waistCm: hombres, abdomen a la altura del ombligo; mujeres, la parte más estrecha de la
 *   cintura (protocolo del método de la Marina, que es el que usa la estimación de % de grasa).
 * - neckCm: justo por debajo de la laringe. hipCm: la parte más ancha de los glúteos.
 * - chestCm: a la altura de los pezones, al final de una espiración normal.
 * - armCm: brazo relajado, punto medio entre el hombro (acromion) y el codo (olécranon).
 * - thighCm: punto medio entre la ingle y la rótula.
 * Pecho, brazo y muslo son solo de seguimiento: ninguna regla del motor los usa.
 */
export const BODY_MEASUREMENT_RANGES = {
  weightKg: [25, 400],
  waistCm: [40, 250],
  neckCm: [20, 70],
  hipCm: [50, 250],
  chestCm: [50, 220],
  armCm: [15, 80],
  thighCm: [25, 120],
} as const;
export type BodyMeasurementField = keyof typeof BODY_MEASUREMENT_RANGES;
export const BODY_MEASUREMENT_FIELDS = Object.keys(BODY_MEASUREMENT_RANGES) as BodyMeasurementField[];
/** Perímetros (todo salvo el peso): ámbito `body_measurements` del consentimiento. */
export const CIRCUMFERENCE_FIELDS = BODY_MEASUREMENT_FIELDS.filter((f) => f !== 'weightKg') as Exclude<
  BodyMeasurementField,
  'weightKg'
>[];

const measure = (f: BodyMeasurementField) =>
  z.number().min(BODY_MEASUREMENT_RANGES[f][0]).max(BODY_MEASUREMENT_RANGES[f][1]).nullable().default(null);

/**
 * PUT /me/measurements — guarda las medidas de un día (fecha local del usuario, no futura).
 * Sustituye las de ese día (un campo omitido queda vacío); idempotente. Al menos una medida.
 * Si es el peso más reciente, actualiza también `weightKg` del perfil (objetivos nutricionales).
 */
export const UpsertBodyMeasurementRequestSchema = z
  .object({
    measuredOn: CalendarDateSchema,
    weightKg: measure('weightKg'),
    waistCm: measure('waistCm'),
    neckCm: measure('neckCm'),
    hipCm: measure('hipCm'),
    chestCm: measure('chestCm'),
    armCm: measure('armCm'),
    thighCm: measure('thighCm'),
  })
  .strict()
  .refine((m) => BODY_MEASUREMENT_FIELDS.some((f) => m[f] !== null), 'At least one measurement is required');
export type UpsertBodyMeasurementRequest = z.input<typeof UpsertBodyMeasurementRequestSchema>;
export type UpsertBodyMeasurement = z.infer<typeof UpsertBodyMeasurementRequestSchema>;

export const BodyMeasurementResponseSchema = z
  .object({
    measuredOn: CalendarDateSchema,
    weightKg: z.number().nullable(),
    waistCm: z.number().nullable(),
    neckCm: z.number().nullable(),
    hipCm: z.number().nullable(),
    chestCm: z.number().nullable(),
    armCm: z.number().nullable(),
    thighCm: z.number().nullable(),
    updatedAt: DateTimeSchema,
  })
  .strict();
export type BodyMeasurementResponse = z.infer<typeof BodyMeasurementResponseSchema>;

/** GET /me/measurements?from=&to= (fechas incluidas; por defecto, los últimos 365 días). */
export const BodyMeasurementListQuerySchema = z
  .object({ from: CalendarDateSchema.optional(), to: CalendarDateSchema.optional() })
  .strict()
  .refine((q) => !q.from || !q.to || q.from <= q.to, { message: 'from must be on or before to', path: ['from'] });
export type BodyMeasurementListQuery = z.infer<typeof BodyMeasurementListQuerySchema>;

export const BodyMeasurementListResponseSchema = z
  .object({ items: z.array(BodyMeasurementResponseSchema).max(400) })
  .strict();
export type BodyMeasurementListResponse = z.infer<typeof BodyMeasurementListResponseSchema>;

export const MeasurementDateParamsSchema = z.object({ date: CalendarDateSchema }).strict();

const LatestValueSchema = z.object({ date: CalendarDateSchema, value: z.number() }).strict();

export const CircumferenceTrendSchema = z
  .object({
    field: z.enum(['waistCm', 'neckCm', 'hipCm', 'chestCm', 'armCm', 'thighCm']),
    latest: LatestValueSchema.nullable(),
    /** Cambio respecto a la medida más cercana de hace ~4 y ~12 semanas (cm); null sin dato. */
    change4w: z.number().nullable(),
    change12w: z.number().nullable(),
  })
  .strict();
export type CircumferenceTrend = z.infer<typeof CircumferenceTrendSchema>;

/**
 * GET /progress/body — evolución y estimaciones (solo lectura; se calculan al leer, nada se
 * guarda). IMC y % de grasa requieren el ámbito `derived_estimates` del consentimiento; si no,
 * `status: 'consent_required'`. Todo es orientativo: no es un diagnóstico.
 */
export const BodyProgressResponseSchema = z
  .object({
    timezone: z.string(),
    weight: z
      .object({
        latest: LatestValueSchema.nullable(),
        trend: WeightTrendSchema,
      })
      .strict(),
    bmi: z
      .object({
        status: z.enum(['ok', 'insufficient_data', 'consent_required', 'invalid_input']),
        /** Fecha del peso usado (la altura es la del perfil). */
        measuredOn: CalendarDateSchema.nullable(),
        result: BmiResultSchema.nullable(),
        /** IMC de cada registro de peso de la ventana (para la gráfica). */
        series: z.array(z.object({ date: CalendarDateSchema, value: z.number() }).strict()),
      })
      .strict(),
    bodyFat: z
      .object({
        status: z.enum(['ok', 'insufficient_data', 'consent_required', 'not_applicable', 'invalid_input']),
        /** Fecha de las medidas usadas (cintura, cuello y cadera del mismo día). */
        measuredOn: CalendarDateSchema.nullable(),
        result: BodyFatResultSchema.nullable(),
        series: z.array(z.object({ date: CalendarDateSchema, percent: z.number() }).strict()),
      })
      .strict(),
    circumferences: z.array(CircumferenceTrendSchema),
    disclaimer: z.string(),
  })
  .strict();
export type BodyProgressResponse = z.infer<typeof BodyProgressResponseSchema>;
