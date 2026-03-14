import { Test, TestingModule } from '@nestjs/testing';
import { HealthController } from './health.controller';
import { PrismaService } from '../prisma/prisma.service';

describe('HealthController', () => {
  let controller: HealthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        {
          provide: PrismaService,
          useValue: {
            $queryRaw: vi.fn().mockResolvedValue(1),
          },
        },
      ],
    }).compile();
    controller = module.get<HealthController>(HealthController);
  });

  it('returns ok for /health', () => {
    const res = controller.get();
    expect(res.status).toBe('ok');
  });
});
