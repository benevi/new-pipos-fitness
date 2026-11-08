import { describe, expect, it } from 'vitest';
import { engineV2 } from '@pipos/contracts';
import rawExercises from '../data/exercises.json';
import { CatalogValidationError, getExercise, loadCatalog, parseCatalog } from './index';

type Equipment = engineV2.Equipment;
type MovementPattern = engineV2.MovementPattern;

/** Configuraciones de material habituales para el test de huecos. */
const SETUPS: Record<string, readonly Equipment[]> = {
  solo_peso_corporal: ['bodyweight'],
  mancuernas_y_banco: ['bodyweight', 'dumbbell', 'bench'],
  gimnasio_completo: engineV2.EQUIPMENT,
};

/**
 * Huecos aceptados (patrón sin ninguna variante para ese material), con su motivo.
 * El motor emite el aviso PATTERN_UNCOVERED cuando un patrón requerido cae aquí.
 */
const ACCEPTED_GAPS: Record<string, Partial<Record<MovementPattern, string>>> = {
  solo_peso_corporal: {
    horizontal_pull:
      'Sin barra, anillas, TRX ni banda no hay tirón seguro con carga útil; se avisa y se recomienda una banda',
    vertical_pull: 'Requiere barra de dominadas, polea, banda anclada o anillas',
    elbow_flexion: 'Sin carga externa no hay curl útil; el bíceps trabaja como secundario en tirones',
    elbow_extension:
      'El tríceps trabaja en flexiones (las flexiones diamante son empuje horizontal con tríceps primario)',
    carry: 'Un acarreo necesita peso que transportar',
  },
  // knee_extension solo se cubre con la sissy squat (avanzado, rodilla «avoid»): no es un hueco
  // formal, pero el motor rara vez la elige; el cuádriceps se cubre con goblet y zancadas.
  mancuernas_y_banco: {},
  gimnasio_completo: {},
};

function available(setup: readonly Equipment[]) {
  const set = new Set<Equipment>([...setup, 'bodyweight']);
  return loadCatalog().filter((e) => e.equipment.every((eq) => set.has(eq)));
}

