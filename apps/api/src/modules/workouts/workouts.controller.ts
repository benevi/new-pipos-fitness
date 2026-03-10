import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { ZodBody } from '../../zod/zod-body.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../users/current-user.decorator';
import { WorkoutsService } from './workouts.service';
import {
  StartWorkoutRequestSchema,
  AddExerciseToWorkoutRequestSchema,
  LogSetRequestSchema,
  FinishWorkoutRequestSchema,
} from '@pipos/contracts';

@ApiTags('workouts')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('workouts')
export class WorkoutsController {
  constructor(private readonly workoutsService: WorkoutsService) {}

  @Get('history')
  @ApiOperation({ summary: 'Get recent workout sessions' })
  getHistory(@CurrentUser() user: { id: string }) {
    return this.workoutsService.getHistory(user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a single workout session with exercises and sets' })
  getById(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.workoutsService.getById(user.id, id);
  }

  @Post('start')
  @ZodBody(StartWorkoutRequestSchema)
  @ApiOperation({ summary: 'Start a workout session' })
  start(@CurrentUser() user: { id: string }, @Body() body: { planSessionId?: string }) {
    return this.workoutsService.startSession(user.id, body.planSessionId);
  }

  @Post(':id/exercises')
  @ZodBody(AddExerciseToWorkoutRequestSchema)
  @ApiOperation({ summary: 'Add exercise to workout' })
  addExercise(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() body: { exerciseId: string },
  ) {
    return this.workoutsService.addExercise(user.id, id, body.exerciseId);
  }

  @Post(':id/exercises/:workoutExerciseId/sets')
  @ZodBody(LogSetRequestSchema)
  @ApiOperation({ summary: 'Log a set' })
  logSet(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Param('workoutExerciseId') workoutExerciseId: string,
    @Body()
    body: { weightKg?: number; reps?: number; rir?: number; completed?: boolean },
  ) {
    return this.workoutsService.logSet(user.id, id, workoutExerciseId, body);
  }

  @Post(':id/finish')
  @ZodBody(FinishWorkoutRequestSchema)
  @ApiOperation({ summary: 'Finish workout session' })
  finish(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() body: { durationMinutes?: number; notes?: string },
  ) {
    return this.workoutsService.finishSession(user.id, id, body);
  }
}
