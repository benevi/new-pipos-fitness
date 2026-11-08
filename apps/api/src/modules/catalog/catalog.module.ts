import { Module } from '@nestjs/common';
import { EquipmentModule } from './equipment/equipment.module';
import { ExercisesModule } from './exercises/exercises.module';
import { FoodsModule } from './foods/foods.module';
import { MusclesModule } from './muscles/muscles.module';

/**
 * Catálogo de sólo lectura. Su contenido es un seed revisado en git (ADR-0005):
 * no hay endpoints de escritura/administración expuestos por la API.
 */
@Module({
  imports: [MusclesModule, EquipmentModule, ExercisesModule, FoodsModule],
})
export class CatalogModule {}
