import { describe, expect, it } from 'vitest';
import type { PrismaService } from '../../prisma/prisma.service';
import { prismaMock, rejectsWithCode, UID } from '../../test/unit/support';
import { NotesService, toNoteResponse } from './notes.service';

const T0 = new Date('2026-11-01T10:00:00.000Z');
const T1 = new Date('2026-11-02T10:00:00.000Z');
const note = (text: string, clientUpdatedAt: Date) => ({
  exerciseId: 'e1',
  text,
  clientUpdatedAt,
  updatedAt: clientUpdatedAt,
  exercise: { slug: 'press-banca-barra' },
});

function setup() {
  const prisma = prismaMock();
  return { prisma, service: new NotesService(prisma as unknown as PrismaService) };
}

describe('NotesService (nota fija por ejercicio, idea 2)', () => {
  it('toNoteResponse y list', async () => {
    const { prisma, service } = setup();
    prisma.userExerciseNote.findMany.mockResolvedValue([note('Agarre ancho', T0)]);
    const expected = {
      exerciseId: 'e1',
      slug: 'press-banca-barra',
      text: 'Agarre ancho',
      clientUpdatedAt: T0.toISOString(),
      updatedAt: T0.toISOString(),
    };
    expect(toNoteResponse(note('Agarre ancho', T0))).toEqual(expected);
    await expect(service.list(UID)).resolves.toEqual({ items: [expected] });
  });

  it('byExercise: sin ids no consulta; con ids devuelve el mapa', async () => {
    const { prisma, service } = setup();
    await expect(service.byExercise(UID, [])).resolves.toEqual(new Map());
    expect(prisma.userExerciseNote.findMany).not.toHaveBeenCalled();
    prisma.userExerciseNote.findMany.mockResolvedValue([{ exerciseId: 'e1', text: 'x' }]);
    await expect(service.byExercise(UID, ['e1', 'e2'])).resolves.toEqual(new Map([['e1', 'x']]));
  });

  describe('put («última escritura gana»)', () => {
    it('ejercicio inexistente o borrado → 404', async () => {
      const { prisma, service } = setup();
      prisma.exercise.findFirst.mockResolvedValue(null);
      await rejectsWithCode(service.put(UID, 'e1', { text: 'x', clientUpdatedAt: T1.toISOString() }), 'NOT_FOUND', 404);
    });

    it('una escritura más antigua (o igual) que la guardada no la pisa', async () => {
      const { prisma, service } = setup();
      prisma.exercise.findFirst.mockResolvedValue({ id: 'e1' });
      prisma.userExerciseNote.findUnique.mockResolvedValue(note('nueva', T1));
      await expect(service.put(UID, 'e1', { text: 'vieja', clientUpdatedAt: T0.toISOString() })).resolves.toMatchObject({
        text: 'nueva',
      });
      await expect(service.put(UID, 'e1', { text: 'igual', clientUpdatedAt: T1.toISOString() })).resolves.toMatchObject({
        text: 'nueva',
      });
      expect(prisma.userExerciseNote.upsert).not.toHaveBeenCalled();
      expect(prisma.$queryRaw).toHaveBeenCalled();
    });

    it('sin nota o con una más reciente → upsert', async () => {
      const { prisma, service } = setup();
      prisma.exercise.findFirst.mockResolvedValue({ id: 'e1' });
      prisma.userExerciseNote.findUnique.mockResolvedValueOnce(null).mockResolvedValueOnce(note('vieja', T0));
      prisma.userExerciseNote.upsert.mockImplementation(async ({ create }: { create: { text: string } }) =>
        note(create.text, T1),
      );
      await expect(service.put(UID, 'e1', { text: 'primera', clientUpdatedAt: T1.toISOString() })).resolves.toMatchObject({
        text: 'primera',
      });
      await expect(service.put(UID, 'e1', { text: 'nueva', clientUpdatedAt: T1.toISOString() })).resolves.toMatchObject({
        text: 'nueva',
      });
      expect(prisma.userExerciseNote.upsert).toHaveBeenCalledTimes(2);
      expect(prisma.userExerciseNote.upsert.mock.calls[1][0].update).toEqual({ text: 'nueva', clientUpdatedAt: T1 });
    });
  });

  it('remove es idempotente (deleteMany del propio usuario)', async () => {
    const { prisma, service } = setup();
    await service.remove(UID, 'e1');
    expect(prisma.userExerciseNote.deleteMany).toHaveBeenCalledWith({ where: { userId: UID, exerciseId: 'e1' } });
  });
});
