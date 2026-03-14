import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { ZodExceptionFilter } from './zod/zod-exception.filter';
import { log } from './logging/logging';
import { initMonitoring } from './monitoring/monitoring';

function enforceEnvConfig(): void {
  if (process.env.NODE_ENV === 'test') return;
  const required = ['DATABASE_URL', 'JWT_ACCESS_SECRET', 'JWT_REFRESH_SECRET', 'PORT', 'NODE_ENV'];
  const missing = required.filter((key) => !process.env[key] || !process.env[key]!.toString().length);
  if (missing.length > 0) {
    log('error', 'Missing required environment variables', { missing });
    process.exit(1);
  }
}

async function bootstrap() {
  initMonitoring();
  enforceEnvConfig();
  const app = await NestFactory.create(AppModule);
  app.useGlobalFilters(new ZodExceptionFilter());
  app.enableCors({
    origin: process.env.NODE_ENV === 'production' ? false : true,
    credentials: true,
  });
  const config = new DocumentBuilder()
    .setTitle('Pipos Fitness API')
    .setDescription('API for Pipos Fitness application')
    .setVersion('0.0.1')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);
  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
  log('info', 'Server started', {
    port,
    env: process.env.NODE_ENV ?? 'development',
  });
}

bootstrap();
