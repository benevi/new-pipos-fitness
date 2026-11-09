import type { NextFunction, Request, Response } from 'express';
import { log } from '../logging/logging';

/**
 * Una línea JSON por petición: método, ruta (sin query string), estado y duración.
 * Nunca registra cuerpos, cabeceras ni query (pueden llevar datos personales o de salud).
 */
export function accessLogMiddleware(req: Request, res: Response, next: NextFunction): void {
  const started = process.hrtime.bigint();
  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - started) / 1e6;
    const level = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info';
    log(level, 'request', {
      method: req.method,
      path: req.originalUrl.split('?')[0],
      statusCode: res.statusCode,
      durationMs: Math.round(durationMs * 10) / 10,
    });
  });
  next();
}
