import {
  type CallHandler,
  type ExecutionContext,
  HttpStatus,
  Injectable,
  type NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { ZodTypeAny } from 'zod';
import { map, type Observable } from 'rxjs';
import { log } from '../logging/logging';
import { ApiError, zodIssues } from './api-error';
import { CONTRACT_KEY, type ContractSpec } from './contract';

function parseInput(schema: ZodTypeAny | undefined, value: unknown, where: string): unknown {
  if (!schema) return value;
  const result = schema.safeParse(value ?? {});
  if (!result.success) {
    throw ApiError.validation(
      zodIssues(result.error).map((i) => ({ ...i, path: i.path ? `${where}.${i.path}` : where })),
    );
  }
  return result.data;
}

/**
 * Valida params → query → body con el contrato antes del handler y la respuesta después.
 * Una respuesta que no cumple su contrato es un bug del servidor: 500 y log (sin valores).
 * Las claves que el contrato no declara se eliminan de la salida (no se filtran campos).
 */
@Injectable()
export class ContractInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const spec = this.reflector.get<ContractSpec | undefined>(CONTRACT_KEY, context.getHandler());
    if (!spec || context.getType() !== 'http') return next.handle();

    const req = context.switchToHttp().getRequest();
    req.params = parseInput(spec.params, req.params, 'params');
    // Solo se validan; el handler las lee con @Headers (req.headers no se reasigna).
    if (spec.headers) parseInput(spec.headers, req.headers, 'headers');
    if (spec.query) {
      // En Express 5 `req.query` es un getter de solo lectura: se redefine como propiedad propia
      // para que el handler (@Query) reciba el objeto ya validado.
      Object.defineProperty(req, 'query', {
        value: parseInput(spec.query, req.query, 'query'),
        writable: true,
        configurable: true,
        enumerable: true,
      });
    }
    if (spec.body) req.body = parseInput(spec.body, req.body, 'body');

    const route = `${req.method} ${req.route?.path ?? req.path}`;
    return next.handle().pipe(
      map((out: unknown) => {
        if (spec.response === null) return undefined;
        const result = spec.response.safeParse(out);
        if (!result.success) {
          log('error', 'Response contract violation', {
            route,
            issues: result.error.issues.map((i) => ({ path: i.path.join('.'), code: i.code })),
          });
          throw new ApiError(HttpStatus.INTERNAL_SERVER_ERROR, 'INTERNAL', 'Internal server error');
        }
        return result.data;
      }),
    );
  }
}
