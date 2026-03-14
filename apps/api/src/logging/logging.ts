export type LogLevel = 'info' | 'warn' | 'error';

function isProduction(): boolean {
  return process.env.NODE_ENV === 'production';
}

export function log(level: LogLevel, message: string, meta: Record<string, unknown> = {}): void {
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

