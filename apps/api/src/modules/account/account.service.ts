import { HttpStatus, Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import type { AccountExport, MeResponse } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { fromDateColumn } from '../../common/time';
import { log } from '../../logging/logging';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { AuthService } from '../auth/auth.service';
import { planVersionInclude, toVersionResponse } from '../plans/plan-mapper';
import { ProfileService } from '../profile/profile.service';
import { toMeasurementResponse } from '../profile/measurements.service';
import { toBreakResponse } from '../profile/schedule.service';
import { toNoteResponse } from '../workouts/notes.service';
import { toWorkoutResponse, workoutInclude } from '../workouts/workout-mapper';

/**
 * Derechos RGPD (ADR-0011): acceso/portabilidad (GET /me/export) y supresión (DELETE /me).
 */
@Injectable()
export class AccountService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auth: AuthService,
    private readonly profiles: ProfileService,
    private readonly clock: Clock,
    private readonly audit: AuditService,
  ) {}

  async me(userId: string): Promise<MeResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, role: true, locale: true, createdAt: true },
    });
    if (!user) throw new ApiError(HttpStatus.UNAUTHORIZED, 'UNAUTHORIZED', 'Unauthorized');
    return { ...user, createdAt: user.createdAt.toISOString() };
  }

  /** Todos los datos del usuario (sin passwordHash ni hashes de tokens). Solo lectura. */
  async export(userId: string): Promise<AccountExport> {
    const [user, profile, consentEvents, plans, workouts, e1rm, volume, adherence, notes, breaks, measurements, auditEvents] = await Promise.all([
      this.me(userId),
      this.profiles.find(userId),
      this.prisma.consentEvent.findMany({ where: { userId }, orderBy: { occurredAt: 'asc' } }),
      this.prisma.trainingPlan.findMany({
        where: { userId },
        orderBy: { createdAt: 'asc' },
        include: { versions: { orderBy: { version: 'asc' }, include: planVersionInclude } },
      }),
      this.prisma.workoutSession.findMany({ where: { userId }, orderBy: { startedAt: 'asc' }, include: workoutInclude }),
      this.prisma.exerciseE1rm.findMany({
        where: { userId },
        orderBy: { performedOn: 'asc' },
        include: { exercise: { select: { slug: true } } },
      }),
      this.prisma.weeklyMuscleVolume.findMany({ where: { userId }, orderBy: [{ weekStart: 'asc' }, { muscle: 'asc' }] }),
      this.prisma.weeklyAdherence.findMany({ where: { userId }, orderBy: { weekStart: 'asc' } }),
      this.prisma.userExerciseNote.findMany({
        where: { userId },
        orderBy: { exerciseId: 'asc' },
        include: { exercise: { select: { slug: true } } },
      }),
      this.prisma.trainingBreak.findMany({ where: { userId }, orderBy: [{ startsOn: 'asc' }, { id: 'asc' }] }),
      this.prisma.bodyMeasurement.findMany({ where: { userId }, orderBy: { measuredOn: 'asc' } }),
      this.audit.forExport(userId),
    ]);
    return {
      formatVersion: 1,
      exportedAt: this.clock.now().toISOString(),
      user,
      profile,
      consentEvents: consentEvents.map((c) => ({
        purpose: c.purpose,
        action: c.action,
        policyVersion: c.policyVersion,
        textHash: c.textHash,
        locale: c.locale,
        occurredAt: c.occurredAt.toISOString(),
      })),
      plans: plans.map((p) => ({
        id: p.id,
        status: p.status,
        createdAt: p.createdAt.toISOString(),
        versions: p.versions.map((v) => ({
          // Sin músculos: son datos del catálogo, no del usuario (`muscles` queda vacío).
          ...toVersionResponse(v, null),
          inputSnapshot: (v.inputSnapshot ?? {}) as Record<string, unknown>,
        })),
      })),
      workouts: workouts.map(toWorkoutResponse),
      exerciseNotes: notes.map(toNoteResponse),
      trainingBreaks: breaks.map(toBreakResponse),
      bodyMeasurements: measurements.map(toMeasurementResponse),
      auditEvents,
      analytics: {
        e1rm: e1rm.map((r) => ({
          exerciseId: r.exerciseId,
          slug: r.exercise.slug,
          workoutId: r.workoutSessionId,
          performedOn: fromDateColumn(r.performedOn),
          e1rmKg: Number(r.e1rmKg),
          formulaVersion: r.formulaVersion,
        })),
        weeklyMuscleVolume: volume.map((r) => ({
          weekStart: fromDateColumn(r.weekStart),
          muscle: r.muscle,
          effectiveSets: Number(r.effectiveSets),
          tonnageKg: Number(r.tonnageKg),
        })),
        weeklyAdherence: adherence.map((r) => ({
          weekStart: fromDateColumn(r.weekStart),
          plannedSessions: r.plannedSessions,
          completedSessions: r.completedSessions,
          plannedSets: r.plannedSets,
          completedSets: r.completedSets,
        })),
      },
    };
  }

  /**
   * Borrado real: una sola sentencia `DELETE FROM "User"` y la cascada de FK elimina perfil,
   * salud, consentimientos, planes, entrenamientos, analítica y refresh tokens. Los access
   * tokens dejan de valer porque JwtStrategy comprueba que el usuario existe.
   */
  async delete(userId: string, password: string): Promise<void> {
    if (!(await this.auth.verifyPassword(userId, password))) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'AUTH_INVALID_CREDENTIALS', 'Password confirmation failed');
    }
    // En la misma transacción: la cascada borra también sus eventos de auditoría, y queda solo
    // `account_deleted` con un id aleatorio (prueba de la supresión sin datos personales; issue #17).
    const deletionId = await this.prisma.$transaction(async (tx) => {
      await tx.user.delete({ where: { id: userId } });
      return this.audit.recordAccountDeleted(tx);
    });
    // Prueba de supresión sin datos personales (docs/MODELO_DATOS.md §5.4).
    log('info', 'account deleted', { subject: createHash('sha256').update(userId).digest('hex'), deletionId });
  }
}
