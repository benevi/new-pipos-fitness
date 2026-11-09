import { Module } from '@nestjs/common';
import { PlansModule } from '../plans/plans.module';
import { NutritionController } from './nutrition.controller';
import { NutritionService } from './nutrition.service';

@Module({
  imports: [PlansModule],
  controllers: [NutritionController],
  providers: [NutritionService],
})
export class NutritionModule {}
