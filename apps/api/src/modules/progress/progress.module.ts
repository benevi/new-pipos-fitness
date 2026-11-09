import { Module } from '@nestjs/common';
import { ProfileModule } from '../profile/profile.module';
import { ProgressController } from './progress.controller';
import { ProgressService } from './progress.service';

@Module({
  imports: [ProfileModule],
  controllers: [ProgressController],
  providers: [ProgressService],
})
export class ProgressModule {}
