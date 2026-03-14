import { Injectable } from '@nestjs/common';
import type { AIResponse } from '@pipos/contracts';
import { TrainingLocation } from '@pipos/contracts';
import { PrismaService } from '../../prisma/prisma.service';
import { ContextBuilderService, type AICoachContext } from './context-builder';
import { AIResponseNormalizerService } from './ai-response-normalizer';
import { ResponseValidatorService } from './response-validator';

@Injectable()
export class AICoachService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly contextBuilder: ContextBuilderService,
    private readonly normalizer: AIResponseNormalizerService,
    private readonly responseValidator: ResponseValidatorService,
  ) {}

  async ask(userId: string, question: string): Promise<AIResponse> {
    const context = await this.contextBuilder.build(userId);
    const rawResponse = await this.generateResponse(question, context);
    const normalized = this.normalizer.normalize(rawResponse);
    const { response, proposalStatus, rejectionReason } =
      await this.responseValidator.validate(normalized, context);

    this.persistInteraction(userId, question, response, proposalStatus === 'valid', context, rejectionReason).catch(
      () => {},
    );
    return response;
  }

  private async persistInteraction(
    userId: string,
    question: string,
    response: AIResponse,
    proposalValid: boolean,
    context: AICoachContext,
    rejectionReason: string | undefined,
  ): Promise<void> {
    await this.prisma.aIInteraction.create({
      data: {
        userId,
        question: question.slice(0, 2000),
        responseType: response.responseType,
        proposalType: response.proposal?.type ?? null,
        proposalValid,
        contextSummary: {
          hasTrainingPlan: context.trainingPlanSummary !== null,
          hasNutritionPlan: context.nutritionPlanSummary !== null,
          adherenceScore: context.progressMetrics.adherenceScore,
          fatigueDetected: context.progressMetrics.fatigueDetected,
        },
        responseSummary: {
          responseType: response.responseType,
          proposalType: response.proposal?.type ?? null,
          proposalStatus: response.proposalStatus ?? null,
          rejectionReason: rejectionReason ?? null,
          contentLength: response.content.length,
        },
      },
    });
  }

  private async generateResponse(
    question: string,
    context: AICoachContext,
  ): Promise<AIResponse> {
    const lowerQuestion = question.toLowerCase();
    const wantsSwap =
      lowerQuestion.includes('swap') ||
      lowerQuestion.includes('replace') ||
      lowerQuestion.includes('cambiar') ||
      lowerQuestion.includes('reemplazar');

    if (wantsSwap && context.trainingPlanSummary) {
      const proposal = await this.buildExerciseSwapProposal(context);
      if (proposal) {
        return {
          responseType: 'proposal',
          content: 'Propuesta validada de cambio de ejercicio compatible con tu plan actual.',
          proposal,
          proposalStatus: 'valid',
        };
      }
    }

    if (lowerQuestion.includes('why') || lowerQuestion.includes('por qué')) {
      return {
        responseType: 'explanation',
        content:
          'Tu recomendación actual combina contexto de perfil, resumen de planes y métricas recientes de progreso para mantener consistencia con tus restricciones.',
      };
    }

    return {
      responseType: 'answer',
      content:
        'Puedo responder preguntas sobre tu plan actual y generar propuestas estructuradas cuando sean compatibles con tus restricciones.',
    };
  }

  private async buildExerciseSwapProposal(
    context: AICoachContext,
  ): Promise<AIResponse['proposal'] | undefined> {
    const fromExerciseId = context.trainingPlanSummary?.exerciseIds[0];
    if (!fromExerciseId) return undefined;

    const fromExercise = await this.prisma.exercise.findUnique({
      where: { id: fromExerciseId },
    });
    if (!fromExercise) return undefined;

    const availableEquipment = context.profile.availableEquipmentIds;
    const candidates = await this.prisma.exercise.findMany({
      where: {
        id: { not: fromExercise.id },
        movementPattern: fromExercise.movementPattern ?? undefined,
        place: (context.profile.trainingLocation as TrainingLocation) ?? undefined,
      },
      include: { equipment: true },
      orderBy: { id: 'asc' },
      take: 20,
    });

    const compatible = candidates.find((candidate) =>
      candidate.equipment.every((item: { equipmentItemId: string }) =>
        availableEquipment.includes(item.equipmentItemId),
      ),
    );
    if (!compatible) return undefined;

    return {
      type: 'exercise_swap',
      fromExerciseId: fromExercise.id,
      toExerciseId: compatible.id,
    };
  }
}
