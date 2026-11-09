import { AsyncLocalStorage } from 'async_hooks';
import { randomUUID } from 'crypto';
import type { NextFunction, Request, Response } from 'express';

interface RequestContext {
  requestId: string;
}

const storage = new AsyncLocalStorage<RequestContext>();

export const REQUEST_ID_HEADER = 'x-request-id';

/** Solo se acepta un id de cliente con forma segura (evita inyección en logs). */
const SAFE_ID = /^[A-Za-z0-9._-]{8,64}$/;

export function currentRequestId(): string | undefined {
  return storage.getStore()?.requestId;
}

export function runWithRequestId<T>(requestId: string, fn: () => T): T {
  return storage.run({ requestId }, fn);
}

export function resolveRequestId(incoming: unknown): string {
  return typeof incoming === 'string' && SAFE_ID.test(incoming) ? incoming : randomUUID();
}

/** Middleware Express: asigna un id por petición, lo devuelve en `X-Request-Id` y lo propaga a los logs. */
export function requestContextMiddleware(req: Request, res: Response, next: NextFunction): void {
  const requestId = resolveRequestId(req.headers[REQUEST_ID_HEADER]);
  res.setHeader('X-Request-Id', requestId);
  runWithRequestId(requestId, () => next());
}
