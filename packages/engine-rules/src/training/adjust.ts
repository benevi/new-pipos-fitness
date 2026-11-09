/**
 * Ajuste de la sesión de hoy (PROGRAMACION.md §16.17; idea 4 de docs/IDEAS_EL_PLAN.md).
 *
 * - Poco tiempo: se quitan ejercicios ENTEROS de menor prioridad (core → accesorio → secundario,
 *   del último al primero) hasta que la estimación cabe; nunca el principal. Si solo con los
 *   principales sigue sin caber, se quita una serie a cada principal (mínimo 2) y se avisa.
 * - Volumen reducido (opción voluntaria): una serie menos por ejercicio, RIR + 1 y sin subida de
 *   carga ese día.
 *
 * Nunca aumenta el volumen: el resultado tiene un subconjunto de los ejercicios y, para cada uno,
 * las mismas series o menos. No crea una versión del plan. Función pura y determinista.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';
import { estimateSessionMinutes } from './estimate.js';
import { fmt, list } from './labels.js';

export interface AdjustItem {
  /** Identificador estable del hueco (planExerciseId en la API). */
  readonly id: string;
  readonly nameEs: string;
  readonly role: engineV2.ExerciseRole;
  readonly order: number;
  readonly sets: number;
  readonly repMin: number;
  readonly repMax: number;
  readonly targetRir: number;
  readonly restSeconds: number;
  readonly isUnilateral: boolean;
  readonly warmupSets: number;
}

export interface SessionAdjustment {
  /** Minutos disponibles hoy (incluye el calentamiento general). */
  readonly availableMinutes?: number | null;
  readonly reducedVolume?: boolean;
}

export interface AdjustedItem {
  readonly id: string;
  readonly sets: number;
  readonly targetRir: number;
}

export interface AdjustResult {
  readonly kept: AdjustedItem[];
  /** Huecos quitados, en el orden en que se quitaron. */
  readonly dropped: string[];
  readonly estimatedMinutes: number;
  /** false si ni con solo los principales al mínimo cabe en el tiempo disponible. */
  readonly fits: boolean;
  readonly rationale: string[];
}

export function adjustSession(
  items: readonly AdjustItem[],
  adjustment: SessionAdjustment,
  config: ProgrammingConfig = PROGRAMMING,
): AdjustResult {
  const a = config.adjust;
  const work = items
    .map((it) => ({ ...it }))
    .sort((x, y) => x.order - y.order);
  const rationale: string[] = [];

  // 1. Volumen reducido: una serie menos y RIR + 1 (nunca por debajo del mínimo).
  if (adjustment.reducedVolume) {
    for (const it of work) {
      const min = it.role === 'main' || it.role === 'secondary' ? a.reducedMinSetsMain.value : a.reducedMinSetsOther.value;
      it.sets = Math.min(it.sets, Math.max(min, it.sets - a.reducedSetsDelta.value));
      it.targetRir = Math.min(5, it.targetRir + a.reducedExtraRir.value);
    }
    rationale.push(
      `Volumen reducido: ${a.reducedSetsDelta.value} serie menos por ejercicio (mínimo ${a.reducedMinSetsMain.value} en los principales y secundarios), ${a.reducedExtraRir.value} repetición más en reserva y sin subir carga hoy. No cambia tu plan.`,
    );
  }

  const estimate = (list_: typeof work) => estimateSessionMinutes(list_, config);
  const dropped: typeof work = [];
  let fits = true;
  const available = adjustment.availableMinutes ?? null;

  if (available !== null) {
    const target = Math.min(a.maxMinutes.value, Math.max(a.minMinutes.value, available));
    // 2. Quitar ejercicios enteros por prioridad inversa: core → accesorio → secundario.
    for (const role of a.dropOrder.value) {
      const candidates = work.filter((it) => it.role === role).sort((x, y) => y.order - x.order);
      for (const c of candidates) {
        if (estimate(work) <= target) break;
        work.splice(work.indexOf(c), 1);
        dropped.push(c);
      }
    }
    // 3. Solo principales y aún no cabe: una serie menos a cada uno, del último al primero.
    const trimmedIds = new Set<string>();
    let changed = true;
    while (estimate(work) > target && changed) {
      changed = false;
      for (const it of [...work].sort((x, y) => y.order - x.order)) {
        if (estimate(work) <= target) break;
        if (it.sets > a.minMainSets.value) {
          it.sets -= 1;
          trimmedIds.add(it.id);
          changed = true;
        }
      }
    }
    fits = estimate(work) <= target;
    const est = estimate(work);
    if (dropped.length > 0) {
      const sets = dropped.reduce((n, d) => n + d.sets, 0);
      rationale.push(
        `Quitamos ${list(dropped.map((d) => d.nameEs))} (${sets} series de menor prioridad) para que la sesión dure unos ${fmt(est)} min de tus ${target} min. Los principales se mantienen: el volumen de la semana es lo que más cuenta.`,
      );
    }
    const trimmed = work.filter((it) => trimmedIds.has(it.id));
    if (trimmed.length > 0) {
      rationale.push(`Para ajustarnos al tiempo, ${list(trimmed.map((t) => t.nameEs))} ${trimmed.length > 1 ? 'bajan' : 'baja'} series (mínimo ${a.minMainSets.value}).`);
    }
    if (!fits) {
      rationale.push(
        `Ni con solo los ejercicios principales a ${a.minMainSets.value} series cabe en ${target} min (unos ${fmt(est)} min): haz lo que puedas empezando por el primero.`,
      );
    }
    if (dropped.length === 0 && fits && trimmed.length === 0) {
      rationale.push(`La sesión ya cabe en ${target} min (unos ${fmt(est)} min): no hace falta quitar nada.`);
    }
  }

  return {
    kept: work.map((it) => ({ id: it.id, sets: it.sets, targetRir: it.targetRir })),
    dropped: dropped.map((d) => d.id),
    estimatedMinutes: estimate(work),
    fits,
    rationale,
  };
}

/**
 * Prescripción de hoy tras el ajuste: nunca más series ni menos RIR que la del motor. Con volumen
 * reducido, si el motor proponía subir carga, se mantiene (`hold`) la carga actual.
 */
export function adjustedPrescription(
  next: engineV2.NextPrescription,
  adjusted: AdjustedItem,
  reducedVolume: boolean,
  currentLoadKg: number | null,
): engineV2.NextPrescription {
  const sets = Math.min(next.sets, adjusted.sets);
  const targetRir = reducedVolume ? Math.max(next.targetRir, adjusted.targetRir) : next.targetRir;
  const base = { ...next, sets, targetRir };
  if (!reducedVolume || next.action !== 'increase_load') return base;
  return {
    ...base,
    action: 'hold',
    loadKg: currentLoadKg,
    rationale: [
      `Hoy con volumen reducido no subimos carga: mantén ${currentLoadKg !== null ? `${fmt(currentLoadKg)} kg` : 'la carga'}; la subida queda para la próxima sesión normal.`,
    ],
  };
}
