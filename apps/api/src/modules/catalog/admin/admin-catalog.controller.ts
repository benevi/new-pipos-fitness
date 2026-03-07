import { Body, Controller, Param, Post, Put } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ZodBody } from '../../../zod/zod-body.decorator';
import {
  AddExerciseMediaRequestSchema,
  CreateExerciseRequestSchema,
  UpdateExerciseRequestSchema,
} from '@pipos/contracts';
import { AdminCatalogService } from './admin-catalog.service';

@ApiTags('admin')
@Controller('admin')
export class AdminCatalogController {
  constructor(private readonly adminCatalogService: AdminCatalogService) {}

  @Post('exercises')
  @ZodBody(CreateExerciseRequestSchema)
  @ApiOperation({ summary: 'Create exercise (admin)' })
  createExercise(@Body() body: Parameters<AdminCatalogService['createExercise']>[0]) {
    return this.adminCatalogService.createExercise(body);
  }

  @Put('exercises/:id')
  @ZodBody(UpdateExerciseRequestSchema)
  @ApiOperation({ summary: 'Update exercise (admin)' })
  updateExercise(
    @Param('id') id: string,
    @Body() body: Parameters<AdminCatalogService['updateExercise']>[1],
  ) {
    return this.adminCatalogService.updateExercise(id, body);
  }

  @Post('exercises/:id/media')
  @ZodBody(AddExerciseMediaRequestSchema)
  @ApiOperation({ summary: 'Add YouTube media to exercise (admin)' })
  addExerciseMedia(
    @Param('id') id: string,
    @Body() body: Parameters<AdminCatalogService['addExerciseMedia']>[1],
  ) {
    return this.adminCatalogService.addExerciseMedia(id, body);
  }

  @Put('exercise-media/:id/approve')
  @ApiOperation({ summary: 'Approve exercise media (admin)' })
  approveMedia(@Param('id') id: string) {
    return this.adminCatalogService.approveMedia(id);
  }

  @Put('exercise-media/:id/reject')
  @ApiOperation({ summary: 'Reject exercise media (admin)' })
  rejectMedia(@Param('id') id: string) {
    return this.adminCatalogService.rejectMedia(id);
  }
}
