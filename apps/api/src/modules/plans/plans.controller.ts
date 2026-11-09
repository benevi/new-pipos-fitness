import { Body, Controller, Delete, Get, Headers, Param, Post, Put, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { z } from 'zod';
import { Throttle } from '@nestjs/throttler';
import {
  IdSchema,
  IdempotencyKeyHeadersSchema,
  PlanExerciseOverrideRequestSchema,
  PlanExerciseOverrideResponseSchema,
  type PlanExerciseOverrideRequest,
  PaginationQuerySchema,
  PlanVersionListResponseSchema,
  PlanVersionResponseSchema,
  type PaginationQuery,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import { THROTTLE_LIMITS } from '../../config/throttle';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IdParamsSchema } from '../catalog/catalog.controller';
import { OverridesService } from './overrides.service';
import { PlansService } from './plans.service';

const SlotParamsSchema = z.object({ planExerciseId: IdSchema }).strict();

@Controller('plans')
@UseGuards(JwtAuthGuard)
export class PlansController {
  constructor(
    private readonly plans: PlansService,
    private readonly overrides: OverridesService,
  ) {}

  @Post('generate')
  @Throttle({ default: THROTTLE_LIMITS.PLAN_GENERATION })
  @Contract({
    tag: 'plans',
    summary: 'Generar una versión nueva del plan a partir del perfil',
    description:
      'Cabecera opcional Idempotency-Key (recomendado un UUID v4 por intento, igual en cada reintento): repetir la clave devuelve la misma versión con 200 en vez de crear otra; la misma clave con otra entrada (el perfil cambió entre medias) → 422 IDEMPOTENCY_KEY_REUSED. Sin cabecera, cada petición crea una versión.',
    headers: IdempotencyKeyHeadersSchema,
    response: PlanVersionResponseSchema,
    status: 201,
    alternateStatuses: [200],
    errors: [409, 422],
  })
  async generate(
    @CurrentUser() user: AuthenticatedUser,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.plans.generate(user.id, idempotencyKey);
    res.status(result.created ? 201 : 200);
    return result.value;
  }

  @Get('current')
  @Contract({ tag: 'plans', summary: 'Versión vigente del plan', response: PlanVersionResponseSchema, errors: [404] })
  current(@CurrentUser() user: AuthenticatedUser) {
    return this.plans.current(user.id);
  }

  @Get('versions')
  @Contract({
    tag: 'plans',
    summary: 'Historial de versiones (paginado, más reciente primero)',
    query: PaginationQuerySchema,
    response: PlanVersionListResponseSchema,
  })
  versions(@CurrentUser() user: AuthenticatedUser, @Query() query: PaginationQuery) {
    return this.plans.versions(user.id, query);
  }

  @Get('versions/:id')
  @Contract({
    tag: 'plans',
    summary: 'Una versión concreta del plan',
    params: IdParamsSchema,
    response: PlanVersionResponseSchema,
    errors: [404],
  })
  version(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.plans.version(user.id, id);
  }

  @Put('current/exercises/:planExerciseId/override')
  @Contract({
    tag: 'plans',
    summary: 'Fijar un cambio de ejercicio en el plan vigente (se hereda en las versiones siguientes)',
    description:
      'Debe ser una alternativa válida del ejercicio original para tu perfil (400 si no). Se aplica a todos los huecos de la versión vigente con ese ejercicio y no crea una versión nueva. Si exerciseId es el original, equivale a DELETE.',
    params: SlotParamsSchema,
    body: PlanExerciseOverrideRequestSchema,
    response: PlanExerciseOverrideResponseSchema,
    errors: [404, 409],
  })
  pin(
    @CurrentUser() user: AuthenticatedUser,
    @Param('planExerciseId') planExerciseId: string,
    @Body() body: PlanExerciseOverrideRequest,
  ) {
    return this.overrides.pin(user.id, planExerciseId, body.exerciseId);
  }

  @Delete('current/exercises/:planExerciseId/override')
  @Contract({
    tag: 'plans',
    summary: 'Volver al ejercicio original del plan (idempotente)',
    params: SlotParamsSchema,
    response: PlanExerciseOverrideResponseSchema,
    errors: [404],
  })
  unpin(@CurrentUser() user: AuthenticatedUser, @Param('planExerciseId') planExerciseId: string) {
    return this.overrides.unpin(user.id, planExerciseId);
  }
}
