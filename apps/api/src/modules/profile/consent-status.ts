import { createHash } from 'crypto';
import type { ConsentEvent, Prisma } from '@prisma/client';
import { HEALTH_CONSENT_POLICY, healthConsentScopes, type HealthConsentStatus, type HealthDataScope } from '@pipos/contracts';

type Db = Pick<Prisma.TransactionClient, 'consentEvent'>;

export const HEALTH_POLICY_TEXT_HASH = createHash('sha256').update(HEALTH_CONSENT_POLICY.textEs).digest('hex');

/** Último evento de consentimiento de salud (el registro es append-only). */
export function latestHealthConsent(db: Db, userId: string): Promise<ConsentEvent | null> {
  return db.consentEvent.findFirst({
    where: { userId, purpose: 'health_data_processing' },
    orderBy: { occurredAt: 'desc' },
  });
}

/**
 * Vigente = último evento `granted` con una versión publicada del texto. Cada versión cubre sus
 * ámbitos (HEALTH_CONSENT_POLICIES): una versión anterior sigue valiendo para lo que decía (peso,
 * altura, limitaciones) y los ámbitos nuevos (medidas corporales, estimaciones) exigen volver a
 * consentir con la versión actual (docs/MODELO_DATOS.md §5.2, ADR-0013).
 */
export function healthConsentStatus(latest: ConsentEvent | null): HealthConsentStatus {
  const scopes = latest?.action === 'granted' ? healthConsentScopes(latest.policyVersion) : [];
  return {
    granted: scopes.length > 0,
    version: latest?.action === 'granted' ? latest.policyVersion : null,
    grantedAt: latest?.action === 'granted' ? latest.occurredAt.toISOString() : null,
    currentVersion: HEALTH_CONSENT_POLICY.version,
    scopes,
  };
}

/** ¿El consentimiento vigente cubre todos estos ámbitos? */
export function coversScopes(status: HealthConsentStatus, needed: readonly HealthDataScope[]): boolean {
  return status.granted && needed.every((s) => status.scopes.includes(s));
}
