import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ExerciseFilterQuerySchema, type ExerciseFilterQuery } from '@pipos/contracts';
import { UuidParam, ZodQuery } from '../../../zod/zod-param';
import { ExercisesService } from './exercises.service';

@ApiTags('exercises')
@Controller('exercises')
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) {}

  @Get()
  @ApiOperation({ summary: 'List exercises with filters and pagination' })
  findAll(@ZodQuery(ExerciseFilterQuerySchema) query: ExerciseFilterQuery) {
    return this.exercisesService.findAll(query);
  }

  @Get(':id/media')
  @ApiOperation({ summary: 'Get approved YouTube media for exercise' })
  getMedia(@UuidParam('id') id: string) {
    return this.exercisesService.getMedia(id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get exercise by id with muscles, variants, media' })
  findOne(@UuidParam('id') id: string) {
    return this.exercisesService.findOne(id);
  }
}
