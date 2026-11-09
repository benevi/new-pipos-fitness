/**
 * Configuración de Prisma 7 (CLI: generate, migrate, seed). Las URL salen del entorno; ya no se
 * declaran en schema.prisma. Prisma 7 no carga `.env` por sí mismo: lo hace `loadDotEnv` (si
 * existe, sin pisar el entorno). `DATABASE_URL_SHADOW` solo hace falta para `prisma:diff`.
 */
import { defineConfig } from 'prisma/config';
import { loadDotEnv } from './src/config/dotenv';

loadDotEnv();

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    url: process.env.DATABASE_URL,
    shadowDatabaseUrl: process.env.DATABASE_URL_SHADOW,
  },
});
