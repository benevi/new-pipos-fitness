import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ExerciseFilterQuerySchema } from '@pipos/contracts';
import { ExercisesService } from './exercises.service';

@ApiTags('exercises')
@Controller('exercises')
export class ExercisesController {
  constructor(private readonly exercisesService: ExercisesService) {}

  @Get()
  @ApiOperation({ summary: 'List exercises with filters and pagination' })
  findAll(@Query() query: unknown) {
    const parsed = ExerciseFilterQuerySchema.parse(query);
    return this.exercisesService.findAll(parsed);
  }

  @Get(':id/media')
  @ApiOperation({ summary: 'Get approved YouTube media for exercise' })
  getMedia(@Param('id') id: string) {
    return this.exercisesService.getMedia(id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get exercise by id with muscles, variants, media' })
  findOne(@Param('id') id: string) {
    return this.exercisesService.findOne(id);
  }
}
