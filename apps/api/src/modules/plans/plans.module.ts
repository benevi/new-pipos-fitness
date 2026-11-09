import { Module } from '@nestjs/common';
import { CatalogModule } from '../catalog/catalog.module';
import { EngineInputService } from './engine-input.service';
import { PlansController } from './plans.controller';
import { PlansService } from './plans.service';

@Module({
  imports: [CatalogModule],
  controllers: [PlansController],
  providers: [PlansService, EngineInputService],
  exports: [PlansService, EngineInputService],
})
export class PlansModule {}
