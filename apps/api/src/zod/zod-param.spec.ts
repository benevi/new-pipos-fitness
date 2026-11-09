import { describe, it, expect } from 'vitest';
import { BadRequestException } from '@nestjs/common';
import { z } from 'zod';
import { ZodValidationPipe } from './zod-param';

describe('ZodValidationPipe', () => {
  const uuidPipe = new ZodValidationPipe(z.string().uuid());

  it('devuelve el valor si cumple el esquema', () => {
    const id = '7b0c4a4e-2d0b-4c39-9a51-0f4d2f6f2b11';
    expect(uuidPipe.transform(id)).toBe(id);
  });

  it('lanza BadRequestException (400) si no cumple', () => {
    expect(() => uuidPipe.transform('ex1')).toThrow(BadRequestException);
    expect(() => uuidPipe.transform("1' OR '1'='1")).toThrow(BadRequestException);
  });

  it('aplica transformaciones (coerción de query)', () => {
    const pipe = new ZodValidationPipe(z.object({ limit: z.coerce.number().default(5) }));
    expect(pipe.transform({ limit: '10' })).toEqual({ limit: 10 });
    expect(pipe.transform({})).toEqual({ limit: 5 });
  });
});
