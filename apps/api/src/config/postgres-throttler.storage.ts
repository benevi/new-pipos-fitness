import { Injectable } from '@nestjs/common';
import type { ThrottlerStorage } from '@nestjs/throttler';
import { log } from '../logging/logging';
import { PrismaService } from '../prisma/prisma.service';

type ThrottlerStorageRecord = Awaited<ReturnType<ThrottlerStorage['increment']>>;

/** Cada cuánto, como mucho, una réplica borra las filas caducadas (en la propia petición). */
export const THROTTLER_CLEANUP_INTERVAL_MS = 60_000;

interface Row {
  hits: number;
  expires_in_ms: number;
  blocked_for_ms: number | null;
}

/**
 * Almacén de @nestjs/throttler en Postgres (THROTTLE_STORE=postgres; issue #9): todas las
 * réplicas comparten los contadores. Ventana fija por clave con bloqueo, como el almacén en
 * memoria: la petición que supera el límite se bloquea `blockDuration` ms; mientras dura el
 * bloqueo no se cuentan más golpes; al acabar el bloqueo o la ventana el contador vuelve a 1.
 *
 * Un único `INSERT … ON CONFLICT DO UPDATE … RETURNING` por petición: atómico entre réplicas
 * (la fila queda bloqueada durante el upsert, así que dos golpes simultáneos nunca leen el mismo
 * contador). Los tiempos se calculan con el reloj de Postgres, común a todas las réplicas.
 *
 * Si la base de datos falla, la petición pasa (fail-open) y se registra el error: sin base de
 * datos la API no puede autenticar ni guardar nada, así que no hay nada que proteger.
 */
@Injectable()
export class PostgresThrottlerStorage implements ThrottlerStorage {
  private lastCleanup = 0;

  constructor(private readonly prisma: PrismaService) {}

  async increment(key: string, ttl: number, limit: number, blockDuration: number): Promise<ThrottlerStorageRecord> {
    try {
      await this.maybeCleanup();
      const rows = await this.prisma.$queryRaw<Row[]>`
        INSERT INTO "ThrottlerRecord" AS r ("key", "hits", "expiresAt", "blockedUntil")
        VALUES (
          ${key}, 1, now() + make_interval(secs => ${ttl}::double precision / 1000),
          CASE WHEN 1 > ${limit}::int THEN now() + make_interval(secs => ${blockDuration}::double precision / 1000) END
        )
        ON CONFLICT ("key") DO UPDATE SET
          "hits" = CASE
            WHEN r."blockedUntil" > now() THEN r."hits"
            WHEN r."blockedUntil" IS NOT NULL OR r."expiresAt" <= now() THEN 1
            ELSE r."hits" + 1 END,
          "expiresAt" = CASE
            WHEN r."blockedUntil" > now() THEN r."expiresAt"
            WHEN r."blockedUntil" IS NOT NULL OR r."expiresAt" <= now()
              THEN now() + make_interval(secs => ${ttl}::double precision / 1000)
            ELSE r."expiresAt" END,
          "blockedUntil" = CASE
            WHEN r."blockedUntil" > now() THEN r."blockedUntil"
            WHEN (CASE WHEN r."blockedUntil" IS NOT NULL OR r."expiresAt" <= now() THEN 1 ELSE r."hits" + 1 END) > ${limit}::int
              THEN now() + make_interval(secs => ${blockDuration}::double precision / 1000)
            ELSE NULL END
        RETURNING
          "hits",
          (EXTRACT(EPOCH FROM ("expiresAt" - now())) * 1000)::float8 AS expires_in_ms,
          (EXTRACT(EPOCH FROM ("blockedUntil" - now())) * 1000)::float8 AS blocked_for_ms`;
      return toRecord(rows[0]);
    } catch (error) {
      log('error', 'Throttler storage unavailable; request allowed', { name: (error as Error)?.name });
      return { totalHits: 0, timeToExpire: Math.ceil(ttl / 1000), isBlocked: false, timeToBlockExpire: 0 };
    }
  }

  /** Borra las filas caducadas (ventana y bloqueo terminados). Devuelve cuántas. */
  async cleanup(): Promise<number> {
    this.lastCleanup = Date.now();
    return this.prisma.$executeRaw`
      DELETE FROM "ThrottlerRecord"
      WHERE "expiresAt" <= now() AND ("blockedUntil" IS NULL OR "blockedUntil" <= now())`;
  }

  private async maybeCleanup(): Promise<void> {
    if (Date.now() - this.lastCleanup < THROTTLER_CLEANUP_INTERVAL_MS) return;
    await this.cleanup();
  }
}

export function toRecord(row: Row): ThrottlerStorageRecord {
  const blockedFor = row.blocked_for_ms ?? 0;
  const isBlocked = blockedFor > 0;
  return {
    totalHits: row.hits,
    timeToExpire: Math.max(0, Math.ceil(row.expires_in_ms / 1000)),
    isBlocked,
    timeToBlockExpire: isBlocked ? Math.ceil(blockedFor / 1000) : 0,
  };
}
