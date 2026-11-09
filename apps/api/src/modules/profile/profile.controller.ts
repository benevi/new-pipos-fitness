import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import {
  CreateTrainingBreakRequestSchema,
  OkResponseSchema,
  ProfileScheduleRequestSchema,
  TrainingBreakListQuerySchema,
  TrainingBreakListResponseSchema,
  TrainingBreakResponseSchema,
  type CreateTrainingBreakRequest,
  type ProfileScheduleRequest,
  type TrainingBreakListQuery,
  GrantHealthConsentRequestSchema,
  HealthConsentStatusSchema,
  ProfileResponseSchema,
  ProfileUpdateResponseSchema,
  ProfileUpsertRequestSchema,
  WithdrawHealthConsentResponseSchema,
  type Locale,
  type ProfileUpsert,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ConsentService } from './consent.service';
import { IdParamsSchema } from '../catalog/catalog.controller';
import { ProfileService } from './profile.service';
import { ScheduleService } from './schedule.service';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(
    private readonly profiles: ProfileService,
    private readonly consents: ConsentService,
    private readonly schedule: ScheduleService,
  ) {}

  @Get('profile')
  @Contract({ tag: 'profile', summary: 'Perfil de entrenamiento', response: ProfileResponseSchema, errors: [404] })
  get(@CurrentUser() user: AuthenticatedUser) {
    return this.profiles.get(user.id);
  }

  @Put('profile')
  @Contract({
    tag: 'profile',
    summary: 'Crear o sustituir el perfil (regenera el plan si cambia algo que lo afecta)',
    description:
      'limitations, weightKg y heightCm son datos de salud: sin consentimiento vigente → 409 HEALTH_CONSENT_REQUIRED.',
    body: ProfileUpsertRequestSchema,
    response: ProfileUpdateResponseSchema,
    errors: [409, 422],
  })
  put(@CurrentUser() user: AuthenticatedUser, @Body() body: ProfileUpsert) {
    return this.profiles.upsert(user.id, body);
  }

  @Get('consents/health')
  @Contract({ tag: 'profile', summary: 'Estado del consentimiento de datos de salud', response: HealthConsentStatusSchema })
  consent(@CurrentUser() user: AuthenticatedUser) {
    return this.consents.status(user.id);
  }

  @Post('consents/health')
  @Contract({
    tag: 'profile',
    summary: 'Conceder el consentimiento de datos de salud (versión del texto mostrado)',
    body: GrantHealthConsentRequestSchema,
    response: HealthConsentStatusSchema,
    errors: [422],
  })
  grant(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { version: string; locale: Locale },
  ) {
    return this.consents.grant(user.id, body);
  }

  @Delete('consents/health')
  @Contract({
    tag: 'profile',
    summary: 'Retirar el consentimiento: borra los datos de salud y regenera el plan sin ellos',
    response: WithdrawHealthConsentResponseSchema,
  })
  withdraw(@CurrentUser() user: AuthenticatedUser) {
    return this.consents.withdraw(user.id);
  }

  // ── Días de entreno y pausas planificadas (idea 6, ADR-0013) ──

  @Patch('profile/schedule')
  @Contract({
    tag: 'profile',
    summary: 'Días de entreno preferidos (no crea versión del plan)',
    description:
      'ISO 1 = lunes … 7 = domingo, como mucho daysPerWeek (422 si hay más). Solo sirven para el recordatorio local del móvil y para «hoy toca».',
    body: ProfileScheduleRequestSchema,
    response: ProfileResponseSchema,
    errors: [404, 422],
  })
  setSchedule(@CurrentUser() user: AuthenticatedUser, @Body() body: ProfileScheduleRequest) {
    return this.schedule.setWeekdays(user.id, body);
  }

  @Get('breaks')
  @Contract({
    tag: 'profile',
    summary: 'Pausas planificadas (las que terminan en `from` o después)',
    query: TrainingBreakListQuerySchema,
    response: TrainingBreakListResponseSchema,
  })
  listBreaks(@CurrentUser() user: AuthenticatedUser, @Query() query: TrainingBreakListQuery) {
    return this.schedule.listBreaks(user.id, query);
  }

  @Post('breaks')
  @Contract({
    tag: 'profile',
    summary: 'Crear una pausa planificada (idempotente por clientId; 409 si se solapa con otra)',
    description: 'Sin motivo (sería un dato de salud). Excluye esos días de la adherencia y de la ausencia que baja la carga.',
    body: CreateTrainingBreakRequestSchema,
    response: TrainingBreakResponseSchema,
    status: 201,
    alternateStatuses: [200],
    errors: [409],
  })
  async createBreak(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateTrainingBreakRequest,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.schedule.createBreak(user.id, body);
    res.status(result.created ? 201 : 200);
    return result.value;
  }

  @Delete('breaks/:id')
  @Contract({ tag: 'profile', summary: 'Borrar una pausa planificada (idempotente)', params: IdParamsSchema, response: OkResponseSchema })
  async deleteBreak(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.schedule.deleteBreak(user.id, id);
    return { ok: true as const };
  }
}
