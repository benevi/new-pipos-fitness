import { Body, Controller, Delete, Get, Post, Put, UseGuards } from '@nestjs/common';
import {
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
import { ProfileService } from './profile.service';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class ProfileController {
  constructor(
    private readonly profiles: ProfileService,
    private readonly consents: ConsentService,
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
}
