import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { z } from 'zod';
import {
  ExerciseNoteListResponseSchema,
  ExerciseNoteRequestSchema,
  ExerciseNoteResponseSchema,
  OkResponseSchema,
  type ExerciseNoteRequest,
  FinishWorkoutRequestSchema,
  IdSchema,
  PatchSetRequestSchema,
  SetLogResponseSchema,
  StartWorkoutRequestSchema,
  SubstituteExerciseRequestSchema,
  SubstitutesResponseSchema,
  SubstitutionResponseSchema,
  TodaySessionQuerySchema,
  TodaySessionResponseSchema,
  type TodaySessionQuery,
  UpsertSetRequestSchema,
  WorkoutResponseSchema,
  type FinishWorkoutRequest,
  type PatchSetRequest,
  type StartWorkoutRequest,
  type SubstituteExerciseRequest,
  type UpsertSet,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { IdParamsSchema } from '../catalog/catalog.controller';
import { NotesService } from './notes.service';
import { SessionsService } from './sessions.service';
import { WorkoutsService, type Upserted } from './workouts.service';

const SetParamsSchema = z.object({ id: IdSchema, clientId: IdSchema }).strict();
const SlotParamsSchema = z.object({ id: IdSchema, planExerciseId: IdSchema }).strict();

/** 201 si se creó; 200 si era un reenvío idempotente del mismo clientId. */
function created<T>(res: Response, result: Upserted<T>): T {
  res.status(result.created ? 201 : 200);
  return result.value;
}

@Controller()
@UseGuards(JwtAuthGuard)
export class WorkoutsController {
  constructor(
    private readonly workouts: WorkoutsService,
    private readonly sessions: SessionsService,
    private readonly notes: NotesService,
  ) {}

  @Get('sessions/today')
  @Contract({
    tag: 'workouts',
    summary: 'Sesión de hoy: calentamiento y prescripción con carga sugerida',
    description:
      'minutes (15-90) y mode=reduced ajustan la vista de hoy quitando ejercicios enteros de menor prioridad o una serie por ejercicio (PROGRAMACION.md §16.17). Solo lectura: no guarda nada ni crea una versión del plan.',
    query: TodaySessionQuerySchema,
    response: TodaySessionResponseSchema,
    errors: [404, 409],
  })
  today(@CurrentUser() user: AuthenticatedUser, @Query() query: TodaySessionQuery) {
    return this.sessions.today(user.id, query);
  }

  @Post('workouts')
  @Contract({
    tag: 'workouts',
    summary: 'Empezar un entrenamiento (idempotente por clientId)',
    body: StartWorkoutRequestSchema,
    response: WorkoutResponseSchema,
    status: 201,
    alternateStatuses: [200],
    errors: [404, 409],
  })
  start(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: StartWorkoutRequest,
    @Res({ passthrough: true }) res: Response,
  ) {
    return this.workouts.start(user.id, body).then((r) => created(res, r));
  }

  @Get('workouts/:id')
  @Contract({ tag: 'workouts', summary: 'Un entrenamiento con sus series', params: IdParamsSchema, response: WorkoutResponseSchema, errors: [404] })
  get(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workouts.get(user.id, id);
  }

  @Post('workouts/:id/sets')
  @Contract({
    tag: 'workouts',
    summary: 'Registrar una serie (idempotente por clientId: reenviar devuelve la existente con 200)',
    params: IdParamsSchema,
    body: UpsertSetRequestSchema,
    response: SetLogResponseSchema,
    status: 201,
    alternateStatuses: [200],
    errors: [404, 409],
  })
  addSet(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: UpsertSet,
    @Res({ passthrough: true }) res: Response,
  ) {
    return this.workouts.upsertSet(user.id, id, body).then((r) => created(res, r));
  }

  @Patch('workouts/:id/sets/:clientId')
  @Contract({
    tag: 'workouts',
    summary: 'Editar una serie (gana la última escritura por clientUpdatedAt)',
    params: SetParamsSchema,
    body: PatchSetRequestSchema,
    response: SetLogResponseSchema,
    errors: [404],
  })
  patchSet(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('clientId') clientId: string,
    @Body() body: PatchSetRequest,
  ) {
    return this.workouts.patchSet(user.id, id, clientId, body);
  }

  @Delete('workouts/:id/sets/:clientId')
  @Contract({
    tag: 'workouts',
    summary: 'Borrar una serie (borrado lógico, idempotente)',
    params: SetParamsSchema,
    response: SetLogResponseSchema,
    errors: [404],
  })
  deleteSet(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Param('clientId') clientId: string) {
    return this.workouts.deleteSet(user.id, id, clientId);
  }

  @Post('workouts/:id/finish')
  @Contract({
    tag: 'workouts',
    summary: 'Terminar el entrenamiento (409 si ya estaba terminado)',
    params: IdParamsSchema,
    body: FinishWorkoutRequestSchema,
    response: WorkoutResponseSchema,
    errors: [404, 409],
  })
  finish(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() body: FinishWorkoutRequest) {
    return this.workouts.finish(user.id, id, body);
  }

  @Post('workouts/:id/exercises/:planExerciseId/substitute')
  @Contract({
    tag: 'workouts',
    summary: 'Cambiar el ejercicio de un hueco del plan en este entrenamiento',
    params: SlotParamsSchema,
    body: SubstituteExerciseRequestSchema,
    response: SubstitutionResponseSchema,
    errors: [404, 409],
  })
  substitute(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Param('planExerciseId') planExerciseId: string,
    @Body() body: SubstituteExerciseRequest,
  ) {
    return this.workouts.substitute(user.id, id, planExerciseId, body.exerciseId);
  }

  @Get('exercises/:id/substitutes')
  @Contract({
    tag: 'workouts',
    summary: 'Tres alternativas para un ejercicio según tu perfil',
    params: IdParamsSchema,
    response: SubstitutesResponseSchema,
    errors: [404, 409],
  })
  substitutes(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.workouts.substitutesFor(user.id, id);
  }

  // ── Nota fija por ejercicio (idea 2, ADR-0013) ──

  @Get('me/exercise-notes')
  @Contract({ tag: 'workouts', summary: 'Mis notas fijas por ejercicio', response: ExerciseNoteListResponseSchema })
  listNotes(@CurrentUser() user: AuthenticatedUser) {
    return this.notes.list(user.id);
  }

  @Put('exercises/:id/note')
  @Contract({
    tag: 'workouts',
    summary: 'Guardar la nota fija de un ejercicio (gana la última escritura por clientUpdatedAt)',
    description: 'Texto libre (máx. 280). Puede contener datos personales: se exporta, se borra con la cuenta y nunca se registra en logs.',
    params: IdParamsSchema,
    body: ExerciseNoteRequestSchema,
    response: ExerciseNoteResponseSchema,
    errors: [404],
  })
  putNote(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string, @Body() body: ExerciseNoteRequest) {
    return this.notes.put(user.id, id, body);
  }

  @Delete('exercises/:id/note')
  @Contract({ tag: 'workouts', summary: 'Borrar la nota fija de un ejercicio (idempotente)', params: IdParamsSchema, response: OkResponseSchema })
  async deleteNote(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.notes.remove(user.id, id);
    return { ok: true as const };
  }
}
