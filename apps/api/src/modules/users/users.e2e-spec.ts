import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { vi } from 'vitest';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtService } from '@nestjs/jwt';

const mockUser = {
  id: 'user-1',
  email: 'me@example.com',
  passwordHash: 'hash',
  createdAt: new Date(),
  updatedAt: new Date(),
  heightCm: null,
  weightKg: null,
  age: null,
  sex: null,
  trainingLevel: null,
  preferredTrainingDays: null,
  availableEquipment: null,
  trainingLocation: null,
  goals: null,
  muscleFocus: null,
};

describe('Users /me (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;

  beforeAll(async () => {
    process.env.JWT_ACCESS_SECRET = 'test-secret';
    const jwtService = new JwtService({
      secret: 'test-secret',
      signOptions: { expiresIn: '15m' },
    });
    accessToken = jwtService.sign({ userId: mockUser.id, email: mockUser.email });

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        user: {
          findUnique: vi.fn().mockResolvedValue(mockUser),
          update: vi.fn().mockResolvedValue({ ...mockUser }),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('GET /me', () => {
    it('returns 200 and user when authenticated', async () => {
      const res = await request(app.getHttpServer())
        .get('/me')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200);
      expect(res.body.id).toBe(mockUser.id);
      expect(res.body.email).toBe(mockUser.email);
    });

    it('returns 401 when no token', async () => {
      await request(app.getHttpServer()).get('/me').expect(401);
    });
  });

  describe('PUT /me/profile', () => {
    it('returns 200 and updated user', async () => {
      const res = await request(app.getHttpServer())
        .put('/me/profile')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ heightCm: 180, weightKg: 75, age: 30, sex: 'male' })
        .expect(200);
      expect(res.body.id).toBe(mockUser.id);
    });
  });

  describe('PUT /me/preferences', () => {
    it('returns 200', async () => {
      await request(app.getHttpServer())
        .put('/me/preferences')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          trainingLevel: 'intermediate',
          preferredTrainingDays: 3,
          trainingLocation: 'gym',
        })
        .expect(200);
    });
    it('returns 200 with valid availableEquipment array', async () => {
      await request(app.getHttpServer())
        .put('/me/preferences')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({ availableEquipment: ['dumbbells', 'barbell'] })
        .expect(200);
    });
  });

  describe('PUT /me/goals', () => {
    it('returns 200 with strict goals schema', async () => {
      await request(app.getHttpServer())
        .put('/me/goals')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          goals: [
            { type: 'muscle_gain', priority: 1 },
            { type: 'custom', priority: 2, customText: 'Other' },
          ],
        })
        .expect(200);
    });
  });

  describe('PUT /me/muscle-focus', () => {
    it('returns 200 with strict muscleFocus schema', async () => {
      await request(app.getHttpServer())
        .put('/me/muscle-focus')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          muscleFocus: [
            { muscleId: 'chest', priority: 'grow' },
            { muscleId: 'back', priority: 'maintain' },
          ],
        })
        .expect(200);
    });
  });
});
