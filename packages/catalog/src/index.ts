/**
 * Catálogo de ejercicios versionado (seed revisado por PR; ADR-0005).
 * `data/exercises.json` es la fuente de verdad; aquí solo se valida con Zod y se expone.
 */
import { engineV2 } from '@pipos/contracts';
import rawExercises from '../data/exercises.json';

export const CATALOG_VERSION = '1.0.0';

export type CatalogExercise = engineV2.CatalogExercise;

export class CatalogValidationError extends Error {
  constructor(public readonly issues: { path: string; message: string }[]) {
    super(`Catálogo inválido: ${issues.map((i) => `${i.path}: ${i.message}`).join('; ')}`);
    this.name = 'CatalogValidationError';
  }
}

/** Valida una lista arbitraria contra el esquema del catálogo. */
export function parseCatalog(data: unknown): CatalogExercise[] {
  const parsed = engineV2.CatalogSchema.safeParse(data);
  if (!parsed.success) {
    throw new CatalogValidationError(
      parsed.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    );
  }
  return [...parsed.data].sort((a, b) => (a.slug < b.slug ? -1 : a.slug > b.slug ? 1 : 0));
}

let cache: readonly CatalogExercise[] | null = null;

/** Devuelve el catálogo validado, ordenado por slug. Lanza si el JSON no cumple el esquema. */
export function loadCatalog(): readonly CatalogExercise[] {
  if (!cache) cache = Object.freeze(parseCatalog(rawExercises));
  return cache;
}

export function getExercise(slug: string): CatalogExercise | undefined {
  return loadCatalog().find((e) => e.slug === slug);
}
