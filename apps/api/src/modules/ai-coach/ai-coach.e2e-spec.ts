import request from 'supertest';
import {
  bearer,
  createTestApp,
  registerUser,
  truncateAll,
  type RegisteredUser,
  type TestContext,
} from '../../test/e2e/helpers';

/**
 * Cobertura mínima (401 + respuesta genérica): el módulo AI coach se elimina en la Fase 3.
 * Nota: el flujo de propuestas (swap) está roto en main — AIResponseNormalizer descarta
 * proposalStatus y AIResponseSchema lo exige, así que toda propuesta cae al fallback.
 * El test antiguo que lo "cubría" usaba mocks y nunca llegó a ejecutarse.
 */
describe('AI Coach (e2e, Postgres real)', () => {
  let ctx: TestContext;
  let user: RegisteredUser;
  const server = () => ctx.app.getHttpServer();

  beforeAll(async () => {
    ctx = await createTestApp();
  });

  beforeEach(async () => {
    await truncateAll(ctx.prisma);
    user = await registerUser(ctx.app, 'ai@example.com');
    await request(server())
      .put('/me/preferences')
      .set(bearer(user.accessToken))
      .send({ trainingLevel: 'intermediate', trainingLocation: 'gym', availableEquipment: [] })
      .expect(200);
  });

  afterAll(async () => {
    await ctx.app.close();
  });

  it('401 sin token', async () => {
    await request(server()).post('/ai-coach/ask').send({ question: 'help' }).expect(401);
  });

  it('responde con una respuesta genérica', async () => {
    const res = await request(server())
      .post('/ai-coach/ask')
      .set(bearer(user.accessToken))
      .send({ question: 'What can you do for me?' })
      .expect(201);
    expect(res.body.responseType).toBe('answer');
    expect(typeof res.body.content).toBe('string');
    expect(res.body.proposal).toBeUndefined();
    expect(res.body.proposalStatus).toBeUndefined();
  });

  it('400 si la pregunta supera 2000 caracteres', async () => {
    await request(server())
      .post('/ai-coach/ask')
      .set(bearer(user.accessToken))
      .send({ question: 'q'.repeat(2001) })
      .expect(400);
  });
});
