import { defineConfig } from 'vitest/config';
import { resolve } from 'path';
import swc from 'unplugin-swc';

/**
 * Tests e2e contra un Postgres REAL (sin mocks de PrismaService).
 * Requiere DATABASE_URL apuntando a una base de datos desechable: global-setup aplica
 * las migraciones (prisma migrate deploy) y cada test trunca las tablas.
 */
export default defineConfig({
  plugins: [swc.vite({ module: { type: 'es6' } })],
  test: {
    globals: true,
    include: ['src/**/*.e2e-spec.ts'],
    globalSetup: ['./src/test/e2e/global-setup.ts'],
    setupFiles: ['./src/test/e2e/setup-env.ts'],
    // Todas las suites comparten la misma base de datos: se ejecutan en serie, en un solo proceso
    // (Vitest 4+ sustituye `poolOptions.forks.singleFork` por `maxWorkers: 1`).
    fileParallelism: false,
    pool: 'forks',
    maxWorkers: 1,
    testTimeout: 30_000,
    hookTimeout: 60_000,
  },
  resolve: {
    alias: {
      '@': resolve(import.meta.dirname, './src'),
    },
  },
});
