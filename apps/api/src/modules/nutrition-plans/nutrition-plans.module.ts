import { Module } from '@nestjs/common';
import { NutritionPlansController } from './nutrition-plans.controller';
import { NutritionPlansService } from './nutrition-plans.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [PrismaModule, UsersModule],
  controllers: [NutritionPlansController],
  providers: [NutritionPlansService],
  exports: [NutritionPlansService],
})
export class NutritionPlansModule {}
