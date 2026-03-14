import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';
import { ZodError } from 'zod';

@Catch(ZodError)
export class ZodExceptionFilter implements ExceptionFilter {
  catch(exception: ZodError, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status = HttpStatus.BAD_REQUEST;
    const message =
      exception.errors?.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ') ??
      'Validation failed';
    response.status(status).json({
      statusCode: status,
      message,
      error: 'Bad Request',
    });
  }
}
