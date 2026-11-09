import { type ArgumentsHost, Catch, type ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import type { Response } from 'express';
import type { ErrorCode, ErrorResponse } from '@pipos/contracts';
import { log } from '../logging/logging';
import { currentRequestId } from './request-context';

const DEFAULT_CODES: Partial<Record<number, ErrorCode>> = {
  400: 'VALIDATION_FAILED',
  401: 'UNAUTHORIZED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  409: 'CONFLICT',
  422: 'VALIDATION_FAILED',
  429: 'RATE_LIMITED',
};

/** Un error inesperado se registra sin su mensaje (puede contener datos de la consulta). */
export function describeUnexpected(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    const code = (error as { code?: unknown }).code;
    return {
      errorName: error.name,
      ...(typeof code === 'string' ? { errorCode: code } : {}),
      stack: error.stack
        ?.split('\n')
        .filter((l) => l.trimStart().startsWith('at '))
        .slice(0, 6)
        .join('\n'),
    };
  }
  return { errorName: typeof error };
}

/**
 * Filtro global: toda respuesta de error sigue ErrorResponseSchema
 * `{ statusCode, code, message, issues?, requestId }`.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    const requestId = currentRequestId();
    let body: ErrorResponse;

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const raw = exception.getResponse();
      const obj = typeof raw === 'object' && raw !== null ? (raw as Record<string, unknown>) : {};
      const message =
        typeof raw === 'string'
          ? raw
          : Array.isArray(obj.message)
            ? obj.message.join('; ')
            : typeof obj.message === 'string'
              ? obj.message
              : exception.message;
      const code =
        exception instanceof ThrottlerException
          ? 'RATE_LIMITED'
          : typeof obj.code === 'string'
            ? obj.code
            : (DEFAULT_CODES[status] ?? (status >= 500 ? 'INTERNAL' : 'CONFLICT'));
      body = {
        statusCode: status,
        code,
        message,
        ...(Array.isArray(obj.issues) ? { issues: obj.issues as ErrorResponse['issues'] } : {}),
      };
      if (status >= 500) log('error', 'Request failed', { statusCode: status, code });
    } else {
      log('error', 'Unhandled error', describeUnexpected(exception));
      body = { statusCode: HttpStatus.INTERNAL_SERVER_ERROR, code: 'INTERNAL', message: 'Internal server error' };
    }

    if (requestId) body.requestId = requestId;
    res.status(body.statusCode).json(body);
  }
}
