/**
 * Selección de split (PROGRAMACION.md §2) y plantillas de sesión (§16.13).
 * 2-3 días: cuerpo completo; 4: torso/pierna; 5: híbrido torso/pierna + PPL; 6: PPL ×2.
 * Todas las plantillas garantizan que cada grupo aparece en al menos 2 sesiones por semana.
 */
import type { engineV2 } from '@pipos/contracts';
import type { ProgrammingConfig } from '../config/programming.js';
import { GOAL_ES, LEVEL_ES } from './labels.js';
import type { ExerciseRole, MovementPattern, Muscle, Profile, SessionKind, VolumeGroup } from './model.js';

export interface SlotSpec {
  readonly patterns: readonly MovementPattern[];
  readonly role: ExerciseRole;
  /** Músculo preferido para el hueco (p. ej. deltoides posterior en el día de tirón). */
  readonly prefer?: Muscle;
}

export interface SessionTemplate {
  readonly kind: SessionKind;
  readonly name: string;
  readonly groups: readonly VolumeGroup[];
  readonly slots: readonly SlotSpec[];
}

const ALL_GROUPS: readonly VolumeGroup[] = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'quads',
  'hamstrings',
  'glutes',
  'calves',
  'core',
];
const UPPER: readonly VolumeGroup[] = ['chest', 'back', 'shoulders', 'biceps', 'triceps'];
const LOWER: readonly VolumeGroup[] = ['quads', 'hamstrings', 'glutes', 'calves', 'core'];
const PUSH: readonly VolumeGroup[] = ['chest', 'shoulders', 'triceps'];
const PULL: readonly VolumeGroup[] = ['back', 'biceps', 'shoulders'];

const s = (patterns: MovementPattern[], role: ExerciseRole, prefer?: Muscle): SlotSpec =>
  prefer ? { patterns, role, prefer } : { patterns, role };

const CORE_A: MovementPattern[] = ['core_anti_extension', 'core_flexion', 'core_anti_rotation'];
const CORE_B: MovementPattern[] = ['core_anti_rotation', 'core_anti_extension', 'core_flexion'];
const CORE_C: MovementPattern[] = ['core_flexion', 'core_anti_extension', 'core_anti_rotation'];

const FULL_BODY: readonly SessionTemplate[] = [
  {
    kind: 'full_body',
    name: 'Cuerpo completo A',
    groups: ALL_GROUPS,
    slots: [
      s(['squat', 'lunge'], 'main'),
      s(['horizontal_push'], 'main'),
      s(['horizontal_pull', 'vertical_pull'], 'main'),
      s(['hinge', 'hip_isolation'], 'secondary'),
      s(CORE_A, 'core'),
    ],
  },
  {
    kind: 'full_body',
    name: 'Cuerpo completo B',
    groups: ALL_GROUPS,
    slots: [
      s(['hinge', 'squat'], 'main'),
      s(['vertical_push', 'horizontal_push'], 'main'),
      s(['vertical_pull', 'horizontal_pull'], 'main'),
      s(['lunge', 'squat'], 'secondary'),
      s(CORE_B, 'core'),
    ],
  },
  {
    kind: 'full_body',
    name: 'Cuerpo completo C',
    groups: ALL_GROUPS,
    slots: [
      s(['squat', 'lunge'], 'main'),
      s(['horizontal_push', 'vertical_push'], 'main'),
      s(['horizontal_pull', 'vertical_pull'], 'main'),
      s(['hip_isolation', 'hinge'], 'secondary'),
      s(CORE_C, 'core'),
    ],
  },
];

const UPPER_A: SessionTemplate = {
  kind: 'upper',
  name: 'Torso A',
  groups: UPPER,
  slots: [
    s(['horizontal_push'], 'main'),
    s(['horizontal_pull', 'vertical_pull'], 'main'),
    s(['vertical_push'], 'secondary'),
    s(['vertical_pull', 'horizontal_pull'], 'secondary'),
  ],
};
const UPPER_B: SessionTemplate = {
  kind: 'upper',
  name: 'Torso B',
  groups: UPPER,
  slots: [
    s(['vertical_push', 'horizontal_push'], 'main'),
    s(['vertical_pull', 'horizontal_pull'], 'main'),
    s(['horizontal_push'], 'secondary'),
    s(['horizontal_pull'], 'secondary'),
  ],
};
const lowerA = (kind: SessionKind, name: string): SessionTemplate => ({
  kind,
  name,
  groups: LOWER,
  slots: [
    s(['squat'], 'main'),
    s(['hinge'], 'secondary'),
    s(['lunge'], 'secondary'),
    s(['knee_flexion'], 'accessory'),
    s(['calf_raise'], 'accessory'),
    s(CORE_A, 'core'),
  ],
});
const lowerB = (kind: SessionKind, name: string): SessionTemplate => ({
  kind,
  name,
  groups: LOWER,
  slots: [
    s(['hinge'], 'main'),
    s(['squat', 'lunge'], 'secondary'),
    s(['hip_isolation'], 'accessory'),
    s(['knee_extension', 'knee_flexion'], 'accessory'),
    s(['calf_raise'], 'accessory'),
    s(CORE_B, 'core'),
  ],
});
const PUSH_A: SessionTemplate = {
  kind: 'push',
  name: 'Empuje A',
  groups: PUSH,
  slots: [
    s(['horizontal_push'], 'main'),
    s(['vertical_push'], 'secondary'),
    s(['horizontal_push'], 'accessory'),
    s(['shoulder_isolation'], 'accessory', 'side_delts'),
    s(['elbow_extension'], 'accessory'),
  ],
};
const PUSH_B: SessionTemplate = {
  kind: 'push',
  name: 'Empuje B',
  groups: PUSH,
  slots: [
    s(['vertical_push', 'horizontal_push'], 'main'),
    s(['horizontal_push'], 'secondary'),
    s(['shoulder_isolation'], 'accessory', 'side_delts'),
    s(['elbow_extension'], 'accessory'),
  ],
};
const PULL_A: SessionTemplate = {
  kind: 'pull',
  name: 'Tirón A',
  groups: PULL,
  slots: [
    s(['vertical_pull', 'horizontal_pull'], 'main'),
    s(['horizontal_pull'], 'secondary'),
    s(['shoulder_isolation'], 'accessory', 'rear_delts'),
    s(['elbow_flexion'], 'accessory'),
  ],
};
const PULL_B: SessionTemplate = {
  kind: 'pull',
  name: 'Tirón B',
  groups: PULL,
  slots: [
    s(['horizontal_pull', 'vertical_pull'], 'main'),
    s(['vertical_pull'], 'secondary'),
    s(['shoulder_isolation'], 'accessory', 'rear_delts'),
    s(['elbow_flexion'], 'accessory'),
  ],
};

