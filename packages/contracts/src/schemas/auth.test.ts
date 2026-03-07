import { describe, it, expect } from 'vitest';
import {
  RegisterRequestSchema,
  LoginRequestSchema,
  RefreshTokenRequestSchema,
  AuthResponseSchema,
} from './auth.js';

describe('RegisterRequestSchema', () => {
  it('accepts valid input', () => {
    expect(
      RegisterRequestSchema.safeParse({ email: 'a@b.com', password: 'password123' }).success,
    ).toBe(true);
  });
  it('rejects short password', () => {
    expect(RegisterRequestSchema.safeParse({ email: 'a@b.com', password: 'short' }).success).toBe(
      false,
    );
  });
});

describe('LoginRequestSchema', () => {
  it('accepts valid input', () => {
    expect(LoginRequestSchema.safeParse({ email: 'a@b.com', password: 'x' }).success).toBe(true);
  });
});

describe('RefreshTokenRequestSchema', () => {
  it('accepts non-empty refreshToken', () => {
    expect(RefreshTokenRequestSchema.safeParse({ refreshToken: 'abc' }).success).toBe(true);
  });
});

describe('AuthResponseSchema', () => {
  it('accepts valid auth response', () => {
    const result = AuthResponseSchema.safeParse({
      accessToken: 'at',
      refreshToken: 'rt',
      expiresIn: 900,
      user: { id: 'u1', email: 'a@b.com' },
    });
    expect(result.success).toBe(true);
  });
});
