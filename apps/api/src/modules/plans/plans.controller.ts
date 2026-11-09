import { Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
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
import { PlansService } from './plans.service';

@Controller('plans')
@UseGuards(JwtAuthGuard)
export class PlansController {
  constructor(private readonly plans: PlansService) {}

  @Post('generate')
  @Throttle({ default: THROTTLE_LIMITS.PLAN_GENERATION })
  @Contract({
    tag: 'plans',
    summary: 'Generar una versión nueva del plan a partir del perfil',
    response: PlanVersionResponseSchema,
    status: 201,
    errors: [409, 422],
  })
  generate(@CurrentUser() user: AuthenticatedUser) {
    return this.plans.generate(user.id);
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
}
