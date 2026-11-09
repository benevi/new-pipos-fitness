import { existsSync } from 'node:fs';
import { resolve } from 'node:path';

/**
 * Carga `.env` del directorio actual (apps/api con `pnpm --filter @pipos/api …`) si existe, sin
 * pisar las variables ya definidas. Hasta Prisma 6 lo hacía el propio `@prisma/client` al
 * importarse; Prisma 7 ya no, así que se hace explícito para el desarrollo local. En producción
 * no hay `.env`: las variables llegan del entorno.
 */
export function loadDotEnv(file = resolve(process.cwd(), '.env')): void {
  if (existsSync(file)) process.loadEnvFile(file);
}
