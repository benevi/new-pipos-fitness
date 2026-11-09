import { engineV2 } from '@pipos/contracts';
import { describe, expect, it } from 'vitest';
import { PROGRAMMING } from '../config/programming.js';
import { CATALOG, FULL_GYM, HOME_DUMBBELLS, longHistory, profile } from '../test-support/fixtures.js';
import { assertPlanInvariants } from '../test-support/invariants.js';
import { generatePlan } from './generate.js';

function plan(p: engineV2.EngineProfileInput, catalog: readonly engineV2.CatalogExercise[] = CATALOG) {
  const r = generatePlan(p, catalog);
  if (!r.ok) throw new Error(JSON.stringify(r.error));
  assertPlanInvariants(p, r.plan);
  return r.plan;
}
const codes = (pl: engineV2.PlanDraft) => pl.warnings.map((w) => w.code);
const exercises = (pl: engineV2.PlanDraft) => pl.sessions.flatMap((s) => s.exercises);
const bySlug = new Map(CATALOG.map((e) => [e.slug, e]));

describe('casos límite fijos (PLAN §3)', () => {
  it('2 días, 30 min, solo peso corporal: plan válido y huecos avisados explícitamente', () => {
    const p = profile({ daysPerWeek: 2, minutesPerSession: 30, equipment: [], level: 'beginner', goal: 'general_health' });
    const pl = plan(p);
    expect(pl.split.type).toBe('full_body');
    expect(pl.sessions).toHaveLength(2);
    for (const e of exercises(pl)) expect(bySlug.get(e.exerciseId)?.equipment).toEqual(['bodyweight']);
    const uncovered = pl.warnings.filter((w) => w.code === 'PATTERN_UNCOVERED').map((w) => w.data?.pattern);
    expect(uncovered).toEqual(expect.arrayContaining(['horizontal_pull', 'vertical_pull']));
    // El aviso sugiere material concreto.
    const pull = pl.warnings.find((w) => w.data?.pattern === 'horizontal_pull');
    expect(pull?.message).toMatch(/banda elástica/);
    expect(codes(pl)).toContain('VOLUME_BELOW_FLOOR');
    for (const s of pl.sessions) expect(s.estimatedMinutes).toBeLessThanOrEqual(33);
  });

  it('6 días, 90 min, gimnasio completo, avanzado: PPL y todos los grupos ≥ suelo', () => {
    const pl = plan(profile({ daysPerWeek: 6, minutesPerSession: 90, level: 'advanced', goal: 'hypertrophy' }));
    expect(pl.split.type).toBe('push_pull_legs');
    expect(pl.sessions.map((s) => s.kind)).toEqual(['push', 'pull', 'legs', 'push', 'pull', 'legs']);
    for (const v of pl.weeklyVolume) {
      expect(v.effectiveSets, v.group).toBeGreaterThanOrEqual(v.min);
      expect(v.sessions, v.group).toBeGreaterThanOrEqual(2);
    }
    expect(codes(pl)).not.toContain('PATTERN_UNCOVERED');
  });

  it('lesión de hombro: ningún ejercicio «avoid» de hombro y se explica la precaución', () => {
    const pl = plan(profile({ limitations: ['shoulder'], daysPerWeek: 4 }));
    for (const e of exercises(pl)) {
      const tag = bySlug.get(e.exerciseId)?.riskTags.find((r) => r.zone === 'shoulder');
      expect(tag?.level, e.exerciseId).not.toBe('avoid');
      if (tag?.level === 'caution') expect(e.rationale.join(' ')).toMatch(/hombro/);
    }
    const slugs = exercises(pl).map((e) => e.exerciseId);
    for (const banned of ['press-tras-nuca', 'fondos-paralelas', 'remo-menton-barra', 'press-militar-barra']) {
      expect(slugs).not.toContain(banned);
    }
    expect(pl.rationale.join(' ')).toMatch(/hombro/);
    // El empuje vertical sigue cubierto con variantes de precaución.
    expect(exercises(pl).some((e) => e.movementPattern === 'vertical_push')).toBe(true);
  });

  it('lesión de rodilla: sin sissy squat y con explicación', () => {
    const pl = plan(profile({ limitations: ['knee'], level: 'advanced', daysPerWeek: 5 }));
    expect(exercises(pl).map((e) => e.exerciseId)).not.toContain('sissy-squat');
    expect(pl.split.type).toBe('hybrid_ul_ppl');
  });

  it('principiante sin historial: cargas estimadas, RIR ≥ 2 y 8-12 reps', () => {
    const pl = plan(profile({ level: 'beginner', daysPerWeek: 3, goal: 'strength' }));
    for (const e of exercises(pl)) {
      expect(e.targetRir).toBeGreaterThanOrEqual(2);
      expect([e.repMin, e.repMax]).toEqual([8, 12]);
      if (e.loadType === 'weighted') {
        expect(e.initialLoadKg).toBeNull();
        expect(e.initialLoadIsEstimate).toBe(true);
        expect(e.rationale.join(' ')).toMatch(/Estimación inicial/);
      }
    }
    expect(pl.sessions[0].exercises[0].rationale.join(' ')).toMatch(/principiante/);
  });

  it('avanzado con historial largo: carga desde e1RM y peso muerto marcado como estimación', () => {
    const pl = plan(profile({ level: 'advanced', goal: 'strength', daysPerWeek: 4, history: longHistory() }));
    const withLoad = exercises(pl).filter((e) => e.initialLoadKg !== null);
    expect(withLoad.length).toBeGreaterThan(0);
    const squat = exercises(pl).find((e) => e.exerciseId === 'sentadilla-trasera-barra');
    if (squat) {
      // e1RM última sesión: 111 kg × (1 + 7/30) ≈ 136,9; para 3+2 reps → ≈ 117 kg.
      expect(squat.initialLoadKg).toBeGreaterThan(100);
      expect(squat.initialLoadIsEstimate).toBe(false);
      expect(squat.warmupSets.length).toBeGreaterThan(0);
      expect(squat.warmupSets[0].loadKg).toBeLessThan(squat.initialLoadKg!);
    }
    const dl = exercises(pl).find((e) => e.exerciseId === 'peso-muerto-barra' && e.initialLoadKg !== null);
    if (dl) expect(dl.initialLoadIsEstimate).toBe(true);
  });

  it('material que no cubre un patrón: aviso explícito, nunca hueco silencioso', () => {
    const pl = plan(profile({ equipment: ['dumbbell'], daysPerWeek: 3 }));
    // Sin banco ni barra no hay tirón vertical.
    const w = pl.warnings.find((x) => x.code === 'PATTERN_UNCOVERED' && x.data?.pattern === 'vertical_pull');
    expect(w).toBeDefined();
    expect(w?.data?.suggestedEquipment).toEqual(expect.arrayContaining(['bench']));
  });

  it('todas las variantes de un patrón vetadas → aviso de patrón', () => {
    const banned = CATALOG.filter((e) => e.movementPattern === 'hinge').map((e) => e.slug);
    const pl = plan(profile({ bannedExerciseIds: banned, daysPerWeek: 4 }));
    expect(exercises(pl).every((e) => e.movementPattern !== 'hinge')).toBe(true);
    expect(pl.warnings.some((w) => w.code === 'PATTERN_UNCOVERED' && w.data?.pattern === 'hinge')).toBe(true);
  });

  it('limitación que excluye un patrón entero → el aviso cita la limitación', () => {
    const catalog = CATALOG.map((e) =>
      e.movementPattern === 'vertical_push' ? { ...e, riskTags: [{ zone: 'shoulder' as const, level: 'avoid' as const }] } : e,
    );
    const pl = plan(profile({ limitations: ['shoulder'] }), catalog);
    const w = pl.warnings.find((x) => x.code === 'PATTERN_UNCOVERED' && x.data?.pattern === 'vertical_push');
    expect(w?.data?.reason).toBe('limitation');
    expect(w?.message).toMatch(/limitaciones/);
  });
});

