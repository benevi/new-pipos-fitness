import { z } from 'zod';
import { TEXT_LIMITS, utf8ByteLength } from './limits.js';

const EmailSchema = z.string().max(TEXT_LIMITS.EMAIL).email();

/** Contraseña de registro: 8–72 bytes UTF-8 (bcrypt ignora lo que pase de 72 bytes). */
export const PasswordSchema = z
  .string()
  .refine((p) => utf8ByteLength(p) >= TEXT_LIMITS.PASSWORD_MIN_BYTES, {
    message: `Password must be at least ${TEXT_LIMITS.PASSWORD_MIN_BYTES} bytes`,
  })
  .refine((p) => utf8ByteLength(p) <= TEXT_LIMITS.PASSWORD_MAX_BYTES, {
    message: `Password must be at most ${TEXT_LIMITS.PASSWORD_MAX_BYTES} bytes`,
  });

const RefreshTokenSchema = z.string().min(1).max(TEXT_LIMITS.REFRESH_TOKEN);

export const RegisterRequestSchema = z.object({
  email: EmailSchema,
  password: PasswordSchema,
});

export type RegisterRequest = z.infer<typeof RegisterRequestSchema>;

export const LoginRequestSchema = z.object({
  email: EmailSchema,
  password: z.string().min(1).max(TEXT_LIMITS.LOGIN_PASSWORD_MAX_CHARS),
});

export type LoginRequest = z.infer<typeof LoginRequestSchema>;

export const RefreshTokenRequestSchema = z.object({
  refreshToken: RefreshTokenSchema,
});

export type RefreshTokenRequest = z.infer<typeof RefreshTokenRequestSchema>;

export const LogoutRequestSchema = z.object({
  refreshToken: RefreshTokenSchema,
});

export type LogoutRequest = z.infer<typeof LogoutRequestSchema>;

export const AuthResponseSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  expiresIn: z.number(),
  user: z.object({
    id: z.string(),
    email: z.string(),
  }),
});

export type AuthResponse = z.infer<typeof AuthResponseSchema>;
