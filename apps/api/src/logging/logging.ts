export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LEVEL_ORDER: Record<LogLevel, number> = { debug: 10, info: 20, warn: 30, error: 40 };

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

function minLevel(): LogLevel {
  const configured = process.env.LOG_LEVEL as LogLevel | undefined;
  return configured && configured in LEVEL_ORDER ? configured : 'info';
}

export function log(level: LogLevel, message: string, meta: Record<string, unknown> = {}): void {
  if (LEVEL_ORDER[level] < LEVEL_ORDER[minLevel()]) return;

  const payload = {
    level,
    message,
    ...meta,
    timestamp: new Date().toISOString(),
  };

  if (isProduction()) {
    // Structured JSON logging in production.
    // eslint-disable-next-line no-console
    console.log(JSON.stringify(payload));
  } else {
    // Human-readable logs in non-production environments.
    // eslint-disable-next-line no-console
    console.log(`[${payload.timestamp}] [${level}] ${message}`, meta);
  }
}
