import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../users/current-user.decorator';
import { AnalyticsService } from './analytics.service';

@ApiTags('analytics')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('progress')
  @ApiOperation({ summary: 'Get user exercise progress metrics' })
  getProgress(@CurrentUser() user: { id: string }) {
    return this.analyticsService.getProgress(user.id);
  }

  @Get('volume')
  @ApiOperation({ summary: 'Get weekly training volume' })
  getVolume(@CurrentUser() user: { id: string }) {
    return this.analyticsService.getVolume(user.id);
  }
}
