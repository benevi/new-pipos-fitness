import { Controller, Get, UseGuards } from '@nestjs/common';
import { NutritionTargetsResponseSchema } from '@pipos/contracts';
import { Contract } from '../../common/contract';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { NutritionService } from './nutrition.service';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class NutritionController {
  constructor(private readonly nutrition: NutritionService) {}

  @Get('nutrition-targets')
  @Contract({
    tag: 'nutrition',
    summary: 'Objetivos diarios de energía y macros (422 con los campos que faltan)',
    response: NutritionTargetsResponseSchema,
    errors: [409, 422],
  })
  targets(@CurrentUser() user: AuthenticatedUser) {
    return this.nutrition.targets(user.id);
  }
}
