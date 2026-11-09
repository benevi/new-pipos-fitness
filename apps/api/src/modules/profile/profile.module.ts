import { Module } from '@nestjs/common';
import { CatalogModule } from '../catalog/catalog.module';
import { PlansModule } from '../plans/plans.module';
import { ConsentService } from './consent.service';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';

@Module({
  imports: [CatalogModule, PlansModule],
  controllers: [ProfileController],
  providers: [ProfileService, ConsentService],
  exports: [ProfileService],
})
export class ProfileModule {}
