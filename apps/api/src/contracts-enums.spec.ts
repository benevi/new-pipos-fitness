import { describe, expect, it } from 'vitest';
import { $Enums } from '@prisma/client';
import * as c from '@pipos/contracts';
import { FEATURE_MODULES } from './app.module';
import { redact, REDACTED } from './logging/logging';
import { buildOpenApiDocument, collectRoutes } from './openapi/openapi';

/** Los enums de Prisma y los de @pipos/contracts no pueden divergir (docs/MODELO_DATOS.md §2). */
const PAIRS: Record<string, readonly string[]> = {
  Role: c.ROLES,
  Locale: c.LOCALES,
  Sex: c.SEXES,
  TrainingGoal: c.TRAINING_GOALS,
  TrainingLevel: c.TRAINING_LEVELS,
  ActivityLevel: c.ACTIVITY_LEVELS,
  Equipment: c.EQUIPMENT,
  BodyZone: c.BODY_ZONES,
  Muscle: c.MUSCLES,
  VolumeGroup: c.engineV2.VOLUME_GROUPS,
  MuscleRole: c.MUSCLE_ROLES,
  MovementPattern: c.MOVEMENT_PATTERNS,
  LoadType: c.LOAD_TYPES,
  RiskLevel: c.RISK_LEVELS,
  ExercisePreferenceKind: c.EXERCISE_PREFERENCE_KINDS,
  MediaKind: c.MEDIA_KINDS,
  ModerationStatus: c.MODERATION_STATUSES,
  ConsentPurpose: c.CONSENT_PURPOSES,
  ConsentAction: c.CONSENT_ACTIONS,
  RefreshTokenRevokeReason: c.REFRESH_TOKEN_REVOKE_REASONS,
  PlanStatus: c.PLAN_STATUSES,
  SessionKind: c.SESSION_KINDS,
  ExerciseRole: c.EXERCISE_ROLES,
  WorkoutStatus: c.WORKOUT_STATUSES,
  AuditEventType: c.AUDIT_EVENT_TYPES,
};

describe('enums BD ↔ contratos', () => {
  it('cubre todos los enums de Prisma', () => {
    expect(Object.keys($Enums).sort()).toEqual(Object.keys(PAIRS).sort());
  });
  it.each(Object.entries(PAIRS))('%s coincide', (name, values) => {
    expect(Object.values(($Enums as Record<string, Record<string, string>>)[name]).sort()).toEqual([...values].sort());
  });
});

describe('logs', () => {
  it('redact elimina PII y datos de salud a cualquier profundidad', () => {
    expect(redact({ a: 1, email: 'x', nested: [{ weightKg: 80, Limitations: ['knee'], ok: true }] })).toEqual({
      a: 1,
      email: REDACTED,
      nested: [{ weightKg: REDACTED, Limitations: REDACTED, ok: true }],
    });
    expect(redact('plain')).toBe('plain');
  });
});

describe('OpenAPI', () => {
  it('cada ruta tiene @Contract con respuesta declarada', () => {
    const routes = collectRoutes(FEATURE_MODULES);
    expect(routes.length).toBeGreaterThanOrEqual(25);
    for (const r of routes) expect({ route: `${r.method} ${r.path}`, hasContract: !!r.spec }).toEqual({ route: `${r.method} ${r.path}`, hasContract: true });
  });
  it('el documento referencia componentes con nombre y ErrorResponse', () => {
    const doc = buildOpenApiDocument(FEATURE_MODULES, { version: 'test' });
    expect(doc.components.schemas.ErrorResponse).toBeDefined();
    expect(doc.paths['/workouts/{id}/sets'].post.responses['200']).toBeDefined();
    expect(doc.paths['/me/profile'].put.requestBody.content['application/json'].schema.$ref).toBe(
      '#/components/schemas/ProfileUpsertRequest',
    );
  });
});
