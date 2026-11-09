import { z } from 'zod';

/**
 * Enums cerrados compartidos por API, BD y móvil. Los valores coinciden 1:1 con los enums
 * de Prisma (apps/api/prisma/schema.prisma); un test de la API lo comprueba.
 * Los del dominio del motor viven en engine-v2/enums.ts y se reexportan aquí.
 */
export * from '../engine-v2/enums.js';
export { ACTIVITY_LEVELS, ActivityLevelSchema, type ActivityLevel } from '../engine-v2/nutrition.js';
export {
  SESSION_KINDS,
  SessionKindSchema,
  type SessionKind,
  EXERCISE_ROLES,
  ExerciseRoleSchema,
  type ExerciseRole,
} from '../engine-v2/plan.js';

export const ROLES = ['user', 'admin'] as const;
export const RoleSchema = z.enum(ROLES);
export type Role = z.infer<typeof RoleSchema>;

export const LOCALES = ['es', 'en'] as const;
export const LocaleSchema = z.enum(LOCALES);
export type Locale = z.infer<typeof LocaleSchema>;

export const LOAD_TYPES = ['weighted', 'unweighted'] as const;
export const LoadTypeSchema = z.enum(LOAD_TYPES);
export type LoadType = z.infer<typeof LoadTypeSchema>;

export const EXERCISE_PREFERENCE_KINDS = ['banned', 'favourite'] as const;
export const ExercisePreferenceKindSchema = z.enum(EXERCISE_PREFERENCE_KINDS);
export type ExercisePreferenceKind = z.infer<typeof ExercisePreferenceKindSchema>;

export const MEDIA_KINDS = ['youtube', 'image'] as const;
export const MediaKindSchema = z.enum(MEDIA_KINDS);
export type MediaKind = z.infer<typeof MediaKindSchema>;

export const MODERATION_STATUSES = ['pending', 'approved', 'rejected', 'unavailable'] as const;
export const ModerationStatusSchema = z.enum(MODERATION_STATUSES);
export type ModerationStatus = z.infer<typeof ModerationStatusSchema>;

export const CONSENT_PURPOSES = ['health_data_processing'] as const;
export const ConsentPurposeSchema = z.enum(CONSENT_PURPOSES);
export type ConsentPurpose = z.infer<typeof ConsentPurposeSchema>;

export const CONSENT_ACTIONS = ['granted', 'withdrawn'] as const;
export const ConsentActionSchema = z.enum(CONSENT_ACTIONS);
export type ConsentAction = z.infer<typeof ConsentActionSchema>;

export const REFRESH_TOKEN_REVOKE_REASONS = [
  'rotated',
  'logout',
  'reuse_detected',
  'password_changed',
  'account_deleted',
  'admin',
] as const;
export const RefreshTokenRevokeReasonSchema = z.enum(REFRESH_TOKEN_REVOKE_REASONS);
export type RefreshTokenRevokeReason = z.infer<typeof RefreshTokenRevokeReasonSchema>;

export const PLAN_STATUSES = ['active', 'archived'] as const;
export const PlanStatusSchema = z.enum(PLAN_STATUSES);
export type PlanStatus = z.infer<typeof PlanStatusSchema>;

/** Tipos del registro de auditoría (issue #17); se exportan en GET /me/export. */
export const AUDIT_EVENT_TYPES = [
  'login_succeeded',
  'login_failed',
  'refresh_reuse_detected',
  'health_consent_granted',
  'health_consent_withdrawn',
  'health_profile_changed',
  'body_measurement_saved',
  'body_measurement_deleted',
  'account_deleted',
] as const;
export const AuditEventTypeSchema = z.enum(AUDIT_EVENT_TYPES);
export type AuditEventType = z.infer<typeof AuditEventTypeSchema>;

export const WORKOUT_STATUSES = ['in_progress', 'completed', 'abandoned'] as const;
export const WorkoutStatusSchema = z.enum(WORKOUT_STATUSES);
export type WorkoutStatus = z.infer<typeof WorkoutStatusSchema>;
