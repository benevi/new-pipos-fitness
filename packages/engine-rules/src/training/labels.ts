/** Etiquetas en castellano para las explicaciones. */
import type { engineV2 } from '@pipos/contracts';

export const GOAL_ES: Record<engineV2.TrainingGoal, string> = {
  strength: 'fuerza',
  hypertrophy: 'hipertrofia',
  general_health: 'salud general',
  fat_loss: 'pérdida de grasa',
  muscular_endurance: 'resistencia muscular',
};

export const LEVEL_ES: Record<engineV2.TrainingLevel, string> = {
  beginner: 'principiante',
  intermediate: 'intermedio',
  advanced: 'avanzado',
};

export const GROUP_ES: Record<engineV2.VolumeGroup, string> = {
  chest: 'pecho',
  back: 'espalda',
  shoulders: 'hombros',
  biceps: 'bíceps',
  triceps: 'tríceps',
  quads: 'cuádriceps',
  hamstrings: 'isquiosurales',
  glutes: 'glúteos',
  calves: 'gemelos',
  core: 'core',
};

export const MUSCLE_ES: Record<engineV2.Muscle, string> = {
  chest: 'pecho',
  front_delts: 'deltoides anterior',
  side_delts: 'deltoides lateral',
  rear_delts: 'deltoides posterior',
  lats: 'dorsal ancho',
  upper_back: 'espalda alta',
  traps: 'trapecio',
  biceps: 'bíceps',
  triceps: 'tríceps',
  forearms: 'antebrazos',
  abs: 'abdominales',
  obliques: 'oblicuos',
  lower_back: 'zona lumbar',
  glutes: 'glúteos',
  quads: 'cuádriceps',
  hamstrings: 'isquiosurales',
  adductors: 'aductores',
  abductors: 'abductores',
  calves: 'gemelos',
};

export const PATTERN_ES: Record<engineV2.MovementPattern, string> = {
  squat: 'sentadilla',
  hinge: 'bisagra de cadera',
  lunge: 'zancada',
  horizontal_push: 'empuje horizontal',
  vertical_push: 'empuje vertical',
  horizontal_pull: 'tirón horizontal',
  vertical_pull: 'tirón vertical',
  elbow_flexion: 'flexión de codo',
  elbow_extension: 'extensión de codo',
  shoulder_isolation: 'aislamiento de hombro',
  knee_extension: 'extensión de rodilla',
  knee_flexion: 'flexión de rodilla',
  hip_isolation: 'aislamiento de cadera',
  calf_raise: 'elevación de talones',
  core_anti_extension: 'core antiextensión',
  core_anti_rotation: 'core antirrotación',
  core_flexion: 'flexión de tronco',
  carry: 'acarreo',
};

export const ZONE_ES: Record<engineV2.BodyZone, string> = {
  shoulder: 'hombro',
  elbow: 'codo',
  wrist: 'muñeca',
  lumbar: 'zona lumbar',
  hip: 'cadera',
  knee: 'rodilla',
  ankle: 'tobillo',
};

export const EQUIPMENT_ES: Record<engineV2.Equipment, string> = {
  bodyweight: 'peso corporal',
  barbell: 'barra',
  ez_bar: 'barra Z',
  trap_bar: 'barra hexagonal',
  dumbbell: 'mancuernas',
  kettlebell: 'kettlebell',
  weight_plate: 'discos',
  bench: 'banco',
  squat_rack: 'rack',
  cable: 'polea',
  machine: 'máquinas',
  smith_machine: 'máquina Smith',
  pull_up_bar: 'barra de dominadas',
  dip_station: 'paralelas',
  gymnastic_rings: 'anillas',
  suspension_trainer: 'TRX',
  resistance_band: 'banda elástica',
  medicine_ball: 'balón medicinal',
  plyo_box: 'cajón',
};

export const SESSION_ES: Record<engineV2.SessionKind, string> = {
  full_body: 'Cuerpo completo',
  upper: 'Torso',
  lower: 'Pierna',
  push: 'Empuje',
  pull: 'Tirón',
  legs: 'Pierna',
};

export function list(items: readonly string[]): string {
  if (items.length <= 1) return items.join('');
  return `${items.slice(0, -1).join(', ')} y ${items[items.length - 1]}`;
}

export function fmt(n: number): string {
  return Number.isInteger(n) ? String(n) : n.toFixed(1).replace('.', ',');
}
