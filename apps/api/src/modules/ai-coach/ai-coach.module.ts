import { Module } from '@nestjs/common';
import { AICoachController } from './ai-coach.controller';
import { AICoachService } from './ai-coach.service';
import { ContextBuilderService } from './context-builder';
import { AIResponseNormalizerService } from './ai-response-normalizer';
import { ResponseValidatorService } from './response-validator';
import { UsersModule } from '../users/users.module';
import { TrainingPlansModule } from '../training-plans/training-plans.module';
import { NutritionPlansModule } from '../nutrition-plans/nutrition-plans.module';
import { AnalyticsModule } from '../analytics/analytics.module';

@Module({
  imports: [UsersModule, TrainingPlansModule, NutritionPlansModule, AnalyticsModule],
  controllers: [AICoachController],
  providers: [AICoachService, ContextBuilderService, AIResponseNormalizerService, ResponseValidatorService],
})
export class AICoachModule {}
