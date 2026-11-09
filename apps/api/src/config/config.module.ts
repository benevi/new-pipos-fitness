import { Global, Module } from '@nestjs/common';
import { APP_ENV, parseEnv } from './env';

/**
 * Expone el entorno validado como provider inyectable (token APP_ENV).
 * Se parsea al construir el módulo, así cada app (incl. e2e) lee su propio process.env.
 */
@Global()
@Module({
  providers: [{ provide: APP_ENV, useFactory: () => parseEnv(process.env) }],
  exports: [APP_ENV],
})
export class AppConfigModule {}