/** Días de la semana (0 = lunes) repartidos para dejar descanso entre sesiones (§16.13). */
const DAY_INDEXES: Record<number, readonly number[]> = {
  2: [0, 3],
  3: [0, 2, 4],
  4: [0, 1, 3, 4],
  5: [0, 1, 2, 4, 5],
  6: [0, 1, 2, 3, 4, 5],
};

export interface SplitChoice {
  type: engineV2.SplitType;
  templates: SessionTemplate[];
  dayIndexes: readonly number[];
  rationale: string[];
}

export function chooseSplit(profile: Profile, config: ProgrammingConfig): SplitChoice {
  const d = profile.daysPerWeek;
  const f = config.frequency;
  const rationale: string[] = [];
  let type: engineV2.SplitType;
  let templates: SessionTemplate[];
  if (d <= 3) {
    type = f.split.twoToThreeDays.value;
    templates = FULL_BODY.slice(0, d);
    rationale.push(
      `Entrenas ${d} días por semana: con cuerpo completo cada grupo muscular se trabaja ${d} veces por semana, por encima del mínimo de ${f.minPerGroup.value} que recomiendan la OMS (2020) y el ACSM (2026).`,
    );
  } else if (d === 4) {
    type = f.split.fourDays.value;
    templates = [UPPER_A, lowerA('lower', 'Pierna A'), UPPER_B, lowerB('lower', 'Pierna B')];
    rationale.push(
      'Entrenas 4 días por semana: un torso/pierna repetido dos veces trabaja cada grupo 2 veces por semana y reparte el volumen para no pasar de ~10 series por músculo y sesión.',
    );
  } else if (d === 5) {
    type = f.split.fiveDays.value;
    templates = [UPPER_A, lowerA('lower', 'Pierna A'), PUSH_A, PULL_A, lowerB('legs', 'Pierna B')];
    rationale.push(
      'Entrenas 5 días por semana: un híbrido torso/pierna + empuje/tirón/pierna permite trabajar cada grupo al menos 2 veces por semana con sesiones más cortas por grupo.',
    );
  } else {
    type = f.split.sixDays.value;
    templates = [PUSH_A, PULL_A, lowerA('legs', 'Pierna A'), PUSH_B, PULL_B, lowerB('legs', 'Pierna B')];
    rationale.push(
      'Entrenas 6 días por semana: empuje/tirón/pierna dos veces trabaja cada grupo 2 veces por semana y reparte mucho volumen en sesiones manejables.',
    );
  }
  rationale.push(
    'La elección del split por número de días es una convención; lo que respalda la evidencia es entrenar cada músculo al menos 2 veces por semana y repartir el volumen (Schoenfeld 2016; Pelland 2026).',
  );
  const [gMin, gMax] = f.daysGuide[profile.level].value;
  if (d > gMax) {
    rationale.push(
      `Como ${LEVEL_ES[profile.level]}, la guía orientativa es ${gMin}-${gMax} días (ACSM 2009); con ${d} días el volumen por sesión es menor y el plan te deja más margen de recuperación.`,
    );
  }
  rationale.push(`Objetivo: ${GOAL_ES[profile.goal]}.`);
  // Sin texto en `rationale`: la limitación es un dato de salud (va en healthNotes).
  if (profile.limitations.includes('shoulder')) templates = limitVerticalPush(templates);
  return { type, templates, dayIndexes: DAY_INDEXES[d] ?? [], rationale };
}

/**
 * Con limitación de hombro, como mucho UN hueco semanal de empuje vertical (press por encima de
 * la cabeza, el de más riesgo para el hombro): los siguientes huecos de solo empuje vertical pasan
 * a deltoides lateral (aislamiento, carga baja) y, si admiten empuje horizontal, este va primero.
 */
export function limitVerticalPush(templates: readonly SessionTemplate[]): SessionTemplate[] {
  let seen = false;
  return templates.map((t) => ({
    ...t,
    slots: t.slots.map((slot) => {
      if (!slot.patterns.includes('vertical_push')) return slot;
      if (!seen && slot.patterns[0] === 'vertical_push') {
        seen = true;
        return slot;
      }
      const rest = slot.patterns.filter((p) => p !== 'vertical_push');
      if (rest.length === 0) return s(['shoulder_isolation'], 'accessory', 'side_delts');
      return { ...slot, patterns: [...rest, 'vertical_push'] };
    }),
  }));
}

/** ¿Cuántas sesiones del split incluyen cada grupo? */
export function sessionsPerGroup(templates: readonly SessionTemplate[]): Map<VolumeGroup, number> {
  const out = new Map<VolumeGroup, number>();
  for (const t of templates) for (const g of t.groups) out.set(g, (out.get(g) ?? 0) + 1);
  return out;
}
