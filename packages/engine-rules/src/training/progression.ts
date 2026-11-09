/**
 * Progresión sesión a sesión (PROGRAMACION.md §7, §16.9; CUJ-3 y CUJ-5):
 * doble progresión con autorregulación por RIR, descarga programada y reactiva,
 * y reajuste tras una pausa larga. Función pura: `today` llega como dato.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';
import { fmt } from './labels.js';
import { roundDown } from './prescription.js';

type Log = engineV2.ExerciseSessionLog;

export function daysBetween(fromIso: string, toIso: string): number {
  const a = Date.UTC(+fromIso.slice(0, 4), +fromIso.slice(5, 7) - 1, +fromIso.slice(8, 10));
  const b = Date.UTC(+toIso.slice(0, 4), +toIso.slice(5, 7) - 1, +toIso.slice(8, 10));
  return Math.round((b - a) / 86_400_000);
}

function workSets(log: Log): engineV2.LoggedSet[] {
  return log.sets.filter((s) => !s.isWarmup);
}

/** Índice de rendimiento de una sesión: mejor Epley con reps + RIR (sin tope, solo para comparar). */
function performance(log: Log, divisor: number): number {
  let best = 0;
  for (const s of workSets(log)) {
    const eff = s.reps + (s.rir ?? 0);
    const v = s.loadKg > 0 ? s.loadKg * (1 + eff / divisor) : eff;
    if (v > best) best = v;
  }
  return best;
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
  const step = config.e1rm.loadRoundingKg.value;
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
  const gap = daysBetween(last.date, today);
  if (gap >= pr.breakDays.value) {
    const reduced =
      weighted && currentLoad !== null ? roundDown(currentLoad * (1 - pr.breakLoadReductionPct.value / 100), step) : currentLoad;
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

  // 3. Descarga reactiva: el rendimiento (reps o RIR a igual carga) cae dos sesiones seguidas.
  const n = pr.stagnationSessions.value;
  if (history.length >= n + 1) {
    const perf = history.slice(-(n + 1)).map((h) => performance(h, config.e1rm.epleyDivisor.value));
    let drops = true;
    for (let i = 1; i < perf.length; i++) if (!(perf[i] < perf[i - 1] - 1e-9)) drops = false;
    if (drops) {
      return {
        ok: true,
        next: deload(base, p, config, `Tus repeticiones o tu RIR han caído ${n} sesiones seguidas.`),
      };
    }
  }

  // 4. Rendimiento por debajo del objetivo dos sesiones seguidas → bajar la carga.
  const prev = history.length >= 2 ? history[history.length - 2] : null;
  if (underperformed(last, p)) {
    if (prev && underperformed(prev, p) && weighted && currentLoad !== null) {
      const reduced = roundDown(currentLoad * (1 - pr.reactiveDecreasePct.value / 100), step);
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
    const lower = pr.lowerBodyPatterns.value.includes(p.movementPattern);
    const pct = lower ? pr.loadIncrementPctLower.value : pr.loadIncrementPctUpper.value;
    const inc = Math.max(pr.minIncrementKg.value, roundUp((currentLoad * pct) / 100, step));
    const next = currentLoad + inc;
    return {
      ok: true,
      next: {
        ...base,
        loadKg: next,
        action: 'increase_load',
        rationale: [
          `Completaste todas las series a ${p.repMax} reps con RIR ${p.targetRir} o más: subimos ${fmt(inc)} kg (${pct} % en tren ${lower ? 'inferior' : 'superior'}, mínimo ${pr.minIncrementKg.value} kg), de ${fmt(currentLoad)} a ${fmt(next)} kg, y vuelves a ${p.repMin} reps.`,
        ],
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
