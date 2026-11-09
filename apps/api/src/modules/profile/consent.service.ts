import { HttpStatus, Injectable } from '@nestjs/common';
import {
  HEALTH_CONSENT_POLICY,
  type GrantHealthConsentRequest,
  type HealthConsentStatus,
  type Locale,
  type WithdrawHealthConsentResponse,
} from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { PrismaService } from '../../prisma/prisma.service';
import { buildEngineProfile, EngineInputService } from '../plans/engine-input.service';
import { PlansService, type PreparedPlan } from '../plans/plans.service';
import { HEALTH_POLICY_TEXT_HASH, healthConsentStatus, latestHealthConsent } from './consent-status';

export interface ConsentRequestMeta {
  ip?: string;
  userAgent?: string;
}

const IPV4_OR_6 = /^[0-9a-fA-F:.]{2,45}$/;

/**
 * Consentimiento explícito para datos de salud (RGPD art. 9.2.a; ADR-0011).
 * Registro append-only en ConsentEvent; la retirada borra los datos de salud, redacta las
 * instantáneas de los planes y los textos derivados de salud de sus explicaciones, y regenera el plan sin ellos, todo en una transacción.
 */
@Injectable()
export class ConsentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly engineInput: EngineInputService,
    private readonly plans: PlansService,
    private readonly clock: Clock,
  ) {}

  async status(userId: string): Promise<HealthConsentStatus> {
    return healthConsentStatus(await latestHealthConsent(this.prisma, userId));
  }

  async grant(
    userId: string,
    input: { version: string; locale: Locale } & GrantHealthConsentRequest,
    meta: ConsentRequestMeta = {},
  ): Promise<HealthConsentStatus> {
    if (input.version !== HEALTH_CONSENT_POLICY.version) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'HEALTH_CONSENT_VERSION_MISMATCH',
        `The current consent text is version ${HEALTH_CONSENT_POLICY.version}`,
        [{ path: 'body.version', message: `Expected ${HEALTH_CONSENT_POLICY.version}` }],
      );
    }
    const current = healthConsentStatus(await latestHealthConsent(this.prisma, userId));
    if (current.granted) return current; // idempotente: no duplica el evento
    await this.prisma.consentEvent.create({
      data: {
        userId,
        purpose: 'health_data_processing',
        action: 'granted',
        policyVersion: input.version,
        textHash: HEALTH_POLICY_TEXT_HASH,
        locale: input.locale,
        occurredAt: this.clock.now(),
        ip: meta.ip && IPV4_OR_6.test(meta.ip) ? meta.ip : null,
        userAgent: meta.userAgent?.slice(0, 512) ?? null,
      },
    });
    return this.status(userId);
  }

  async withdraw(userId: string, meta: ConsentRequestMeta = {}): Promise<WithdrawHealthConsentResponse> {
    const latest = await latestHealthConsent(this.prisma, userId);
    const ctx = await this.engineInput.load(userId);
    let prepared: PreparedPlan | null = null;
    if (ctx && (await this.plans.hasActivePlan(userId))) {
      const withoutHealth = buildEngineProfile(ctx.profile, ctx.bannedSlugs, ctx.favouriteSlugs, false, this.clock.now());
      prepared = await this.plans.prepare(userId, withoutHealth, ctx.profile.timezone);
    }

    const planVersion = await this.plans.withVersionRetry(async (tx) => {
      if (latest?.action === 'granted') {
        await tx.consentEvent.create({
          data: {
            userId,
            purpose: 'health_data_processing',
            action: 'withdrawn',
            policyVersion: latest.policyVersion,
            textHash: latest.textHash,
            locale: latest.locale,
            occurredAt: this.clock.now(),
            ip: meta.ip && IPV4_OR_6.test(meta.ip) ? meta.ip : null,
            userAgent: meta.userAgent?.slice(0, 512) ?? null,
          },
        });
      }
      await tx.trainingProfile.updateMany({
        where: { userId },
        data: { limitations: [], weightKg: null, heightCm: null },
      });
      // Redacta los datos de salud copiados en las instantáneas de versiones anteriores.
      await tx.$executeRaw`
        UPDATE "PlanVersion"
        SET "inputSnapshot" = (("inputSnapshot" - 'limitations') #- '{body,weightKg}' #- '{body,heightCm}')
                              || jsonb_build_object('redacted', true)
        WHERE "userId" = ${userId}::uuid`;
      // Y los textos derivados de salud (zona limitada) de las explicaciones guardadas:
      // las del plan (healthNotes y avisos con health: true) y las de cada ejercicio.
      await tx.$executeRaw`
        UPDATE "PlanVersion"
        SET "rationale" = jsonb_set(
              jsonb_set("rationale", '{healthNotes}', '[]'::jsonb),
              '{warnings}',
              COALESCE(
                (SELECT jsonb_agg(w ORDER BY i)
                   FROM jsonb_array_elements("rationale" -> 'warnings') WITH ORDINALITY AS t(w, i)
                  WHERE COALESCE(w ->> 'health', 'false') <> 'true'),
                '[]'::jsonb))
        WHERE "userId" = ${userId}::uuid`;
      await tx.$executeRaw`
        UPDATE "PlanExercise" pe
        SET "rationale" = COALESCE(
              (SELECT jsonb_agg(e ORDER BY i)
                 FROM jsonb_array_elements(pe."rationale") WITH ORDINALITY AS t(e, i)
                WHERE jsonb_typeof(e) <> 'object' OR COALESCE(e ->> 'health', 'false') <> 'true'),
              '[]'::jsonb)
        FROM "PlanSession" ps
        WHERE pe."planSessionId" = ps."id" AND ps."userId" = ${userId}::uuid
          AND jsonb_typeof(pe."rationale") = 'array'`;
      return prepared ? this.plans.persistVersion(tx, userId, prepared) : null;
    });

    return { healthConsent: await this.status(userId), planVersion };
  }
}
