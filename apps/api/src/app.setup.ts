import type { INestApplication } from '@nestjs/common';
import { SwaggerModule, type OpenAPIObject } from '@nestjs/swagger';
import helmet from 'helmet';
import { FEATURE_MODULES } from './app.module';
import { accessLogMiddleware } from './common/access-log.middleware';
import { requestContextMiddleware } from './common/request-context';
import type { Env } from './config/env';
import { buildOpenApiDocument } from './openapi/openapi';

export const API_VERSION = '1.0.0';

/**
 * Configuración HTTP común a producción y a los tests e2e (para que los e2e
 * ejerciten exactamente la misma superficie que la API desplegada).
 */
export function configureApp(app: INestApplication, env: Env): void {
  const isProduction = env.NODE_ENV === 'production';

  // Id de petición + log de acceso estructurado (antes que cualquier otro middleware).
  app.use(requestContextMiddleware);
  app.use(accessLogMiddleware);

  // La API sólo devuelve JSON; la CSP por defecto de helmet rompería Swagger UI en desarrollo.
  app.use(helmet({ contentSecurityPolicy: isProduction ? undefined : false }));

  // Allowlist explícita: un origen que no esté en CORS_ORIGINS no recibe cabeceras CORS.
  app.enableCors({
    origin: env.CORS_ORIGINS.length > 0 ? env.CORS_ORIGINS : false,
    credentials: true,
    exposedHeaders: ['X-Request-Id'],
  });

  if (!isProduction) {
    // OpenAPI generado desde los contratos Zod (el mismo que apps/api/openapi.json).
    const document = buildOpenApiDocument(FEATURE_MODULES, { version: API_VERSION }) as unknown as OpenAPIObject;
    SwaggerModule.setup('docs', app, document);
  }
}
