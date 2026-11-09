/**
 * Catálogo de ejercicios versionado (seed revisado por PR; ADR-0005).
 * `data/exercises.json` es la fuente de verdad; aquí solo se valida con Zod y se expone.
 */
import { existsSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { engineV2 } from '@pipos/contracts';
import rawExercises from '../data/exercises.json';

export const CATALOG_VERSION = '1.1.0';

/**
 * Estado del contenido de la ficha del ejercicio (`descriptionEs`, `mistakesEs`; ADR-0014).
 * Lo redactó el equipo de desarrollo ejercicio a ejercicio y entró por PR; debe revisarlo un
 * entrenador titulado antes del lanzamiento público (SPEC_V1). Al revisarlo, cambiar a
 * 'professionally_reviewed' e indicar la fecha.
 */
export const GUIDE_CONTENT_REVIEW = {
  status: 'pending_professional_review' as 'pending_professional_review' | 'professionally_reviewed',
  reviewedOn: null as string | null,
} as const;

export type CatalogExercise = engineV2.CatalogExercise;
export type CatalogMedia = engineV2.CatalogMedia;
export type CatalogYoutubeMedia = engineV2.CatalogYoutubeMedia;

/** Raíz del paquete (la que tiene `package.json`), tanto desde `src/` como desde `dist/src/`. */
function packageRoot(): string {
  let dir = __dirname;
  while (!existsSync(join(dir, 'package.json')) && dirname(dir) !== dir) dir = dirname(dir);
  return dir;
}

/**
 * Carpeta de las imágenes propias del catálogo (ADR-0014, Fase 4). Cada medio `image` del JSON
 * nombra un fichero de aquí; la validación comprueba que existe y que no pesa demasiado.
 */
export const MEDIA_DIR = join(packageRoot(), 'media');

/** Tamaño máximo de una imagen del catálogo (PLAN_GUIA_EJERCICIOS §7: límite por imagen). */
export const MEDIA_IMAGE_MAX_BYTES = 300 * 1024;

export interface ParseCatalogOptions {
  /** Carpeta donde buscar las imágenes; por defecto `MEDIA_DIR` (los tests usan una temporal). */
  mediaDir?: string;
}

export class CatalogValidationError extends Error {
  constructor(public readonly issues: { path: string; message: string }[]) {
    super(`Catálogo inválido: ${issues.map((i) => `${i.path}: ${i.message}`).join('; ')}`);
    this.name = 'CatalogValidationError';
  }
}

/** Problemas de las imágenes en disco: fichero inexistente, que no es un fichero o demasiado grande. */
function mediaFileIssues(list: readonly CatalogExercise[], mediaDir: string): { path: string; message: string }[] {
  const issues: { path: string; message: string }[] = [];
  list.forEach((ex, i) =>
    ex.media.forEach((m, j) => {
      if (m.kind !== 'image') return;
      const path = `${i}.media.${j}.file`;
      const file = join(mediaDir, m.file);
      if (!existsSync(file) || !statSync(file).isFile()) {
        issues.push({ path, message: `la imagen ${m.file} no existe en el paquete (${ex.slug})` });
      } else if (statSync(file).size > MEDIA_IMAGE_MAX_BYTES) {
        issues.push({ path, message: `la imagen ${m.file} supera ${MEDIA_IMAGE_MAX_BYTES} bytes (${ex.slug})` });
      }
    }),
  );
  return issues;
}

/**
 * Valida una lista arbitraria contra el esquema del catálogo y comprueba que las imágenes que
 * nombra existen en el paquete (ADR-0014, Fase 4).
 */
export function parseCatalog(data: unknown, options: ParseCatalogOptions = {}): CatalogExercise[] {
  const parsed = engineV2.CatalogSchema.safeParse(data);
  if (!parsed.success) {
    throw new CatalogValidationError(
      parsed.error.issues.map((i) => ({ path: i.path.join('.'), message: i.message })),
    );
  }
  const fileIssues = mediaFileIssues(parsed.data, options.mediaDir ?? MEDIA_DIR);
  if (fileIssues.length > 0) throw new CatalogValidationError(fileIssues);
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

/** Vídeos de YouTube del catálogo, el principal de cada ejercicio primero (para `media:check`). */
export function catalogVideos(
  catalog: readonly CatalogExercise[] = loadCatalog(),
): { slug: string; video: CatalogYoutubeMedia }[] {
  return catalog.flatMap((ex) =>
    [...ex.media]
      .sort((a, b) => Number(b.isPrimary) - Number(a.isPrimary))
      .filter((m): m is CatalogYoutubeMedia => m.kind === 'youtube')
      .map((video) => ({ slug: ex.slug, video })),
  );
}

export * from './media-check.js';
