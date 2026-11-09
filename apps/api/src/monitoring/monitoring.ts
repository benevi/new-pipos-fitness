import { describeUnexpected } from '../common/http-exception.filter';
import { log } from '../logging/logging';

let initialized = false;

type Exit = (code: number) => never;

/**
 * Tras una excepción no capturada el proceso queda en estado indefinido:
 * se registra y se termina con código 1 para que el orquestador lo reinicie.
 * Como en HttpExceptionFilter, solo nombre, código y frames de la pila: el mensaje puede
 * contener datos personales (p. ej. valores de una consulta) y no se registra.
 */
export function handleUncaughtException(error: Error, exit: Exit = process.exit): never {
  log('error', 'Uncaught exception; exiting', describeUnexpected(error));
  return exit(1);
}

export function handleUnhandledRejection(reason: unknown): void {
  log('error', 'Unhandled rejection', describeUnexpected(reason));
}

export function initMonitoring(options: { sentryDsn?: string } = {}): void {
  if (initialized) return;
  initialized = true;

  process.on('uncaughtException', (error: Error) => handleUncaughtException(error));
  process.on('unhandledRejection', handleUnhandledRejection);

  if (!options.sentryDsn) {
    log('info', 'Monitoring disabled (no SENTRY_DSN configured)');
    return;
  }
  log('info', 'Monitoring initialized', { provider: 'sentry-like', hasDsn: true });
}
