import { describe, expect, it } from 'vitest';
import { engineV2 } from '@pipos/contracts';
import rawExercises from '../data/exercises.json';
import { CatalogValidationError, GUIDE_CONTENT_REVIEW, getExercise, loadCatalog, parseCatalog } from './index';

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

/** Frases de un texto: cortes tras «.», «!» o «?» seguidos de espacio o fin. */
function sentences(text: string): number {
  return text.split(/[.!?](?:\s|$)/).filter((s) => s.trim().length > 0).length;
}

describe('ficha del ejercicio: descripción y errores comunes (ADR-0014)', () => {
  it('cobertura completa: los 144 ejercicios tienen descripción y al menos un error común', () => {
    const list = loadCatalog();
    const withDescription = list.filter((e) => e.descriptionEs.trim().length > 0).length;
    const withMistakes = list.filter((e) => e.mistakesEs.length > 0).length;
    console.info(
      `Cobertura de la ficha: ${withDescription}/${list.length} con descripción, ${withMistakes}/${list.length} con errores comunes`,
    );
    expect(withDescription).toBe(list.length);
    expect(withMistakes).toBe(list.length);
  });

  it('cada ficha es propia: no hay descripciones repetidas entre ejercicios', () => {
    const descriptions = loadCatalog().map((e) => e.descriptionEs);
    expect(new Set(descriptions).size).toBe(descriptions.length);
  });

  it('el estado del contenido es «pendiente de revisión profesional» hasta el lanzamiento', () => {
    expect(GUIDE_CONTENT_REVIEW.status).toBe('pending_professional_review');
  });

  it('ningún texto supera los límites: 1-3 frases y ≤ 400 caracteres; 0-3 errores de ≤ 120', () => {
    for (const e of loadCatalog()) {
      {
        expect(e.descriptionEs.length, e.slug).toBeLessThanOrEqual(engineV2.EXERCISE_DESCRIPTION_MAX);
        expect(sentences(e.descriptionEs), e.slug).toBeGreaterThanOrEqual(1);
        expect(sentences(e.descriptionEs), e.slug).toBeLessThanOrEqual(3);
        expect(e.descriptionEs, e.slug).not.toMatch(/\n/);
      }
      for (const m of e.mistakesEs ?? []) {
        expect(m.length, e.slug).toBeLessThanOrEqual(engineV2.EXERCISE_MISTAKE_MAX);
      }
      expect(e.mistakesEs.length, e.slug).toBeLessThanOrEqual(3);
    }
  });

  it('sin promesas de efectos sin fuente', () => {
    const banned = /quema(r)? grasa|previene lesiones|evita lesiones|tonific|el mejor ejercicio|garantiza|adelgaza/i;
    for (const e of loadCatalog()) {
      const text = [e.descriptionEs, ...e.mistakesEs].join(' ');
      expect(text, e.slug).not.toMatch(banned);
    }
  });

  it('el esquema rechaza una descripción o errores fuera de límites', () => {
    const first = loadCatalog()[0];
    expect(() => parseCatalog([{ ...first, descriptionEs: 'x'.repeat(401) }])).toThrow(CatalogValidationError);
    expect(() => parseCatalog([{ ...first, mistakesEs: ['a', 'b', 'c', 'd'].map((c) => c.repeat(10)) }])).toThrow(
      CatalogValidationError,
    );
    expect(() => parseCatalog([{ ...first, mistakesEs: ['x'.repeat(121)] }])).toThrow(CatalogValidationError);
  });
});
