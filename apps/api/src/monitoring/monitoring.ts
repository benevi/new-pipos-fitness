import { log } from '../logging/logging';

let initialized = false;

export function initMonitoring(): void {
  if (initialized) return;
  initialized = true;

  const dsn = process.env.SENTRY_DSN;
  if (!dsn) {
    log('info', 'Monitoring disabled (no SENTRY_DSN configured)');
    return;
  }

  log('info', 'Monitoring initialized', { provider: 'sentry-like', hasDsn: true });

  process.on('uncaughtException', (error: Error) => {
    log('error', 'Uncaught exception', {
      error: error.message,
      stack: error.stack,
    });
  });

  process.on('unhandledRejection', (reason: unknown) => {
    log('error', 'Unhandled rejection', {
      reason: reason instanceof Error ? reason.message : String(reason),
    });
  });
}

