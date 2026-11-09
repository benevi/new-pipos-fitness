import { HttpStatus, Injectable } from '@nestjs/common';
import type { TrainingProfile } from '@prisma/client';
import { dailyTargets } from '@pipos/engine-rules';
import type { engineV2, FieldIssue, NutritionTargetsResponse, TrainingGoal } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { ageFrom, EngineInputService } from '../plans/engine-input.service';

export function nutritionGoalFor(goal: TrainingGoal): engineV2.NutritionGoal {
  if (goal === 'fat_loss') return 'fat_loss';
  if (goal === 'hypertrophy') return 'muscle_gain';
  return 'maintenance';
}

/**
 * Entrada de `dailyTargets` desde el perfil, o la lista de campos que faltan.
 * Nada se rellena por defecto (no se inventan 70 kg ni 2000 kcal).
 */
export function dailyTargetsInput(
  profile: TrainingProfile,
  healthAllowed: boolean,
  now: Date,
): { ok: true; input: engineV2.DailyTargetsInput } | { ok: false; issues: FieldIssue[] } {
  const issues: FieldIssue[] = [];
  const age = ageFrom(profile.birthYear, now, profile.timezone);
  if (profile.sex !== 'male' && profile.sex !== 'female') {
    issues.push({ path: 'sex', message: 'male or female is required (Mifflin-St Jeor)' });
  }
  if (age === null) issues.push({ path: 'birthYear', message: 'Required' });
  if (!healthAllowed) {
    issues.push({ path: 'healthConsent', message: 'Weight and height require an active health consent' });
  } else {
    if (profile.weightKg === null) issues.push({ path: 'weightKg', message: 'Required' });
    if (profile.heightCm === null) issues.push({ path: 'heightCm', message: 'Required' });
  }
  if (profile.activityLevel === null) issues.push({ path: 'activityLevel', message: 'Required' });
  if (issues.length > 0) return { ok: false, issues };
  return {
    ok: true,
    input: {
      sex: profile.sex as 'male' | 'female',
      age: age as number,
      weightKg: Number(profile.weightKg),
      heightCm: Number(profile.heightCm),
      activityLevel: profile.activityLevel as engineV2.ActivityLevel,
      goal: nutritionGoalFor(profile.goal),
      level: profile.level,
    },
  };
}

/** Objetivos diarios (ADR-0004): cálculo puro del motor; no se persisten. */
@Injectable()
export class NutritionService {
  constructor(
    private readonly engineInput: EngineInputService,
    private readonly clock: Clock,
  ) {}

  async targets(userId: string): Promise<NutritionTargetsResponse> {
    const ctx = await this.engineInput.load(userId);
    if (!ctx) throw new ApiError(HttpStatus.CONFLICT, 'PROFILE_REQUIRED', 'Complete your training profile first');
    const prepared = dailyTargetsInput(ctx.profile, ctx.consent.granted, this.clock.now());
    if (!prepared.ok) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'NUTRITION_INPUT_INCOMPLETE',
        'Profile data is missing for nutrition targets',
        prepared.issues,
      );
    }
    const result = dailyTargets(prepared.input);
    if (!result.ok) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'NUTRITION_INPUT_INCOMPLETE',
        'Profile data is out of range for nutrition targets',
        result.error.issues,
      );
    }
    return { ...result.targets, nutritionGoal: prepared.input.goal };
  }
}
