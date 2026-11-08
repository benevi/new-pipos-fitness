import { Injectable, Param, PipeTransform, Query } from '@nestjs/common';
import { z, type ZodType } from 'zod';
import { parseOrBadRequest } from './zod-error';

/**
 * Pipe genérico que valida/transforma un valor con un esquema Zod.
 * Un fallo de validación se traduce a 400 (BadRequestException).
 */
@Injectable()
export class ZodValidationPipe<T> implements PipeTransform<unknown, T> {
  constructor(private readonly schema: ZodType<T>) {}

  transform(value: unknown): T {
    return parseOrBadRequest(this.schema, value);
  }
}

const UuidParamSchema = z.string().uuid();

/** `@UuidParam('id')`: parámetro de ruta obligatoriamente UUID (si no, 400 antes de tocar la BD). */
export const UuidParam = (name = 'id') => Param(name, new ZodValidationPipe(UuidParamSchema));

/** `@ZodParam('slug', schema)`: parámetro de ruta validado con un esquema arbitrario. */
export const ZodParam = <T>(name: string, schema: ZodType<T>) =>
  Param(name, new ZodValidationPipe(schema));

/** `@ZodQuery(schema)`: query string completa validada con un esquema Zod. */
export const ZodQuery = <T>(schema: ZodType<T>) => Query(new ZodValidationPipe(schema));
