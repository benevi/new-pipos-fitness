import type { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import type { Env } from './config/env';

/**
 * Configuración HTTP común a producción y a los tests e2e (para que los e2e
 * ejerciten exactamente la misma superficie que la API desplegada).
 */
export function configureApp(app: INestApplication, env: Env): void {
  const isProduction = env.NODE_ENV === 'production';

  // La API sólo devuelve JSON; la CSP por defecto de helmet rompería Swagger UI en desarrollo.
  app.use(helmet({ contentSecurityPolicy: isProduction ? undefined : false }));

  // Allowlist explícita: un origen que no esté en CORS_ORIGINS no recibe cabeceras CORS.
  app.enableCors({
    origin: env.CORS_ORIGINS.length > 0 ? env.CORS_ORIGINS : false,
    credentials: true,
  });

  if (!isProduction) {
    const config = new DocumentBuilder()
      .setTitle('Pipos Fitness API')
      .setDescription('API for Pipos Fitness application')
      .setVersion('0.0.1')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document);
  }
}