describe('catálogo de ejercicios', () => {
  it('cumple el esquema Zod y tiene entre 80 y 150 ejercicios', () => {
    const list = loadCatalog();
    expect(list.length).toBeGreaterThanOrEqual(80);
    expect(list.length).toBeLessThanOrEqual(150);
    expect(engineV2.CatalogSchema.safeParse(rawExercises).success).toBe(true);
  });

  it('los slugs son únicos y la lista está ordenada por slug', () => {
    const slugs = loadCatalog().map((e) => e.slug);
    expect(new Set(slugs).size).toBe(slugs.length);
    expect([...slugs].sort()).toEqual(slugs);
  });

  it('cada grupo de sustitución tiene al menos 2 ejercicios', () => {
    const counts = new Map<string, number>();
    for (const e of loadCatalog()) counts.set(e.substitutionGroup, (counts.get(e.substitutionGroup) ?? 0) + 1);
    const lonely = [...counts].filter(([, n]) => n < 2).map(([g]) => g);
    expect(lonely).toEqual([]);
  });

  it('un grupo de sustitución no mezcla patrones de movimiento', () => {
    const byGroup = new Map<string, Set<string>>();
    for (const e of loadCatalog()) {
      const s = byGroup.get(e.substitutionGroup) ?? new Set<string>();
      s.add(e.movementPattern);
      byGroup.set(e.substitutionGroup, s);
    }
    const mixed = [...byGroup].filter(([, s]) => s.size > 1).map(([g]) => g);
    expect(mixed).toEqual([]);
  });

  for (const [setup, equipment] of Object.entries(SETUPS)) {
    it(`cobertura de patrones con «${setup}»: cada patrón tiene variante o es un hueco aceptado`, () => {
      const list = available(equipment);
      const missing = engineV2.MOVEMENT_PATTERNS.filter(
        (p) => !list.some((e) => e.movementPattern === p),
      );
      const accepted = Object.keys(ACCEPTED_GAPS[setup] ?? {}).sort();
      // Igualdad exacta: un hueco nuevo falla y un hueco aceptado que ya no existe también.
      expect([...missing].sort()).toEqual(accepted);
      for (const reason of Object.values(ACCEPTED_GAPS[setup] ?? {})) expect(reason.length).toBeGreaterThan(20);
    });
  }

  it('todos los patrones del enum están representados en el catálogo', () => {
    const patterns = new Set(loadCatalog().map((e) => e.movementPattern));
    expect([...patterns].sort()).toEqual([...engineV2.MOVEMENT_PATTERNS].sort());
  });

  it('marca de forma conservadora los ejercicios de riesgo conocido', () => {
    const risk = (slug: string, zone: engineV2.BodyZone) =>
      getExercise(slug)?.riskTags.find((r) => r.zone === zone)?.level;
    expect(risk('press-tras-nuca', 'shoulder')).toBe('avoid');
    expect(risk('remo-menton-barra', 'shoulder')).toBe('avoid');
    expect(risk('fondos-paralelas', 'shoulder')).toBe('avoid');
    expect(risk('fondos-banco', 'shoulder')).toBe('avoid');
    expect(risk('buenos-dias-barra', 'lumbar')).toBe('avoid');
    expect(risk('sissy-squat', 'knee')).toBe('avoid');
    expect(risk('peso-muerto-barra', 'lumbar')).toBe('caution');
    expect(risk('sentadilla-trasera-barra', 'knee')).toBe('caution');
  });

  it('isCompound es coherente con el número de músculos primarios en los multiarticulares grandes', () => {
    for (const slug of ['sentadilla-trasera-barra', 'peso-muerto-barra', 'press-banca-barra', 'dominadas-pronas']) {
      expect(getExercise(slug)?.isCompound).toBe(true);
    }
    for (const slug of ['curl-biceps-mancuernas', 'elevaciones-laterales-mancuernas', 'extension-cuadriceps-maquina']) {
      expect(getExercise(slug)?.isCompound).toBe(false);
    }
  });

  it('los ejercicios sin material declaran solo «bodyweight» y ninguno tiene la lista vacía', () => {
    for (const e of loadCatalog()) {
      expect(e.equipment.length).toBeGreaterThan(0);
      if (e.equipment.includes('bodyweight')) expect(e.equipment).toEqual(['bodyweight']);
    }
  });

  it('cada ejercicio tiene nombre en español y en inglés y 2-3 indicaciones', () => {
    for (const e of loadCatalog()) {
      expect(e.nameEs).not.toEqual(e.nameEn);
      expect(e.cuesEs.length).toBeGreaterThanOrEqual(2);
      expect(e.cuesEs.length).toBeLessThanOrEqual(3);
      expect(e.media).toBeNull();
    }
  });

  it('las fracciones solo usan 1 (directa) y 0,5 (indirecta)', () => {
    for (const e of loadCatalog()) for (const m of e.muscles) expect([1, 0.5]).toContain(m.fraction);
  });

  it('parseCatalog rechaza datos inválidos con un error tipado', () => {
    const first = loadCatalog()[0];
    expect(() => parseCatalog([first, first])).toThrow(CatalogValidationError);
    expect(() => parseCatalog([{ ...first, equipment: [] }])).toThrow(/Catálogo inválido/);
    expect(() => parseCatalog([{ ...first, equipment: ['bodyweight', 'dumbbell'] }])).toThrow(
      CatalogValidationError,
    );
  });

  it('getExercise devuelve undefined para un slug desconocido', () => {
    expect(getExercise('no-existe')).toBeUndefined();
    expect(loadCatalog()).toBe(loadCatalog());
  });
});
