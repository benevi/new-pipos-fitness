import { Module } from '@nestjs/common';
import { AnalyticsModule } from '../analytics/analytics.module';
import { CatalogModule } from '../catalog/catalog.module';
import { PlansModule } from '../plans/plans.module';
import { SessionsService } from './sessions.service';
import { WorkoutsController } from './workouts.controller';
import { WorkoutsService } from './workouts.service';

@Module({
  imports: [AnalyticsModule, CatalogModule, PlansModule],
  controllers: [WorkoutsController],
  providers: [WorkoutsService, SessionsService],
})
export class WorkoutsModule {}
