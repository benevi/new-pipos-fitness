import { Injectable } from '@nestjs/common';
import type { AIResponse, AIExerciseSwapProposal, AIProposalStatus } from '@pipos/contracts';
import { PrismaService } from '../../prisma/prisma.service';
import type { AICoachContext } from './context-builder';

export type ValidationResult = {
  response: AIResponse;
  proposalStatus: AIProposalStatus | undefined;
  rejectionReason: string | undefined;
};

@Injectable()
export class ResponseValidatorService {
  constructor(private readonly prisma: PrismaService) {}

  async validate(response: AIResponse, context: AICoachContext): Promise<ValidationResult> {
    if (response.responseType !== 'proposal' || !response.proposal) {
      return { response, proposalStatus: undefined, rejectionReason: undefined };
    }

    if (response.proposal.type === 'exercise_swap') {
      return this.validateExerciseSwap(response, response.proposal, context);
    }

    return {
      response: { ...response, proposalStatus: 'rejected' },
      proposalStatus: 'rejected',
      rejectionReason: 'Unsupported proposal type',
    };
  }

  private async validateExerciseSwap(
    response: AIResponse,
    proposal: AIExerciseSwapProposal,
    context: AICoachContext,
  ): Promise<ValidationResult> {
    const reject = (reason: string): ValidationResult => ({
      response: { ...response, proposalStatus: 'rejected' },
      proposalStatus: 'rejected',
      rejectionReason: reason,
    });

    if (!context.trainingPlanSummary) {
      return reject('No training plan available');
    }

    if (!context.trainingPlanSummary.exerciseIds.includes(proposal.fromExerciseId)) {
      return reject('fromExerciseId is not in current plan');
    }

    const exercises = await this.prisma.exercise.findMany({
      where: { id: { in: [proposal.fromExerciseId, proposal.toExerciseId] } },
      include: { equipment: true },
    });
    if (exercises.length !== 2) {
      return reject('Referenced exercise does not exist');
    }

    const fromExercise = exercises.find((e) => e.id === proposal.fromExerciseId);
    const toExercise = exercises.find((e) => e.id === proposal.toExerciseId);
    if (!fromExercise || !toExercise) {
      return reject('Referenced exercise does not exist');
    }

    const requiredEquipment = toExercise.equipment.map((item) => item.equipmentItemId);
    if (!requiredEquipment.every((id) => context.profile.availableEquipmentIds.includes(id))) {
      return reject('Equipment not available for replacement');
    }

    if (context.profile.trainingLocation && toExercise.place !== context.profile.trainingLocation) {
      return reject('Replacement does not match training location');
    }

    if (fromExercise.movementPattern && toExercise.movementPattern !== fromExercise.movementPattern) {
      return reject('Replacement breaks movement-pattern constraints');
    }

    if (toExercise.difficulty > fromExercise.difficulty + 1) {
      return reject('Replacement breaks difficulty constraints');
    }

    return {
      response: { ...response, proposalStatus: 'valid' },
      proposalStatus: 'valid',
      rejectionReason: undefined,
    };
  }
}
