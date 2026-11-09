import { NestFactory } from '@nestjs/core';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { parseEnv } from './config/env';
import { log } from './logging/logging';
import { initMonitoring } from './monitoring/monitoring';

type Handler = (req: IncomingMessage, res: ServerResponse) => void;

let handlerPromise: Promise<Handler> | undefined;

/**
 * Arranque para funciones serverless (Vercel). Crea la app Nest una vez por instancia y
 * reutiliza la instancia de Express entre peticiones. Misma configuración que `main.ts`:
 * si el entorno no es válido, la función falla en lugar de arrancar con valores inseguros.
 */
async function createHandler(): Promise<Handler> {
  const env = parseEnv(process.env);
  initMonitoring({ sentryDsn: env.SENTRY_DSN });
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  configureApp(app, env);
  await app.init();
  log('info', 'Serverless handler ready', { env: env.NODE_ENV });
  return app.getHttpAdapter().getInstance() as Handler;
}

export default async function handler(req: IncomingMessage, res: ServerResponse): Promise<void> {
  handlerPromise ??= createHandler().catch((error: unknown) => {
    handlerPromise = undefined;
    throw error;
  });
  const app = await handlerPromise;
  app(req, res);
}
