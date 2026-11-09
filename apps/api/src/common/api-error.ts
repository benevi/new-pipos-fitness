import { HttpException, HttpStatus } from '@nestjs/common';
import type { ErrorCode, FieldIssue } from '@pipos/contracts';

/**
 * Error de dominio con código estable (ErrorResponseSchema en @pipos/contracts).
 * El filtro global lo serializa como `{ statusCode, code, message, issues?, requestId }`.
 */
export class ApiError extends HttpException {
  constructor(
    status: HttpStatus,
    public readonly code: ErrorCode,
    message: string,
    public readonly issues?: FieldIssue[],
  ) {
    super({ statusCode: status, code, message, ...(issues ? { issues } : {}) }, status);
  }

  static notFound(message = 'Not found'): ApiError {
    return new ApiError(HttpStatus.NOT_FOUND, 'NOT_FOUND', message);
  }

  static validation(issues: FieldIssue[], message = 'Validation failed'): ApiError {
    return new ApiError(HttpStatus.BAD_REQUEST, 'VALIDATION_FAILED', message, issues);
  }
}

export function zodIssues(error: { issues: { path: PropertyKey[]; message: string }[] }): FieldIssue[] {
  return error.issues.map((i) => ({ path: i.path.map(String).join('.'), message: i.message }));
}
