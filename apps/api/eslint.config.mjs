// ESLint 10 (flat config) con typescript-eslint 8. Mismas reglas que el antiguo .eslintrc.cjs:
// eslint:recommended + @typescript-eslint/recommended, más las restricciones de los e2e.
import js from '@eslint/js';
import { defineConfig } from 'eslint/config';
import tseslint from 'typescript-eslint';

export default defineConfig(
  { ignores: ['dist/**', 'node_modules/**', 'coverage/**'] },
  {
    files: ['**/*.ts'],
    extends: [js.configs.recommended, tseslint.configs.recommended],
    languageOptions: {
      parserOptions: { project: './tsconfig.check.json', tsconfigRootDir: import.meta.dirname },
    },
  },
  {
    // Los e2e corren contra Postgres real: prohibido mockear PrismaService.
    files: ['src/**/*.e2e-spec.ts'],
    rules: {
      'no-restricted-syntax': [
        'error',
        {
          selector: "CallExpression[callee.property.name='overrideProvider'][arguments.0.name='PrismaService']",
          message: 'e2e tests must use the real database: do not override PrismaService.',
        },
        {
          selector: "Property[key.name='provide'][value.name='PrismaService']",
          message: 'e2e tests must use the real database: do not provide a fake PrismaService.',
        },
        {
          selector: "CallExpression[callee.object.name='vi'][callee.property.name='mock']",
          message: 'e2e tests must not use vi.mock: exercise the real stack.',
        },
      ],
    },
  },
);
