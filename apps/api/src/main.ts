import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { InvalidEnvError, parseEnv, type Env } from './config/env';
import { log } from './logging/logging';
import { initMonitoring } from './monitoring/monitoring';

function loadEnvOrExit(): Env {
  try {
    return parseEnv(process.env);
  } catch (error) {
    if (error instanceof InvalidEnvError) {
      log('error', 'Invalid environment configuration; refusing to start', { issues: error.issues });
      process.exit(1);
    }
    throw error;
  }
}

async function bootstrap() {
  const env = loadEnvOrExit();
  initMonitoring({ sentryDsn: env.SENTRY_DSN });
  const app = await NestFactory.create(AppModule);
  configureApp(app, env);
  await app.listen(env.PORT);
  log('info', 'Server started', { port: env.PORT, env: env.NODE_ENV });
}

bootstrap();
