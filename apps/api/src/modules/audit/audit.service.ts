import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { AuditEventType } from '@pipos/contracts';
import { Clock } from '../../common/clock';
import { PrismaService, type TransactionClient } from '../../prisma/prisma.service';

/**
 * Días que se conservan los eventos de auditoría (issue #17). Suficiente para investigar un
 * incidente (y notificarlo en 72 h) sin convertir el registro en un historial de actividad.
 * Se aplica con `pnpm --filter @pipos/api audit:cleanup` (diario, desde el planificador del hosting).
 */
export const AUDIT_RETENTION_DAYS = 180;
const DAY_MS = 24 * 60 * 60 * 1000;

type Db = PrismaService | TransactionClient;

/**
 * Registro de auditoría append-only (AuditEvent; issue #17). Solo guarda tipo, usuario y fecha:
 * nunca emails, IPs, tokens ni valores de salud. Se escribe en la misma transacción que el cambio
 * auditado cuando la hay (`db` = `tx`).
 */
@Injectable()
export class AuditService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly clock: Clock,
  ) {}

  /** `userId` null = no se sabe de quién es (p. ej. login con un email desconocido). */
  async record(type: Exclude<AuditEventType, 'account_deleted'>, userId: string | null, db: Db = this.prisma): Promise<void> {
    await db.auditEvent.create({ data: { type, userId, createdAt: this.clock.now() } });
  }

  /**
   * Borrado de la cuenta: el evento sobrevive al borrado en cascada porque no guarda el userId,
   * sino un id aleatorio sin relación con el usuario (prueba de que hubo una supresión, sin
   * datos personales). Devuelve ese id.
   */
  async recordAccountDeleted(db: Db = this.prisma): Promise<string> {
    const subjectRef = randomUUID();
    await db.auditEvent.create({ data: { type: 'account_deleted', userId: null, subjectRef, createdAt: this.clock.now() } });
    return subjectRef;
  }

  /** Eventos del usuario para GET /me/export (sin ids internos). */
  async forExport(userId: string): Promise<{ type: AuditEventType; occurredAt: string }[]> {
    const rows = await this.prisma.auditEvent.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
      select: { type: true, createdAt: true },
    });
    return rows.map((r) => ({ type: r.type, occurredAt: r.createdAt.toISOString() }));
  }

  /** Retención: borra los eventos con más de AUDIT_RETENTION_DAYS. Devuelve cuántos. */
  async cleanup(now: Date = this.clock.now()): Promise<number> {
    const cutoff = new Date(now.getTime() - AUDIT_RETENTION_DAYS * DAY_MS);
    const { count } = await this.prisma.auditEvent.deleteMany({ where: { createdAt: { lt: cutoff } } });
    return count;
  }
}
