import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    testTimeout: 60_000,
    coverage: {
      provider: 'v8',
      include: ['src/**/*.ts'],
      // legacy/ es la capa de compatibilidad congelada del motor v1 (se borra en la Fase 3).
      exclude: ['src/**/*.test.ts', 'src/legacy/**', 'src/test-support/**', 'src/index.ts', 'src/**/index.ts'],
      reporter: ['text-summary', 'text'],
      thresholds: { lines: 90, statements: 90, functions: 90, branches: 85 },
    },
  },
});
