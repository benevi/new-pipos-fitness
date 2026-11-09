import { createHash } from 'crypto';
import type { ConsentEvent, Prisma } from '@prisma/client';
import { HEALTH_CONSENT_POLICY, type HealthConsentStatus } from '@pipos/contracts';

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
 * Vigente = último evento `granted` con la versión actual del texto. Un cambio de versión
 * material exige volver a consentir (docs/MODELO_DATOS.md §5.2).
 */
export function healthConsentStatus(latest: ConsentEvent | null): HealthConsentStatus {
  const granted = latest?.action === 'granted' && latest.policyVersion === HEALTH_CONSENT_POLICY.version;
  return {
    granted,
    version: latest?.action === 'granted' ? latest.policyVersion : null,
    grantedAt: latest?.action === 'granted' ? latest.occurredAt.toISOString() : null,
    currentVersion: HEALTH_CONSENT_POLICY.version,
  };
}
