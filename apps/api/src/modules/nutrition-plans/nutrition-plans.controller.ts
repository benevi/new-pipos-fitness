import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../users/current-user.decorator';
import { NutritionPlansService } from './nutrition-plans.service';

@ApiTags('nutrition-plans')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('nutrition-plans')
export class NutritionPlansController {
  constructor(private readonly nutritionPlansService: NutritionPlansService) {}

  @Post('generate')
  @ApiOperation({ summary: 'Generate a new nutrition plan version' })
  generate(
    @CurrentUser() user: { id: string },
    @Body() body: { goal?: 'lose_fat' | 'build_muscle' | 'maintain' },
  ) {
    return this.nutritionPlansService.generatePlan(user.id, body?.goal);
  }

  @Get('current')
  @ApiOperation({ summary: 'Get current nutrition plan snapshot' })
  getCurrent(@CurrentUser() user: { id: string }) {
    return this.nutritionPlansService.getCurrent(user.id);
  }

  @Get('versions')
  @ApiOperation({ summary: 'List nutrition plan versions' })
  getVersions(@CurrentUser() user: { id: string }) {
    return this.nutritionPlansService.getVersions(user.id);
  }
}
