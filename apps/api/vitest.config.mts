import { defineConfig } from 'vitest/config';
import { resolve } from 'path';
import swc from 'unplugin-swc';

/**
 * Tests unitarios (src/**\/*.spec.ts). Los e2e (*.e2e-spec.ts) van en vitest.e2e.config.ts.
 * SWC emite metadatos de decoradores (emitDecoratorMetadata), necesarios para la DI de Nest.
 */
export default defineConfig({
  plugins: [swc.vite({ module: { type: 'es6' } })],
  test: {
    globals: true,
    include: ['src/**/*.spec.ts'],
    exclude: ['src/**/*.e2e-spec.ts', 'node_modules', 'dist'],
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
