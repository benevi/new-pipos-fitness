import { Controller, Get, Param, Query } from '@nestjs/common';
import { z } from 'zod';
import {
  ExerciseDetailSchema,
  ExerciseListQuerySchema,
  ExerciseListResponseSchema,
  IdSchema,
  type ExerciseListQuery,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import { CatalogService } from './catalog.service';

export const IdParamsSchema = z.object({ id: IdSchema }).strict();

/** Catálogo público de solo lectura (seed versionado, ADR-0005). */
@Controller('exercises')
export class CatalogController {
  constructor(private readonly catalog: CatalogService) {}

  @Get()
  @Contract({
    tag: 'catalog',
    summary: 'Listar ejercicios activos (paginado)',
    auth: false,
    query: ExerciseListQuerySchema,
    response: ExerciseListResponseSchema,
  })
  list(@Query() query: ExerciseListQuery) {
    return this.catalog.list(query);
  }

  @Get(':id')
  @Contract({
    tag: 'catalog',
    summary: 'Detalle de un ejercicio',
    auth: false,
    params: IdParamsSchema,
    response: ExerciseDetailSchema,
    errors: [404],
  })
  get(@Param('id') id: string) {
    return this.catalog.get(id);
  }
}
