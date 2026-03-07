import {
  type CallHandler,
  type ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { type ZodType } from 'zod';
import { Observable } from 'rxjs';

export const ZOD_SCHEMA_KEY = 'zodSchema';

@Injectable()
export class ZodValidationInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const schema = this.reflector.get<ZodType | undefined>(
      ZOD_SCHEMA_KEY,
      context.getHandler(),
    );
    if (schema) {
      const request = context.switchToHttp().getRequest();
      request.body = schema.parse(request.body ?? {});
    }
    return next.handle();
  }
}
