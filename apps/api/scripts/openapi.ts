/**
 * Genera apps/api/openapi.json desde los contratos Zod de los endpoints.
 *   pnpm --filter @pipos/api openapi:generate   → escribe el fichero
 *   pnpm --filter @pipos/api openapi:check      → falla si no está al día (CI)
 */
import 'reflect-metadata';
import { readFileSync, writeFileSync } from 'fs';
import { resolve } from 'path';
import { FEATURE_MODULES } from '../src/app.module';
import { API_VERSION } from '../src/app.setup';
import { buildOpenApiDocument } from '../src/openapi/openapi';

const target = resolve(__dirname, '../openapi.json');
const content = `${JSON.stringify(buildOpenApiDocument(FEATURE_MODULES, { version: API_VERSION }), null, 2)}\n`;
const mode = process.argv[2] ?? 'write';

if (mode === 'check') {
  let current = '';
  try {
    current = readFileSync(target, 'utf8');
  } catch {
    // no existe todavía
  }
  if (current !== content) {
    console.error('openapi.json is out of date: run `pnpm --filter @pipos/api openapi:generate` and commit it.');
    process.exit(1);
  }
  console.log('openapi.json is up to date');
} else {
  writeFileSync(target, content);
  console.log(`wrote ${target}`);
}
