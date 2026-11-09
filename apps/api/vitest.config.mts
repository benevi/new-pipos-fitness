import { defineConfig } from 'vitest/config';
import { resolve } from 'path';
import swc from 'unplugin-swc';

/**
 * Tests unitarios (src/**\/*.spec.ts). Los e2e (*.e2e-spec.ts) van en vitest.e2e.config.mts.
 * SWC emite metadatos de decoradores (emitDecoratorMetadata), necesarios para la DI de Nest.
 * Cobertura exigida (SPEC_V1 «Calidad»): ≥ 80 % en los servicios de la API.
 */
export default defineConfig({
  plugins: [swc.vite({ module: { type: 'es6' } })],
  test: {
    globals: true,
    include: ['src/**/*.spec.ts'],
    exclude: ['src/**/*.e2e-spec.ts', 'node_modules', 'dist'],
    coverage: {
      provider: 'v8',
      include: ['src/**/*.service.ts'],
      exclude: ['src/prisma/**'],
      reporter: ['text-summary', 'text'],
      thresholds: { lines: 80, statements: 80, functions: 80, branches: 80 },
    },
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
