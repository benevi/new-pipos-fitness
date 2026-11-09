import { z } from 'zod';
import { ActivityLevelSchema } from '../engine-v2/nutrition.js';
import {
  BodyZoneSchema,
  EquipmentSchema,
  LocaleSchema,
  MuscleSchema,
  SexSchema,
  TrainingGoalSchema,
  TrainingLevelSchema,
} from '../enums/index.js';
import { DateTimeSchema, ExerciseSlugSchema } from './common.js';
import { PlanVersionSummarySchema } from './plans.js';

export function isValidTimeZone(tz: string): boolean {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

/** Zona horaria IANA (p. ej. "Europe/Madrid"). Fija los límites de semana de la analítica. */
export const TimezoneSchema = z.string().min(1).max(64).refine(isValidTimeZone, 'Unknown IANA time zone');

const uniqueArray = <T extends z.ZodTypeAny>(item: T, max: number) =>
  z
    .array(item)
    .max(max)
    .refine((a) => new Set(a).size === a.length, 'Duplicated values');

/**
 * Campos de salud (RGPD art. 9; docs/MODELO_DATOS.md §5.1). Solo se aceptan con un
 * consentimiento de salud vigente; sin él, enviar un valor no vacío devuelve
 * 409 HEALTH_CONSENT_REQUIRED.
 */
export const HEALTH_FIELDS = ['limitations', 'weightKg', 'heightCm'] as const;
export type HealthField = (typeof HEALTH_FIELDS)[number];

/**
 * PUT /me/profile: sustitución completa del perfil. Un campo opcional omitido se guarda vacío
 * (null o []). Nada se rellena por defecto en el servidor.
 */
export const ProfileUpsertRequestSchema = z
  .object({
    goal: TrainingGoalSchema,
    level: TrainingLevelSchema,
    daysPerWeek: z.number().int().min(2).max(6),
    minutesPerSession: z.number().int().min(30).max(90),
    equipment: uniqueArray(EquipmentSchema, 19),
    priorityMuscles: uniqueArray(MuscleSchema, 3).default([]),
    timezone: TimezoneSchema,
    activityLevel: ActivityLevelSchema.nullable().default(null),
    birthYear: z.number().int().min(1900).max(2100).nullable().default(null),
    sex: SexSchema.nullable().default(null),
    bannedExerciseSlugs: uniqueArray(ExerciseSlugSchema, 200).default([]),
    favouriteExerciseSlugs: uniqueArray(ExerciseSlugSchema, 200).default([]),
    // ── salud (art. 9) ──
    limitations: uniqueArray(BodyZoneSchema, 7).default([]),
    weightKg: z.number().min(25).max(400).nullable().default(null),
    heightCm: z.number().min(100).max(250).nullable().default(null),
  })
  .strict()
  .superRefine((p, ctx) => {
    const banned = new Set(p.bannedExerciseSlugs);
    for (const slug of p.favouriteExerciseSlugs) {
      if (banned.has(slug)) {
        ctx.addIssue({
          code: z.ZodIssueCode.custom,
          path: ['favouriteExerciseSlugs'],
          message: `"${slug}" cannot be banned and favourite at once`,
        });
      }
    }
  });
export type ProfileUpsertRequest = z.input<typeof ProfileUpsertRequestSchema>;
export type ProfileUpsert = z.infer<typeof ProfileUpsertRequestSchema>;

/**
 * Ámbitos de datos de salud que cubre cada versión del texto del consentimiento (ADR-0011,
 * ADR-0013). Un consentimiento de una versión anterior sigue vigente para SUS ámbitos; para los
 * nuevos hay que volver a consentir con la versión actual.
 */
export const HEALTH_DATA_SCOPES = ['weight', 'height', 'limitations', 'body_measurements', 'derived_estimates'] as const;
export const HealthDataScopeSchema = z.enum(HEALTH_DATA_SCOPES);
export type HealthDataScope = z.infer<typeof HealthDataScopeSchema>;

export interface HealthConsentPolicy {
  readonly version: string;
  readonly textEs: string;
  readonly scopes: readonly HealthDataScope[];
}

/** Versiones del texto, de la más antigua a la vigente. Nunca se edita una ya publicada. */
export const HEALTH_CONSENT_POLICIES: readonly HealthConsentPolicy[] = [
  {
    version: 'health-2026-11',
    textEs:
      'Acepto que Pipos Fitness trate mis datos de salud (peso, altura y limitaciones o molestias por zona del cuerpo) ' +
      'con el único fin de adaptar mi plan de entrenamiento y mis objetivos nutricionales. Puedo retirar este ' +
      'consentimiento en cualquier momento desde Ajustes; al hacerlo se borran esos datos y el plan se regenera sin ellos. ' +
      'Pipos Fitness no da consejo médico.',
    scopes: ['weight', 'height', 'limitations'],
  },
  {
    version: 'health-2026-11-v2',
    textEs:
      'Acepto que Pipos Fitness trate mis datos de salud (peso, altura, limitaciones o molestias por zona del cuerpo y ' +
      'medidas corporales: perímetros de cintura, cuello, cadera, pecho, brazo y muslo) con el fin de adaptar mi plan de ' +
      'entrenamiento y mis objetivos nutricionales, y de mostrarme su evolución y estimaciones derivadas (índice de masa ' +
      'corporal y porcentaje de grasa estimado). Puedo retirar este consentimiento en cualquier momento desde Ajustes; al ' +
      'hacerlo se borran esos datos, incluido el registro de medidas, y el plan se regenera sin ellos. Las estimaciones ' +
      'no son un diagnóstico y Pipos Fitness no da consejo médico.',
    scopes: ['weight', 'height', 'limitations', 'body_measurements', 'derived_estimates'],
  },
];

/** Texto versionado VIGENTE del consentimiento de salud. `textHash` se guarda como prueba (art. 7.1). */
export const HEALTH_CONSENT_POLICY: HealthConsentPolicy = HEALTH_CONSENT_POLICIES[HEALTH_CONSENT_POLICIES.length - 1];

/** Ámbitos que cubre una versión (vacío si la versión no existe). */
export function healthConsentScopes(version: string | null | undefined): HealthDataScope[] {
  return [...(HEALTH_CONSENT_POLICIES.find((p) => p.version === version)?.scopes ?? [])];
}

export const HealthConsentStatusSchema = z
  .object({
    granted: z.boolean(),
    /** Versión aceptada (null si nunca se concedió o se retiró). */
    version: z.string().nullable(),
    grantedAt: DateTimeSchema.nullable(),
    /** Versión vigente del texto; si difiere de `version`, hay que volver a pedirlo para los ámbitos nuevos. */
    currentVersion: z.string(),
    /**
     * Ámbitos cubiertos por el consentimiento vigente (ADR-0013). Una versión anterior sigue
     * cubriendo sus ámbitos (peso, altura, limitaciones); las medidas corporales y las
     * estimaciones derivadas requieren la versión actual. Siempre presente en el servidor.
     */
    scopes: z.array(HealthDataScopeSchema).default([]),
  })
  .strict();
export type HealthConsentStatus = z.infer<typeof HealthConsentStatusSchema>;

export const GrantHealthConsentRequestSchema = z
  .object({
    version: z.string().min(1).max(32),
    locale: LocaleSchema.default('es'),
  })
  .strict();
export type GrantHealthConsentRequest = z.input<typeof GrantHealthConsentRequestSchema>;

export const ProfileResponseSchema = z
  .object({
    goal: TrainingGoalSchema,
    level: TrainingLevelSchema,
    daysPerWeek: z.number().int(),
    minutesPerSession: z.number().int(),
    equipment: z.array(EquipmentSchema),
    priorityMuscles: z.array(MuscleSchema),
    timezone: z.string(),
    activityLevel: ActivityLevelSchema.nullable(),
    birthYear: z.number().int().nullable(),
    sex: SexSchema.nullable(),
    bannedExerciseSlugs: z.array(z.string()),
    favouriteExerciseSlugs: z.array(z.string()),
    limitations: z.array(BodyZoneSchema),
    weightKg: z.number().nullable(),
    heightCm: z.number().nullable(),
    healthConsent: HealthConsentStatusSchema,
    updatedAt: DateTimeSchema,
    /**
     * Días de entreno preferidos (ISO 1 = lunes … 7 = domingo; idea 6, ADR-0013). Siempre
     * presente en el servidor; el `default` solo mantiene válidos los clientes anteriores.
     */
    trainingWeekdays: z.array(z.number().int().min(1).max(7)).default([]),
  })
  .strict();
export type ProfileResponse = z.infer<typeof ProfileResponseSchema>;

export const ProfileUpdateResponseSchema = z
  .object({
    profile: ProfileResponseSchema,
    /** Nueva versión del plan si había un plan y cambió algo que lo afecta (CUJ-6); si no, null. */
    planVersion: PlanVersionSummarySchema.nullable(),
  })
  .strict();
export type ProfileUpdateResponse = z.infer<typeof ProfileUpdateResponseSchema>;

export const WithdrawHealthConsentResponseSchema = z
  .object({
    healthConsent: HealthConsentStatusSchema,
    /** Plan regenerado sin datos de salud (null si el usuario no tenía plan). */
    planVersion: PlanVersionSummarySchema.nullable(),
  })
  .strict();
export type WithdrawHealthConsentResponse = z.infer<typeof WithdrawHealthConsentResponseSchema>;

/**
 * PATCH /me/profile/schedule — días de entreno preferidos (idea 6, ADR-0013). Como mucho
 * `daysPerWeek` días (si no, 422). No es una entrada del motor: NO crea una versión del plan.
 * Sirve para el recordatorio LOCAL del móvil (no hay push del servidor) y para «hoy toca».
 * `PUT /me/profile` los conserva salvo que `daysPerWeek` baje por debajo de su número (se vacían).
 */
export const ProfileScheduleRequestSchema = z
  .object({ trainingWeekdays: uniqueArray(z.number().int().min(1).max(7), 6) })
  .strict();
export type ProfileScheduleRequest = z.infer<typeof ProfileScheduleRequestSchema>;
