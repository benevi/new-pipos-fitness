import { Module } from '@nestjs/common';
import { AnalyticsModule } from '../analytics/analytics.module';
import { CatalogModule } from '../catalog/catalog.module';
import { EngineInputService } from './engine-input.service';
import { OverridesService } from './overrides.service';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';

@Module({
  imports: [CatalogModule, AnalyticsModule],
  controllers: [PlansController],
  providers: [PlansService, EngineInputService, OverridesService],
  exports: [PlansService, EngineInputService],
})
export class PlansModule {}
