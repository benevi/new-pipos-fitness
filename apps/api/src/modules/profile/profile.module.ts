import { Module } from '@nestjs/common';
import { AnalyticsModule } from '../analytics/analytics.module';
import { CatalogModule } from '../catalog/catalog.module';
import { PlansModule } from '../plans/plans.module';
import { ConsentService } from './consent.service';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';
import { ScheduleService } from './schedule.service';

@Module({
  imports: [AnalyticsModule, CatalogModule, PlansModule],
  controllers: [ProfileController],
  providers: [ProfileService, ConsentService, ScheduleService],
  exports: [ProfileService],
})
export class ProfileModule {}