describe('errores tipados (sin valores por defecto)', () => {
  it.each([
    ['7 días', { daysPerWeek: 7 }],
    ['20 minutos', { minutesPerSession: 20 }],
    ['material desconocido', { equipment: ['sofa'] }],
    ['sin objetivo', { goal: undefined }],
  ])('perfil inválido (%s) → INVALID_PROFILE', (_n, patch) => {
    const r = generatePlan({ ...profile(), ...patch }, CATALOG);
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.error.code).toBe('INVALID_PROFILE');
      expect(r.error.issues.length).toBeGreaterThan(0);
    }
  });

  it('catálogo con slugs duplicados → INVALID_CATALOG', () => {
    const r = generatePlan(profile(), [CATALOG[0], CATALOG[0]]);
    expect(!r.ok && r.error.code).toBe('INVALID_CATALOG');
  });

  it('sin ejercicios elegibles → NO_EXERCISES', () => {
    const r = generatePlan(profile(), []);
    expect(!r.ok && r.error.code).toBe('NO_EXERCISES');
    const onlyCarries = CATALOG.filter((e) => e.movementPattern === 'carry');
    const r2 = generatePlan(profile(), onlyCarries);
    expect(!r2.ok && r2.error.code).toBe('NO_EXERCISES');
  });
});

