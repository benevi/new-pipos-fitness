import { describe, it, expect } from 'vitest';
import { RegisterRequestSchema, LoginRequestSchema, RefreshTokenRequestSchema } from './auth.js';
import { FinishWorkoutRequestSchema, AddExerciseToWorkoutRequestSchema } from './workouts.js';
import { UserGoalsUpdateRequestSchema, UserMuscleFocusUpdateRequestSchema, UserPreferencesUpdateRequestSchema } from './user.js';
import { ExerciseFilterQuerySchema, FoodsListQuerySchema, CreateExerciseRequestSchema } from './catalog.js';
import { NutritionPlanGenerateRequestSchema } from './nutrition-engine.js';
import { CatalogIdSchema, TEXT_LIMITS, UuidSchema, utf8ByteLength } from './limits.js';

const UUID = '7b0c4a4e-2d0b-4c39-9a51-0f4d2f6f2b11';

describe('PasswordSchema (registro): 8–72 bytes UTF-8', () => {
  const reg = (password: string) =>
    RegisterRequestSchema.safeParse({ email: 'a@b.com', password }).success;

  it('acepta exactamente 8 y 72 bytes ASCII', () => {
    expect(reg('a'.repeat(8))).toBe(true);
    expect(reg('a'.repeat(72))).toBe(true);
  });
  it('rechaza 7 y 73 bytes ASCII', () => {
    expect(reg('a'.repeat(7))).toBe(false);
    expect(reg('a'.repeat(73))).toBe(false);
  });
  it('cuenta bytes, no caracteres: 37 "ñ" son 74 bytes y se rechaza', () => {
    const pwd = 'ñ'.repeat(37);
    expect(pwd.length).toBe(37);
    expect(utf8ByteLength(pwd)).toBe(74);
    expect(reg(pwd)).toBe(false);
  });
  it('cuenta bytes multibyte para el mínimo: 4 "ñ" (8 bytes) se acepta', () => {
    expect(reg('ñ'.repeat(4))).toBe(true);
  });
  it('emoji de 4 bytes: 18 emojis = 72 bytes OK, 19 = 76 bytes KO', () => {
    expect(reg('💪'.repeat(18))).toBe(true);
    expect(reg('💪'.repeat(19))).toBe(false);
  });
});

describe('límites de auth', () => {
  it('email demasiado largo se rechaza', () => {
    const email = `${'a'.repeat(250)}@b.com`;
    expect(RegisterRequestSchema.safeParse({ email, password: 'password123' }).success).toBe(false);
  });
  it('login acota la contraseña', () => {
    expect(
      LoginRequestSchema.safeParse({
        email: 'a@b.com',
        password: 'x'.repeat(TEXT_LIMITS.LOGIN_PASSWORD_MAX_CHARS + 1),
      }).success,
    ).toBe(false);
  });
  it('refresh token acotado', () => {
    expect(
      RefreshTokenRequestSchema.safeParse({ refreshToken: 'x'.repeat(TEXT_LIMITS.REFRESH_TOKEN + 1) })
        .success,
    ).toBe(false);
  });
});

describe('workouts', () => {
  it('notes hasta 1000 caracteres', () => {
    expect(FinishWorkoutRequestSchema.safeParse({ notes: 'n'.repeat(1000) }).success).toBe(true);
    expect(FinishWorkoutRequestSchema.safeParse({ notes: 'n'.repeat(1001) }).success).toBe(false);
  });
  it('exerciseId debe ser UUID', () => {
    expect(AddExerciseToWorkoutRequestSchema.safeParse({ exerciseId: UUID }).success).toBe(true);
    expect(AddExerciseToWorkoutRequestSchema.safeParse({ exerciseId: 'not-a-uuid' }).success).toBe(false);
  });
});

describe('user', () => {
  it('customText acotado', () => {
    const goals = (customText: string) => ({ goals: [{ type: 'custom', priority: 1, customText }] });
    expect(UserGoalsUpdateRequestSchema.safeParse(goals('c'.repeat(200))).success).toBe(true);
    expect(UserGoalsUpdateRequestSchema.safeParse(goals('c'.repeat(201))).success).toBe(false);
  });
  it('muscleId y equipment con forma de id de catálogo', () => {
    expect(
      UserMuscleFocusUpdateRequestSchema.safeParse({
        muscleFocus: [{ muscleId: 'x'.repeat(65), priority: 'grow' }],
      }).success,
    ).toBe(false);
    expect(
      UserPreferencesUpdateRequestSchema.safeParse({ availableEquipment: ['eq-barbell', '<script>'] })
        .success,
    ).toBe(false);
  });
});

describe('catalog', () => {
  it('search hasta 100 caracteres', () => {
    expect(ExerciseFilterQuerySchema.safeParse({ search: 's'.repeat(100) }).success).toBe(true);
    expect(ExerciseFilterQuerySchema.safeParse({ search: 's'.repeat(101) }).success).toBe(false);
  });
  it('nombres del catálogo acotados', () => {
    expect(
      CreateExerciseRequestSchema.safeParse({
        slug: 'ok',
        name: 'n'.repeat(TEXT_LIMITS.NAME + 1),
        difficulty: 1,
        place: 'home',
      }).success,
    ).toBe(false);
  });
  it('foods: limit por defecto 500 y acotado a [1, 1000]', () => {
    expect(FoodsListQuerySchema.parse({})).toEqual({ limit: 500 });
    expect(FoodsListQuerySchema.parse({ limit: '10', cursor: 'food-rice' })).toEqual({
      limit: 10,
      cursor: 'food-rice',
    });
    expect(FoodsListQuerySchema.safeParse({ limit: '0' }).success).toBe(false);
    expect(FoodsListQuerySchema.safeParse({ limit: '1001' }).success).toBe(false);
    expect(FoodsListQuerySchema.safeParse({ limit: 'abc' }).success).toBe(false);
    expect(FoodsListQuerySchema.safeParse({ cursor: "'; drop table" }).success).toBe(false);
  });
});

describe('nutrition generate', () => {
  it('acepta cuerpo vacío y objetivos válidos', () => {
    expect(NutritionPlanGenerateRequestSchema.safeParse({}).success).toBe(true);
    for (const goal of ['lose_fat', 'build_muscle', 'maintain']) {
      expect(NutritionPlanGenerateRequestSchema.safeParse({ goal }).success).toBe(true);
    }
  });
  it('rechaza objetivos desconocidos y campos extra', () => {
    expect(NutritionPlanGenerateRequestSchema.safeParse({ goal: 'bulk' }).success).toBe(false);
    expect(NutritionPlanGenerateRequestSchema.safeParse({ goal: 'maintain', x: 1 }).success).toBe(false);
  });
});

describe('ids', () => {
  it('UuidSchema', () => {
    expect(UuidSchema.safeParse(UUID).success).toBe(true);
    expect(UuidSchema.safeParse('ex1').success).toBe(false);
  });
  it('CatalogIdSchema', () => {
    expect(CatalogIdSchema.safeParse('muscle-chest').success).toBe(true);
    expect(CatalogIdSchema.safeParse(UUID).success).toBe(true);
    expect(CatalogIdSchema.safeParse('').success).toBe(false);
    expect(CatalogIdSchema.safeParse('a b').success).toBe(false);
  });
});
