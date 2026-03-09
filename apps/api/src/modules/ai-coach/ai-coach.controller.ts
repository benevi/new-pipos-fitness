import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AIQuestionRequestSchema } from '@pipos/contracts';
import { ZodBody } from '../../zod/zod-body.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../users/current-user.decorator';
import { AICoachService } from './ai-coach.service';

@ApiTags('ai-coach')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('ai-coach')
export class AICoachController {
  constructor(private readonly aiCoachService: AICoachService) {}

  @Post('ask')
  @ZodBody(AIQuestionRequestSchema)
  @ApiOperation({ summary: 'Ask AI coach' })
  ask(
    @CurrentUser() user: { id: string },
    @Body() body: { question: string },
  ) {
    return this.aiCoachService.ask(user.id, body.question);
  }
}
