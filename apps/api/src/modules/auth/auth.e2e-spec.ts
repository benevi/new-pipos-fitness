import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import * as bcrypt from 'bcrypt';
import { vi } from 'vitest';
import { AppModule } from '../../app.module';
import { PrismaService } from '../../prisma/prisma.service';
import { AUTH_REFRESH_REUSED } from './auth.service';

describe('Auth (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  const mockUser = {
    id: 'user-1',
    email: 'test@example.com',
    emailNormalized: 'test@example.com',
    passwordHash: '',
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

  const validStoredToken = {
    id: 'rt-1',
    userId: mockUser.id,
    expiresAt: new Date(Date.now() + 86400000),
    revokedAt: null,
    user: mockUser,
  };

  const revokedStoredToken = {
    ...validStoredToken,
    revokedAt: new Date(),
  };

  beforeAll(async () => {
    mockUser.passwordHash = await bcrypt.hash('password123', 10);
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue({
        user: {
          findUnique: vi.fn(),
          findFirst: vi.fn(),
          create: vi.fn().mockImplementation((args: { data: { email: string; emailNormalized: string } }) =>
            Promise.resolve({
              ...mockUser,
              email: args.data.email,
              emailNormalized: args.data.emailNormalized,
            }),
          ),
          update: vi.fn(),
        },
        refreshToken: {
          create: vi.fn().mockResolvedValue({ id: 'rt-new', userId: mockUser.id }),
          findFirst: vi.fn(),
          update: vi.fn().mockResolvedValue(undefined),
          delete: vi.fn().mockResolvedValue(undefined),
        },
      })
      .compile();

    app = moduleFixture.createNestApplication();
    prisma = moduleFixture.get(PrismaService);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /auth/register', () => {
    it('returns 201 and tokens', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue(null);
      const res = await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email: 'new@example.com', password: 'password123' })
        .expect(201);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body.user).toEqual({ id: mockUser.id, email: 'new@example.com' });
    });

    it('returns 409 when email exists (same emailNormalized)', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue({
        ...mockUser,
        emailNormalized: 'test@example.com',
      });
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email: 'test@example.com', password: 'password123' })
        .expect(409);
    });

    it('returns 409 when registering with different casing (duplicate)', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue({
        ...mockUser,
        emailNormalized: 'user@example.com',
      });
      await request(app.getHttpServer())
        .post('/auth/register')
        .send({ email: 'USER@Example.COM', password: 'password123' })
        .expect(409);
    });
  });

  describe('POST /auth/login', () => {
    it('returns 200 and tokens', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue(mockUser);
      const res = await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'password123' })
        .expect(200);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
    });

    it('returns 200 when login with different email casing', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue(mockUser);
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'TEST@EXAMPLE.COM', password: 'password123' })
        .expect(200);
    });

    it('returns 401 for invalid password', async () => {
      (prisma.user.findUnique as ReturnType<typeof vi.fn>).mockResolvedValue(mockUser);
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email: 'test@example.com', password: 'wrong' })
        .expect(401);
    });
  });

  describe('POST /auth/refresh', () => {
    it('returns 200 and new tokens when valid', async () => {
      (prisma.refreshToken.findFirst as ReturnType<typeof vi.fn>).mockResolvedValue(validStoredToken);
      const res = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'valid-refresh-token' })
        .expect(200);
      expect(res.body).toHaveProperty('accessToken');
      expect(res.body).toHaveProperty('refreshToken');
    });

    it('returns 401 with AUTH_REFRESH_REUSED when token reused after rotation', async () => {
      (prisma.refreshToken.findFirst as ReturnType<typeof vi.fn>)
        .mockResolvedValueOnce(validStoredToken)
        .mockResolvedValueOnce(revokedStoredToken);
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'same-token' })
        .expect(200);
      const res = await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'same-token' })
        .expect(401);
      expect(res.body?.code).toBe(AUTH_REFRESH_REUSED);
    });

    it('returns 401 for invalid refresh token', async () => {
      (prisma.refreshToken.findFirst as ReturnType<typeof vi.fn>).mockResolvedValue(null);
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'invalid' })
        .expect(401);
    });
  });

  describe('POST /auth/logout', () => {
    it('returns 200 and revokes token', async () => {
      (prisma.refreshToken.findFirst as ReturnType<typeof vi.fn>).mockResolvedValue(validStoredToken);
      await request(app.getHttpServer())
        .post('/auth/logout')
        .send({ refreshToken: 'token-to-revoke' })
        .expect(200);
      (prisma.refreshToken.findFirst as ReturnType<typeof vi.fn>).mockResolvedValue(revokedStoredToken);
      await request(app.getHttpServer())
        .post('/auth/refresh')
        .send({ refreshToken: 'token-to-revoke' })
        .expect(401);
    });
  });
});
