import { execFileSync } from 'child_process';
import { resolve } from 'path';

/**
 * Se ejecuta una vez antes de todas las suites e2e: valida que DATABASE_URL apunta a una
 * base de datos desechable y aplica las migraciones reales con `prisma migrate deploy`.
 */
export default function globalSetup(): void {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error(
      'DATABASE_URL is required for e2e tests (a throwaway Postgres; tables are TRUNCATED).',
    );
  }
  const dbName = new URL(url).pathname.replace(/^\//, '');
  if (!/(test|e2e)/i.test(dbName) && process.env.E2E_ALLOW_ANY_DATABASE !== 'true') {
    throw new Error(
      `Refusing to run e2e against database "${dbName}": its name must contain "test" or "e2e" ` +
        '(tables are truncated between tests). Set E2E_ALLOW_ANY_DATABASE=true to override.',
    );
  }

  const apiRoot = resolve(__dirname, '../../..');
  const prismaBin = resolve(apiRoot, 'node_modules/.bin/prisma');
  execFileSync(prismaBin, ['migrate', 'deploy'], {
    cwd: apiRoot,
    stdio: 'inherit',
    env: process.env,
  });
}