describe('split, volumen y explicaciones', () => {
  it.each([
    [2, 'full_body'],
    [3, 'full_body'],
    [4, 'upper_lower'],
    [5, 'hybrid_ul_ppl'],
    [6, 'push_pull_legs'],
  ] as const)('%i días → %s, con días repartidos', (days, type) => {
    const pl = plan(profile({ daysPerWeek: days }));
    expect(pl.split.type).toBe(type);
    expect(pl.split.rationale[0]).toContain(`${days} días`);
    const idx = pl.sessions.map((s) => s.dayIndex);
    expect(new Set(idx).size).toBe(days);
  });

  it('músculo prioritario: volumen en la parte alta y ejercicio al principio de la sesión', () => {
    const base = plan(profile({ daysPerWeek: 4 }));
    const prio = plan(profile({ daysPerWeek: 4, priorityMuscles: ['side_delts'] }));
    const vol = (pl: engineV2.PlanDraft) => pl.weeklyVolume.find((v) => v.group === 'shoulders')!;
    expect(vol(prio).isPriority).toBe(true);
    expect(vol(prio).effectiveSets).toBeGreaterThan(vol(base).effectiveSets);
    expect(vol(prio).effectiveSets).toBeGreaterThanOrEqual((vol(prio).min + vol(prio).max) / 2);
    const upper = prio.sessions.find((s) => s.kind === 'upper')!;
    const first = bySlug.get(upper.exercises[0].exerciseId)!;
    expect(first.muscles.some((m) => m.muscle === 'side_delts' && m.role === 'primary')).toBe(true);
    expect(upper.exercises[0].rationale.join(' ')).toMatch(/prioridad/);
  });

  it('avanzado con músculo prioritario puede llegar a 24 series', () => {
    const pl = plan(profile({ level: 'advanced', daysPerWeek: 6, minutesPerSession: 90, priorityMuscles: ['glutes'] }));
    const g = pl.weeklyVolume.find((v) => v.group === 'glutes')!;
    expect(g.max).toBe(PROGRAMMING.volume.weeklyMaxPriorityAdvanced.value);
  });

  it('músculo prioritario sin ejercicios disponibles → aviso', () => {
    const pl = plan(profile({ equipment: [], priorityMuscles: ['biceps'], level: 'beginner', daysPerWeek: 3 }));
    expect(codes(pl)).toContain('PRIORITY_UNCOVERED');
  });

  it('favoritos: se incluyen si cumplen las restricciones y se avisa si no', () => {
    const pl = plan(
      profile({ favouriteExerciseIds: ['hip-thrust-barra', 'press-tras-nuca'], limitations: ['shoulder'], daysPerWeek: 4 }),
    );
    const ht = exercises(pl).find((e) => e.exerciseId === 'hip-thrust-barra');
    expect(ht?.rationale[0]).toMatch(/favorito/);
    const w = pl.warnings.find((x) => x.code === 'FAVOURITE_EXCLUDED');
    expect(w?.data?.exerciseId).toBe('press-tras-nuca');
    expect(w?.message).toMatch(/riesgo/);
  });

  it('vetados nunca aparecen, aunque sean favoritos', () => {
    const pl = plan(profile({ bannedExerciseIds: ['press-banca-barra'], favouriteExerciseIds: ['press-banca-barra'] }));
    expect(exercises(pl).map((e) => e.exerciseId)).not.toContain('press-banca-barra');
    expect(pl.warnings.find((w) => w.code === 'FAVOURITE_EXCLUDED')?.message).toMatch(/vetados/);
  });

  it('principiante con 6 días: aviso informativo de días por encima de la guía', () => {
    const pl = plan(profile({ level: 'beginner', daysPerWeek: 6 }));
    expect(codes(pl)).toContain('DAYS_ABOVE_LEVEL_GUIDE');
    expect(pl.split.rationale.join(' ')).toMatch(/ACSM 2009/);
  });

  it('fuerza: el primer multiarticular va a 3-6 reps con 3 min y 3 series de aproximación', () => {
    const pl = plan(profile({ goal: 'strength', level: 'intermediate', daysPerWeek: 3 }));
    const first = pl.sessions[0].exercises[0];
    expect([first.repMin, first.repMax]).toEqual([3, 6]);
    expect(first.restSeconds).toBe(180);
    expect(first.warmupSets).toHaveLength(3);
    expect(first.sets).toBeLessThanOrEqual(3);
  });

  it('resistencia muscular: 15+ reps y 60 s de descanso', () => {
    const pl = plan(profile({ goal: 'muscular_endurance', daysPerWeek: 3 }));
    for (const e of exercises(pl)) {
      expect(e.repMin).toBeGreaterThanOrEqual(15);
      expect(e.restSeconds).toBe(60);
    }
  });

  it('salud general: como mucho 3 series por ejercicio', () => {
    const pl = plan(profile({ goal: 'general_health', daysPerWeek: 2, minutesPerSession: 90, level: 'intermediate' }));
    for (const e of exercises(pl)) expect(e.sets).toBeLessThanOrEqual(3);
  });

  it('explicaciones en castellano con datos del usuario', () => {
    const pl = plan(profile({ daysPerWeek: 4, minutesPerSession: 60, equipment: HOME_DUMBBELLS }));
    expect(pl.rationale[0]).toContain('4 días de 60 min');
    expect(pl.rationale[0]).toContain('mancuernas');
    for (const s of pl.sessions) {
      expect(s.rationale[0]).toMatch(/min estimados de tus 60/);
      for (const e of s.exercises) expect(e.rationale.length).toBeGreaterThan(1);
    }
  });

  it('el volumen informado coincide con la suma de series × fracción', () => {
    const pl = plan(profile({ equipment: FULL_GYM }));
    const chest = exercises(pl).reduce((acc, e) => {
      const f = bySlug.get(e.exerciseId)!.muscles.find((m) => m.muscle === 'chest')?.fraction ?? 0;
      return acc + e.sets * f;
    }, 0);
    expect(pl.weeklyVolume.find((v) => v.group === 'chest')!.effectiveSets).toBeCloseTo(chest, 1);
    expect(pl.muscleVolume.find((m) => m.muscle === 'chest')!.effectiveSets).toBeCloseTo(chest, 1);
  });

  it('versión del motor y mesociclo', () => {
    const pl = plan(profile());
    expect(pl.engineVersion).toBe('2.0.0');
    expect(pl.mesocycleWeeks).toBe(6);
    expect(pl.score.total).toBeGreaterThan(0.8);
  });
});
