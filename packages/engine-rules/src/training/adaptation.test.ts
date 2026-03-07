import { describe, it, expect } from 'vitest';
import { adaptPlanToProgress } from './adaptation.js';
import type { CatalogExerciseSnapshot } from '@pipos/contracts';

const catalog: Map<string, CatalogExerciseSnapshot> = new Map([
  [
    'e1',
    {
      id: 'e1',
      name: 'Squat',
      difficulty: 1,
      movementPattern: 'squat',
      place: 'gym',
      equipmentIds: [],
      muscles: [{ muscleId: 'm1', role: 'primary' }],
    },
  ],
  [
    'e2',
    {
      id: 'e2',
      name: 'Row',
      difficulty: 1,
      movementPattern: 'pull',
      place: 'gym',
      equipmentIds: [],
      muscles: [{ muscleId: 'm2', role: 'primary' }],
    },
  ],
  [
    'e3',
    {
      id: 'e3',
      name: 'Lunge',
      difficulty: 1,
      movementPattern: 'squat',
      place: 'gym',
      equipmentIds: [],
      muscles: [{ muscleId: 'm1', role: 'secondary' }],
    },
  ],
]);

const basePlan = {
  metadata: { engineVersion: '0.0.1', objectiveScore: 0.8, constraintViolations: [] },
  weekPlan: {
    sessions: [
      {
        sessionIndex: 0,
        name: 'Day 1',
        targetDurationMinutes: 45,
        exercises: [
          { exerciseId: 'e1', sets: 3, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
          { exerciseId: 'e2', sets: 4, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
          { exerciseId: 'e3', sets: 2, repRangeMin: 8, repRangeMax: 12, restSeconds: 90, rirTarget: 2 },
        ],
      },
    ],
  },
};

describe('adaptPlanToProgress', () => {
  it('returns plan unchanged when no progress', () => {
    const out = adaptPlanToProgress(basePlan, undefined, catalog);
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(3);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(4);
  });

  it('returns plan unchanged when adherence and fatigue ok', () => {
    const out = adaptPlanToProgress(
      basePlan,
      { exerciseHistory: [], adherenceScore: 0.9, fatigueScore: 0 },
      catalog,
    );
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(3);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(4);
  });

  it('reduces all sets when adherence below threshold (global)', () => {
    const out = adaptPlanToProgress(
      basePlan,
      { exerciseHistory: [], adherenceScore: 0.5 },
      catalog,
    );
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(2);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(3);
    expect(out.weekPlan.sessions[0].exercises[2].sets).toBe(1);
  });

  it('localized: reduces sets only for exercises targeting fatigued muscles', () => {
    const progress = {
      exerciseHistory: [
        { exerciseId: 'e1', estimated1RM: 100, volumeLastWeek: 1000, volumeTrend: 'stable' as const, fatigueScore: 0.6 },
      ],
      adherenceScore: 0.9,
    };
    const out = adaptPlanToProgress(basePlan, progress, catalog);
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(2);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(4);
    expect(out.weekPlan.sessions[0].exercises[2].sets).toBe(1);
  });

  it('localized: multiple fatigued exercises same muscle', () => {
    const progress = {
      exerciseHistory: [
        { exerciseId: 'e1', estimated1RM: 100, volumeLastWeek: 1000, volumeTrend: 'stable' as const, fatigueScore: 0.6 },
        { exerciseId: 'e3', estimated1RM: 50, volumeLastWeek: 500, volumeTrend: 'stable' as const, fatigueScore: 0.8 },
      ],
      adherenceScore: 0.9,
    };
    const out = adaptPlanToProgress(basePlan, progress, catalog);
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(2);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(4);
    expect(out.weekPlan.sessions[0].exercises[2].sets).toBe(1);
  });

  it('does not reduce below 1 set', () => {
    const oneSetPlan = {
      ...basePlan,
      weekPlan: {
        sessions: [
          {
            ...basePlan.weekPlan.sessions[0],
            exercises: [{ ...basePlan.weekPlan.sessions[0].exercises[0], sets: 1 }],
          },
        ],
      },
    };
    const out = adaptPlanToProgress(
      oneSetPlan,
      { exerciseHistory: [], adherenceScore: 0.5 },
      catalog,
    );
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(1);
  });

  it('fatigue with empty exerciseHistory does not reduce (no fatigued muscles identified)', () => {
    const out = adaptPlanToProgress(
      basePlan,
      { exerciseHistory: [], fatigueScore: 0.6 },
      catalog,
    );
    expect(out.weekPlan.sessions[0].exercises[0].sets).toBe(3);
    expect(out.weekPlan.sessions[0].exercises[1].sets).toBe(4);
  });
});
