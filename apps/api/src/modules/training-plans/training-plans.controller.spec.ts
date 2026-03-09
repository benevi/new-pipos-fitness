import { TrainingPlansController } from './training-plans.controller';
import { TrainingPlansService } from './training-plans.service';
import { vi } from 'vitest';

describe('TrainingPlansController', () => {
  let controller: TrainingPlansController;
  let service: TrainingPlansService;

  const mockResponse = {
    plan: {
      id: 'plan-1',
      userId: 'user-1',
      createdAt: '2025-01-01T00:00:00.000Z',
      currentVersionId: 'ver-1',
    },
    version: {
      id: 'ver-1',
      planId: 'plan-1',
      version: 1,
      createdAt: '2025-01-01T00:00:00.000Z',
      engineVersion: '0.0.1',
      objectiveScore: 0.8,
      sessions: [],
    },
  };

  beforeEach(async () => {
    const mockService = {
      generatePlan: vi.fn().mockResolvedValue(mockResponse),
      getCurrent: vi.fn().mockResolvedValue(mockResponse),
      getVersions: vi.fn().mockResolvedValue([{ id: 'ver-1', version: 1 }]),
      getVersionById: vi.fn().mockResolvedValue(mockResponse.version),
    };
    service = mockService as unknown as TrainingPlansService;
    controller = new TrainingPlansController(service);
  });

  it('POST generate calls service and returns plan + version', async () => {
    const out = await controller.generate({ id: 'user-1' });
    expect(service.generatePlan).toHaveBeenCalledWith('user-1');
    expect(out.plan.id).toBe('plan-1');
    expect(out.version.version).toBe(1);
  });

  it('GET current returns current plan', async () => {
    const out = await controller.getCurrent({ id: 'user-1' });
    expect(service.getCurrent).toHaveBeenCalledWith('user-1');
    expect(out.plan.currentVersionId).toBe('ver-1');
  });

  it('GET versions returns list', async () => {
    const out = await controller.getVersions({ id: 'user-1' });
    expect(service.getVersions).toHaveBeenCalledWith('user-1');
    expect(out).toHaveLength(1);
    expect(out[0].version).toBe(1);
  });

  it('GET versions/:id returns version', async () => {
    const out = await controller.getVersionById({ id: 'user-1' }, 'ver-1');
    expect(service.getVersionById).toHaveBeenCalledWith('user-1', 'ver-1');
    expect(out.id).toBe('ver-1');
  });
});
