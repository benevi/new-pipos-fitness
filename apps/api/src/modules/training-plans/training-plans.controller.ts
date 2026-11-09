import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { THROTTLE_LIMITS } from '../../config/throttle';
import { UuidParam } from '../../zod/zod-param';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../users/current-user.decorator';
import { TrainingPlansService } from './training-plans.service';

@ApiTags('training-plans')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('training-plans')
export class TrainingPlansController {
  constructor(private readonly trainingPlansService: TrainingPlansService) {}

  @Post('generate')
  @Throttle({ default: THROTTLE_LIMITS.PLAN_GENERATION })
  @ApiOperation({ summary: 'Generate a new training plan version' })
  generate(@CurrentUser() user: { id: string }) {
    return this.trainingPlansService.generatePlan(user.id);
  }

  @Get('current')
  @ApiOperation({ summary: 'Get current plan snapshot' })
  getCurrent(@CurrentUser() user: { id: string }) {
    return this.trainingPlansService.getCurrent(user.id);
  }

  @Get('versions')
  @ApiOperation({ summary: 'List plan versions' })
  getVersions(@CurrentUser() user: { id: string }) {
    return this.trainingPlansService.getVersions(user.id);
  }

  @Get('versions/:id')
  @ApiOperation({ summary: 'Get specific version' })
  getVersionById(@CurrentUser() user: { id: string }, @UuidParam('id') id: string) {
    return this.trainingPlansService.getVersionById(user.id, id);
  }
}
