// Empaqueta dist/serverless.js en un único CommonJS para Vercel.
// El cargador de funciones de Vercel no admite require() de módulos ESM (NestJS 12 y
// @nestjs/swagger lo son), así que se integran en el bundle. Prisma y bcrypt quedan fuera
// (son CommonJS con binarios nativos); los paquetes opcionales de Nest que no usamos también.
import { build } from 'esbuild';

await build({
  entryPoints: ['dist/serverless.js'],
  outfile: 'dist/bundle/serverless.cjs',
  bundle: true,
  platform: 'node',
  target: 'node22',
  format: 'cjs',
  logLevel: 'error',
  // En CommonJS no hay import.meta: se sustituye por la URL del propio bundle.
  define: { 'import.meta.url': '__bundleUrl' },
  banner: { js: "const __bundleUrl = require('node:url').pathToFileURL(__filename).href;" },
  external: [
    '@prisma/client',
    '.prisma/client',
    'bcrypt',
    '@nestjs/microservices',
    '@nestjs/websockets',
    'class-validator',
    'class-transformer',
    '@fastify/static',
    '@nestjs/platform-fastify',
  ],
});
