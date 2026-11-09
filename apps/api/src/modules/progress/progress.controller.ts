import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  AdherenceResponseSchema,
  E1rmQuerySchema,
  E1rmResponseSchema,
  VolumeResponseSchema,
  WeeksQuerySchema,
  type E1rmQuery,
  type WeeksQuery,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ProgressService } from './progress.service';

@Controller('progress')
@UseGuards(JwtAuthGuard)
export class ProgressController {
  constructor(private readonly progress: ProgressService) {}

  @Get('e1rm')
  @Contract({ tag: 'progress', summary: 'e1RM por ejercicio y sesión', query: E1rmQuerySchema, response: E1rmResponseSchema })
  e1rm(@CurrentUser() user: AuthenticatedUser, @Query() query: E1rmQuery) {
    return this.progress.e1rm(user.id, query);
  }

  @Get('volume')
  @Contract({
    tag: 'progress',
    summary: 'Series efectivas semanales por músculo y grupo frente al rango objetivo',
    query: WeeksQuerySchema,
    response: VolumeResponseSchema,
  })
  volume(@CurrentUser() user: AuthenticatedUser, @Query() query: WeeksQuery) {
    return this.progress.volume(user.id, query.weeks);
  }

  @Get('adherence')
  @Contract({
    tag: 'progress',
    summary: 'Adherencia semanal (sesiones hechas / planificadas)',
    query: WeeksQuerySchema,
    response: AdherenceResponseSchema,
  })
  adherence(@CurrentUser() user: AuthenticatedUser, @Query() query: WeeksQuery) {
    return this.progress.adherence(user.id, query.weeks);
  }
}
