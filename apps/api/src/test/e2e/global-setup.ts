import { execFileSync } from 'child_process';
import { resolve } from 'path';
import { PrismaClient } from '@prisma/client';
import { seedCatalog } from '../../catalog-seed/seed-catalog';

/**
 * Se ejecuta una vez antes de todas las suites e2e: valida que DATABASE_URL apunta a una
 * base de datos desechable, aplica las migraciones reales (`prisma migrate deploy`) y
 * siembra el catálogo real de @pipos/catalog (las suites no lo vacían).
 */
export default async function globalSetup(): Promise<void> {
  const url = process.env.DATABASE_URL;
  if (!url) {
    throw new Error('DATABASE_URL is required for e2e tests (a throwaway Postgres; tables are TRUNCATED).');
  }
  const dbName = new URL(url).pathname.replace(/^\//, '');
  if (!/(test|e2e)/i.test(dbName) && process.env.E2E_ALLOW_ANY_DATABASE !== 'true') {
    throw new Error(
      `Refusing to run e2e against database "${dbName}": its name must contain "test" or "e2e" ` +
        '(tables are truncated between tests). Set E2E_ALLOW_ANY_DATABASE=true to override.',
    );
  }

  const apiRoot = resolve(__dirname, '../../..');
  execFileSync(resolve(apiRoot, 'node_modules/.bin/prisma'), ['migrate', 'deploy'], {
    cwd: apiRoot,
    stdio: 'inherit',
    env: process.env,
  });

  const prisma = new PrismaClient();
  try {
    await seedCatalog(prisma);
  } finally {
    await prisma.$disconnect();
  }
}
