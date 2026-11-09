/**
 * Progresión sesión a sesión (PROGRAMACION.md §7, §16.9; CUJ-3 y CUJ-5):
 * doble progresión con autorregulación por RIR, descarga programada y reactiva,
 * y reajuste tras una pausa larga. Función pura: `today` llega como dato.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';
import { fmt } from './labels.js';
import { loadStepKg, roundLoad } from './load.js';
import { daysAwayExcludingBreaks } from './schedule.js';

type Log = engineV2.ExerciseSessionLog;

export function daysBetween(fromIso: string, toIso: string): number {
  const a = Date.UTC(+fromIso.slice(0, 4), +fromIso.slice(5, 7) - 1, +fromIso.slice(8, 10));
  const b = Date.UTC(+toIso.slice(0, 4), +toIso.slice(5, 7) - 1, +toIso.slice(8, 10));
  return Math.round((b - a) / 86_400_000);
}

function workSets(log: Log): engineV2.LoggedSet[] {
  return log.sets.filter((s) => !s.isWarmup);
}

/** Carga de trabajo de la sesión (la mayor de las series de trabajo) y mejor reps + RIR a esa carga. */
function topSet(log: Log): { loadKg: number; effReps: number } {
  const ws = workSets(log);
  const loadKg = Math.max(...ws.map((s) => s.loadKg));
  const effReps = Math.max(...ws.filter((s) => Math.abs(s.loadKg - loadKg) < 1e-9).map((s) => s.reps + (s.rir ?? 0)));
  return { loadKg, effReps };
}

/**
 * ¿La sesión `next` no mejora a `prev`? (estancamiento o regresión, PROGRAMACION.md §7 regla 4).
 * - Misma carga: compara reps + RIR de la mejor serie (≤ → estancado o peor).
 * - Carga mayor (p. ej., tras increase_load): hacer menos reps es lo esperado; no cuenta. El
 *   índice de Epley no es comparable entre cargas (60×12 → 62×8 «cae» un 6 % sin regresión real).
 * - Carga menor: regresión solo si, aun así, el e1RM (Epley con RIR) es más bajo; a menos carga
 *   y más reps Epley sobrestima, así que una caída es una regresión real.
 */
function notImproving(prev: Log, next: Log, divisor: number): boolean {
  const a = topSet(prev);
  const b = topSet(next);
  if (Math.abs(a.loadKg - b.loadKg) < 1e-9) return b.effReps <= a.effReps;
  if (b.loadKg > a.loadKg) return false;
  const e1rm = (t: { loadKg: number; effReps: number }) => t.loadKg * (1 + t.effReps / divisor);
  return e1rm(b) < e1rm(a) - 1e-9;
}

function underperformed(log: Log, p: engineV2.CurrentPrescription): boolean {
  return workSets(log).some((s) => s.reps < p.repMin || (s.rir !== undefined && s.rir < p.targetRir - 1));
}

function roundUp(kg: number, step: number): number {
  return Math.ceil(kg / step - 1e-9) * step;
}

