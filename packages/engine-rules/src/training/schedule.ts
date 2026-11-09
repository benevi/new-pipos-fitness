/**
 * Días de entreno y pausas planificadas (PROGRAMACION.md §16.18; idea 6 de docs/IDEAS_EL_PLAN.md).
 * Funciones puras sobre fechas de calendario ISO (YYYY-MM-DD, en la zona del usuario).
 *
 * El motor no se ata a días fijos: sigue el orden del microciclo (CUJ-5). Los días de entreno solo
 * sirven para recordar y para decir «hoy no te toca»; las pausas excluyen sus días de la
 * adherencia y de la ausencia que baja la carga tras ≥ 14 días.
 */
import type { engineV2 } from '@pipos/contracts';

export type PlannedBreak = engineV2.PlannedBreak;

const DAY = 86_400_000;

function toMs(date: string): number {
  return Date.UTC(+date.slice(0, 4), +date.slice(5, 7) - 1, +date.slice(8, 10));
}

function fromMs(ms: number): string {
  return new Date(ms).toISOString().slice(0, 10);
}

/** Día ISO de la semana: 1 = lunes … 7 = domingo. */
export function isoWeekday(date: string): number {
  const dow = new Date(toMs(date)).getUTCDay();
  return dow === 0 ? 7 : dow;
}

/** ¿Está `date` dentro de alguna pausa (ambos extremos incluidos)? */
export function inBreak(date: string, breaks: readonly PlannedBreak[]): boolean {
  return breaks.some((b) => b.startsOn <= date && date <= b.endsOn);
}

/** La pausa que cubre `date` (la que acaba más tarde si se solapan), o null. */
export function activeBreak<T extends PlannedBreak>(date: string, breaks: readonly T[]): T | null {
  let found: T | null = null;
  for (const b of breaks) if (b.startsOn <= date && date <= b.endsOn && (!found || b.endsOn > found.endsOn)) found = b;
  return found;
}

/** Días del intervalo [from, toExclusive) cubiertos por alguna pausa (sin contar dos veces). */
export function breakDaysInRange(from: string, toExclusive: string, breaks: readonly PlannedBreak[]): number {
  let n = 0;
  for (let ms = toMs(from); ms < toMs(toExclusive); ms += DAY) if (inBreak(fromMs(ms), breaks)) n++;
  return n;
}

/**
 * Días de ausencia entre la última sesión y hoy SIN contar los días en pausa planificada.
 * Es lo que se compara con `breakDays` (§16.9) para la vuelta tras una pausa larga.
 */
export function daysAwayExcludingBreaks(lastDate: string, today: string, breaks: readonly PlannedBreak[] = []): number {
  const gap = Math.round((toMs(today) - toMs(lastDate)) / DAY);
  if (gap <= 1 || breaks.length === 0) return gap;
  return gap - breakDaysInRange(fromMs(toMs(lastDate) + DAY), today, breaks);
}

export interface WeekPlan {
  /** Sesiones previstas en la semana tras descontar las pausas. */
  planned: number;
  /** Días de la semana (0-7) cubiertos por una pausa. */
  breakDays: number;
}

/**
 * Sesiones previstas de la semana que empieza en `weekStart` (lunes) descontando las pausas.
 * - Con días de entreno elegidos (tantos como sesiones): se cuentan los días elegidos fuera de pausa.
 * - Si no: reparto proporcional `round(sesiones × días_sin_pausa / 7)`, mínimo 0 (heurística).
 */
export function plannedSessionsForWeek(
  sessionsPerWeek: number,
  weekStart: string,
  breaks: readonly PlannedBreak[] = [],
  trainingWeekdays: readonly number[] = [],
): WeekPlan {
  const days = Array.from({ length: 7 }, (_, i) => fromMs(toMs(weekStart) + i * DAY));
  const covered = days.filter((d) => inBreak(d, breaks));
  if (covered.length === 0) return { planned: sessionsPerWeek, breakDays: 0 };
  const chosen = new Set(trainingWeekdays);
  if (chosen.size > 0 && chosen.size === sessionsPerWeek) {
    return { planned: days.filter((d) => chosen.has(isoWeekday(d)) && !inBreak(d, breaks)).length, breakDays: covered.length };
  }
  return { planned: Math.max(0, Math.round((sessionsPerWeek * (7 - covered.length)) / 7)), breakDays: covered.length };
}

/**
 * ¿Hoy es día de entreno? Con días elegidos, si `date` es uno de ellos; sin elegir, los días por
 * defecto del plan (`defaultWeekdays`, 1-7). En pausa, nunca.
 */
export function isScheduledDay(
  date: string,
  trainingWeekdays: readonly number[],
  defaultWeekdays: readonly number[],
  breaks: readonly PlannedBreak[] = [],
): boolean {
  if (inBreak(date, breaks)) return false;
  const days = trainingWeekdays.length > 0 ? trainingWeekdays : defaultWeekdays;
  return days.includes(isoWeekday(date));
}
