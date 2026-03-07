import { applyDecorators, SetMetadata } from '@nestjs/common';
import { type ZodType } from 'zod';
import { ZOD_SCHEMA_KEY } from './zod-validation.interceptor';

export function ZodBody(schema: ZodType) {
  return applyDecorators(SetMetadata(ZOD_SCHEMA_KEY, schema));
}
