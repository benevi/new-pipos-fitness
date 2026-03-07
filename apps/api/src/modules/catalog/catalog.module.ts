import { Module } from '@nestjs/common';
import { AdminCatalogModule } from './admin/admin-catalog.module';
import { EquipmentModule } from './equipment/equipment.module';
import { ExercisesModule } from './exercises/exercises.module';
import { MusclesModule } from './muscles/muscles.module';

@Module({
  imports: [MusclesModule, EquipmentModule, ExercisesModule, AdminCatalogModule],
})
export class CatalogModule {}