export function nextPrescription(
  input: unknown,
  config: ProgrammingConfig = PROGRAMMING,
): engineV2.NextPrescriptionResult {
  const parsed = engineV2.NextPrescriptionInputSchema.safeParse(input);
  if (!parsed.success) {
    return {
      ok: false,
      error: {
        code: 'INVALID_INPUT',
        issues: parsed.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
      },
    };
  }
  const { prescription: p, today, weeksSinceDeload } = parsed.data;
  const pr = config.progression;
  const implement = p.implement ?? null;
  const step = loadStepKg(implement, config);
  /** Bajada al peso disponible inmediatamente inferior (§16.16), sin llegar a 0 ni subir. */
  const lower = (kg: number, current: number): number => {
    const down = roundLoad(kg, implement, 'down', config);
    if (down > 0) return Math.min(down, current);
    return Math.min(current, step);
  };
  const history = parsed.data.history
    .filter((h) => h.exerciseId === p.exerciseId && h.date <= today && workSets(h).length > 0)
    .sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0));

  const base = {
    sets: p.sets,
    repMin: p.repMin,
    repMax: p.repMax,
    targetRir: p.targetRir,
    loadKg: p.loadKg,
    isDeload: false,
  };
  const weighted = p.loadType === 'weighted';

  if (history.length === 0) {
    return {
      ok: true,
      next: {
        ...base,
        action: 'start',
        rationale: [
          weighted && p.loadKg === null
            ? `Primera sesión: elige un peso con el que hagas ${p.repMin} repeticiones dejando ${p.targetRir} en reserva.`
            : 'Primera sesión de este ejercicio: mantén la prescripción y registra reps y RIR.',
        ],
      },
    };
  }

  const last = history[history.length - 1];
  const lastLoad = Math.max(...workSets(last).map((s) => s.loadKg));
  const currentLoad = weighted ? (p.loadKg ?? (lastLoad > 0 ? lastLoad : null)) : p.loadKg;

  // 1. Vuelta tras una pausa larga (CUJ-5).
  // Los días en pausa planificada no cuentan como ausencia (§16.18).
  const gap = daysAwayExcludingBreaks(last.date, today, parsed.data.breaks ?? []);
  if (gap >= pr.breakDays.value) {
    const reduced =
      weighted && currentLoad !== null ? lower(currentLoad * (1 - pr.breakLoadReductionPct.value / 100), currentLoad) : currentLoad;
    return {
      ok: true,
      next: {
        ...base,
        loadKg: reduced,
        action: 'return_after_break',
        rationale: [
          weighted && currentLoad !== null
            ? `Llevas ${gap} días sin hacer este ejercicio: bajamos la carga un ${pr.breakLoadReductionPct.value} % (de ${fmt(currentLoad)} a ${fmt(reduced ?? 0)} kg) para retomar con margen.`
            : `Llevas ${gap} días sin hacer este ejercicio: retoma por la parte baja del rango (${p.repMin} reps) antes de progresar.`,
        ],
      },
    };
  }

  // 2. Descarga programada.
  if (weeksSinceDeload >= pr.deloadEveryWeeks.value) {
    return { ok: true, next: deload(base, p, config, `Han pasado ${weeksSinceDeload} semanas desde la última descarga.`) };
  }

  // 3. Descarga reactiva: estancamiento o regresión N sesiones seguidas (PROGRAMACION.md §7),
  //    comparando solo lo comparable (misma carga, o e1RM si la carga bajó).
  // Las sesiones ajustadas (poco tiempo o volumen reducido, §16.17) no cuentan: un día flojo
  // elegido no debe provocar una descarga ni una bajada de carga.
  const comparable = history.filter((h) => !h.adjusted);
  const n = pr.stagnationSessions.value;
  if (comparable.length >= n + 1) {
    const recent = comparable.slice(-(n + 1));
    let stalled = true;
    for (let i = 1; i < recent.length; i++) {
      if (!notImproving(recent[i - 1], recent[i], config.e1rm.epleyDivisor.value)) stalled = false;
    }
    if (stalled) {
      return {
        ok: true,
        next: deload(base, p, config, `Tus repeticiones o tu RIR no han mejorado (o han caído) ${n} sesiones seguidas con la misma carga.`),
      };
    }
  }

  // 4. Rendimiento por debajo del objetivo dos sesiones seguidas → bajar la carga.
  const lastComparable = comparable.length > 0 ? comparable[comparable.length - 1] : null;
  const prev = comparable.length >= 2 ? comparable[comparable.length - 2] : null;
  if (lastComparable === last && underperformed(last, p)) {
    if (prev && underperformed(prev, p) && weighted && currentLoad !== null) {
      const reduced = lower(currentLoad * (1 - pr.reactiveDecreasePct.value / 100), currentLoad);
      return {
        ok: true,
        next: {
          ...base,
          loadKg: reduced,
          action: 'decrease_load',
          rationale: [
            `Dos sesiones seguidas por debajo de ${p.repMin} reps o con menos RIR del previsto: bajamos un ${pr.reactiveDecreasePct.value} % (a ${fmt(reduced)} kg).`,
          ],
        },
      };
    }
    return {
      ok: true,
      next: {
        ...base,
        loadKg: currentLoad,
        action: 'hold',
        rationale: ['La última sesión quedó por debajo del objetivo: mantén la carga y busca completar el rango.'],
      },
    };
  }

  // 5. Doble progresión: todas las series en el techo con el RIR objetivo → subir carga.
  const ws = workSets(last);
  const topReached =
    ws.length >= p.sets &&
    ws.every((s) => s.reps >= p.repMax && (!pr.autoregulateByRir.value || s.rir === undefined || s.rir >= p.targetRir));
  if (topReached) {
    if (!weighted || currentLoad === null || currentLoad === 0) {
      return {
        ok: true,
        next: {
          ...base,
          action: 'progress_variant',
          rationale: [
            `Has completado ${p.sets}×${p.repMax} con RIR ${p.targetRir} o más: pasa a una variante más difícil (o una banda más dura) y vuelve a ${p.repMin} reps.`,
          ],
        },
      };
    }
    const lowerBody = pr.lowerBodyPatterns.value.includes(p.movementPattern);
    const pct = lowerBody ? pr.loadIncrementPctLower.value : pr.loadIncrementPctUpper.value;
    const rawInc = Math.max(pr.minIncrementKg.value, step, roundUp((currentLoad * pct) / 100, step));
    // El siguiente peso que existe con este material (§16.16): múltiplo del paso, por encima.
    const next = roundLoad(currentLoad + rawInc, implement, 'up', config);
    const inc = Math.round((next - currentLoad) * 100) / 100;
    const rationale = [
      implement
        ? `Completaste todas las series a ${p.repMax} reps con RIR ${p.targetRir} o más: subimos ${fmt(inc)} kg (${pct} % en tren ${lowerBody ? 'inferior' : 'superior'}, redondeado al siguiente peso disponible, de ${fmt(step)} en ${fmt(step)} kg), de ${fmt(currentLoad)} a ${fmt(next)} kg, y vuelves a ${p.repMin} reps.`
        : `Completaste todas las series a ${p.repMax} reps con RIR ${p.targetRir} o más: subimos ${fmt(inc)} kg (${pct} % en tren ${lowerBody ? 'inferior' : 'superior'}, mínimo ${pr.minIncrementKg.value} kg), de ${fmt(currentLoad)} a ${fmt(next)} kg, y vuelves a ${p.repMin} reps.`,
    ];
    const jumpPct = (inc / currentLoad) * 100;
    if (jumpPct > config.load.bigJumpPct.value + 1e-9) {
      rationale.push(
        `El siguiente peso disponible es un salto grande (+${Math.round(jumpPct)} %): con ${fmt(next)} kg empieza por la parte baja del rango (${p.repMin} reps) y es normal tardar más sesiones en volver a ${p.repMax}.`,
      );
    }
    return {
      ok: true,
      next: {
        ...base,
        loadKg: next,
        action: 'increase_load',
        rationale,
      },
    };
  }

  return {
    ok: true,
    next: {
      ...base,
      loadKg: currentLoad,
      action: 'increase_reps',
      rationale: [`Mantén ${currentLoad !== null ? `${fmt(currentLoad)} kg` : 'la carga'} e intenta sumar una repetición por serie hasta llegar a ${p.repMax}.`],
    },
  };
}

