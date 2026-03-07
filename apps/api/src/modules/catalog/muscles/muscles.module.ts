import { Module } from '@nestjs/common';
import { MusclesController } from './muscles.controller';
import { MusclesService } from './muscles.service';

@Module({
  controllers: [MusclesController],
  providers: [MusclesService],
  exports: [MusclesService],
})
export class MusclesModule {}
