/**
 * Cambios de ejercicio fijados por el usuario (idea 3 de docs/IDEAS_EL_PLAN.md; ADR-0013).
 *
 * El plan generado no cambia: el motor elige sus ejercicios como siempre y, después, decide qué
 * cambios fijados siguen siendo válidos para cada hueco. Un cambio solo se mantiene si el
 * ejercicio elegido por el usuario pasa los mismos filtros duros que cualquier otro (material,
 * limitaciones, vetados y nivel; §16.12) y comparte grupo de sustitución o patrón con el
 * original. Así ningún cambio fijado puede saltarse un invariante.
 */
import { engineV2 } from '@pipos/contracts';
import { PROGRAMMING, type ProgrammingConfig } from '../config/programming.js';
import { exclusionReason, type ExclusionReason } from './filter.js';
import type { CatalogExercise, Profile } from './model.js';

export type PinDropReason = ExclusionReason | 'unknown_exercise' | 'not_similar' | 'excluded_pattern' | 'not_in_plan';

/** ¿Se puede usar `to` en lugar de `from` para este perfil? null = sí; si no, el motivo. */
export function pinDropReason(
  from: CatalogExercise | undefined,
  to: CatalogExercise | undefined,
  profile: Pick<Profile, 'equipment' | 'limitations' | 'bannedExerciseIds' | 'level'>,
  config: ProgrammingConfig = PROGRAMMING,
): PinDropReason | null {
  if (!from || !to) return 'unknown_exercise';
  if (from.substitutionGroup !== to.substitutionGroup && from.movementPattern !== to.movementPattern) return 'not_similar';
  if (config.balance.autoGenerationExcludedPatterns.value.includes(to.movementPattern)) return 'excluded_pattern';
  return exclusionReason(to, profile);
}

const REASON_ES: Record<PinDropReason, string> = {
  equipment: 'ya no tienes el material que necesita',
  limitation: 'no es compatible con tus limitaciones',
  banned: 'lo has vetado',
  level: 'requiere más nivel',
  unknown_exercise: 'ya no está en el catálogo',
  not_similar: 'ya no es una alternativa del ejercicio original',
  excluded_pattern: 'no se puede prescribir por repeticiones',
  not_in_plan: 'el plan nuevo ya no incluye el ejercicio original',
};

export interface ResolvedPins {
  pinned: engineV2.PinnedSubstitution[];
  warnings: engineV2.EngineWarning[];
}

/**
 * Aplica los cambios fijados a las sesiones ya generadas: cada par `from → to` se aplica a todos
 * los huecos cuyo ejercicio es `from`. Los que dejan de ser válidos se descartan con un aviso.
 */
export function resolvePins(
  sessions: readonly engineV2.PlannedSession[],
  pins: readonly engineV2.PinnedSubstitutionInput[],
  catalog: readonly CatalogExercise[],
  profile: Profile,
  config: ProgrammingConfig = PROGRAMMING,
): ResolvedPins {
  const bySlug = new Map(catalog.map((e) => [e.slug, e]));
  const pinned: engineV2.PinnedSubstitution[] = [];
  const warnings: engineV2.EngineWarning[] = [];
  const seen = new Set<string>();
  for (const pin of pins) {
    if (seen.has(pin.from)) continue; // un solo cambio por ejercicio original
    seen.add(pin.from);
    const from = bySlug.get(pin.from);
    const to = bySlug.get(pin.to);
    let reason = pinDropReason(from, to, profile, config);
    const slots: { sessionOrder: number; exerciseOrder: number }[] = [];
    if (!reason) {
      for (const s of sessions) for (const e of s.exercises) if (e.exerciseId === pin.from) slots.push({ sessionOrder: s.order, exerciseOrder: e.order });
      if (slots.length === 0) reason = 'not_in_plan';
    }
    if (reason) {
      const fromName = from?.nameEs ?? pin.from;
      const toName = to?.nameEs ?? pin.to;
      warnings.push({
        code: 'PINNED_SUBSTITUTION_DROPPED',
        message: `Tu cambio fijado ${fromName} → ${toName} ya no se aplica: ${REASON_ES[reason]}.`,
        data: { from: pin.from, to: pin.to, reason },
        // Si el motivo es una limitación, el aviso se deriva de datos de salud (ADR-0011).
        ...(reason === 'limitation' ? { health: true } : {}),
      });
      continue;
    }
    for (const slot of slots) pinned.push({ ...slot, from: pin.from, to: pin.to });
  }
  pinned.sort((a, b) => a.sessionOrder - b.sessionOrder || a.exerciseOrder - b.exerciseOrder);
  return { pinned, warnings };
}
