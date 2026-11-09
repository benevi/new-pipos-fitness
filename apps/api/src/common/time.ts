/**
 * Fechas de calendario en la zona horaria IANA del usuario (límites de semana de la analítica,
 * "hoy" para la progresión). Sin dependencias: Intl hace la conversión de zona.
 */

const formatters = new Map<string, Intl.DateTimeFormat>();

function formatter(tz: string): Intl.DateTimeFormat {
  let f = formatters.get(tz);
  if (!f) {
    f = new Intl.DateTimeFormat('en-US', {
      timeZone: tz,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
    });
    formatters.set(tz, f);
  }
  return f;
}

function parts(instant: Date, tz: string): Record<string, number> {
  const out: Record<string, number> = {};
  for (const p of formatter(tz).formatToParts(instant)) {
    if (p.type !== 'literal') out[p.type] = Number(p.value);
  }
  return out;
}

const pad = (n: number, len = 2) => String(n).padStart(len, '0');

/** Fecha local (YYYY-MM-DD) de un instante en la zona `tz`. */
export function localDate(instant: Date, tz: string): string {
  const p = parts(instant, tz);
  return `${pad(p.year, 4)}-${pad(p.month)}-${pad(p.day)}`;
}

/** Desfase (ms) de la zona respecto a UTC en ese instante. */
export function tzOffsetMs(instant: Date, tz: string): number {
  const p = parts(instant, tz);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return asUtc - Math.floor(instant.getTime() / 1000) * 1000;
}

function dateToUtcMs(date: string): number {
  return Date.UTC(+date.slice(0, 4), +date.slice(5, 7) - 1, +date.slice(8, 10));
}

export function addDays(date: string, days: number): string {
  return new Date(dateToUtcMs(date) + days * 86_400_000).toISOString().slice(0, 10);
}

/** Lunes ISO de la semana a la que pertenece `date`. */
export function isoWeekStart(date: string): string {
  const dow = new Date(dateToUtcMs(date)).getUTCDay(); // 0 = domingo
  return addDays(date, -((dow + 6) % 7));
}

/** Instante UTC de la medianoche local de `date` en `tz` (correcto en cambios de horario). */
export function zonedStartOfDay(date: string, tz: string): Date {
  const guess = dateToUtcMs(date);
  let result = guess - tzOffsetMs(new Date(guess), tz);
  result = guess - tzOffsetMs(new Date(result), tz);
  return new Date(result);
}

/** Rango [inicio, fin) en UTC de la semana ISO que empieza en `weekStart` (zona `tz`). */
export function weekRange(weekStart: string, tz: string): { from: Date; to: Date } {
  return { from: zonedStartOfDay(weekStart, tz), to: zonedStartOfDay(addDays(weekStart, 7), tz) };
}

/** Semana ISO (lunes local) de un instante. */
export function weekStartOf(instant: Date, tz: string): string {
  return isoWeekStart(localDate(instant, tz));
}

/** `YYYY-MM-DD` → Date a medianoche UTC (columnas @db.Date). */
export function dateColumn(date: string): Date {
  return new Date(dateToUtcMs(date));
}

/** Date de una columna @db.Date → `YYYY-MM-DD`. */
export function fromDateColumn(value: Date): string {
  return value.toISOString().slice(0, 10);
}