function deload(
  base: Omit<engineV2.NextPrescription, 'action' | 'rationale'>,
  p: engineV2.CurrentPrescription,
  config: ProgrammingConfig,
  why: string,
): engineV2.NextPrescription {
  const pr = config.progression;
  const sets = Math.max(1, Math.round(p.sets * (1 - pr.deloadVolumeReductionPct.value / 100)));
  const rir = Math.min(5, p.targetRir + pr.deloadExtraRir.value);
  return {
    ...base,
    sets,
    targetRir: rir,
    isDeload: true,
    action: 'deload',
    rationale: [
      `${why} Toca una semana de descarga (${pr.deloadDurationDays.value} días): ${sets} series en vez de ${p.sets} y RIR ${rir}, sin dejar de entrenar.`,
    ],
  };
}

/**
 * Siguiente sesión pendiente del microciclo (CUJ-5): si faltas, el plan sigue por la siguiente
 * sesión sin saltarse ninguna. `completedOrders` en orden cronológico.
 */
export function nextPendingSession(sessionCount: number, completedOrders: readonly number[]): number {
  if (sessionCount <= 0) return 0;
  if (completedOrders.length === 0) return 0;
  const last = completedOrders[completedOrders.length - 1];
  return (((last + 1) % sessionCount) + sessionCount) % sessionCount;
}
