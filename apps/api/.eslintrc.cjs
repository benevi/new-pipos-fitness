module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: { project: './tsconfig.json' },
  plugins: ['@typescript-eslint'],
  extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended'],
  ignorePatterns: ['dist', 'node_modules'],
  overrides: [
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
  ],
};
