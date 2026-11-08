import { ConflictException, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthResponse, LoginRequest, RegisterRequest } from '@pipos/contracts';
import { AuthResponseSchema } from '@pipos/contracts';
import { createHash, randomBytes } from 'crypto';
import type { User } from '@prisma/client';
import { APP_ENV, type Env } from '../../config/env';
import type { JwtPayload } from './jwt.strategy';

export const BCRYPT_COST = 12;

/**
 * Hash bcrypt (coste 12) de un valor aleatorio descartado. Se compara contra él cuando el
 * usuario no existe para que el tiempo de respuesta de login no revele si el email existe.
 */
export const DUMMY_PASSWORD_HASH = '$2b$12$59YIJW2E1c5ENsg2flI7TeXt/p1IKLv1Q9pvLZ9GuldJFzqTAONRS';

export const AUTH_REFRESH_REUSED = 'AUTH_REFRESH_REUSED';

const DAY_MS = 24 * 60 * 60 * 1000;

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

/** Señal interna: la rotación perdió la carrera (el token ya estaba revocado). */
class RefreshRotationLost extends Error {}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    @Inject(APP_ENV) private readonly env: Env,
  ) {}

  async register(input: RegisterRequest): Promise<AuthResponse> {
    const emailNormalized = normalizeEmail(input.email);
    const existing = await this.prisma.user.findUnique({
      where: { emailNormalized },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }
    const passwordHash = await bcrypt.hash(input.password, BCRYPT_COST);
    const user = await this.prisma.user.create({
      data: {
        email: input.email.trim(),
        emailNormalized,
        passwordHash,
      },
    });
    return this.issueTokens(user);
  }

  async login(input: LoginRequest): Promise<AuthResponse> {
    const emailNormalized = normalizeEmail(input.email);
    const user = await this.prisma.user.findUnique({
      where: { emailNormalized },
    });
    // Siempre se ejecuta un bcrypt.compare para igualar tiempos exista o no el usuario.
    const valid = await bcrypt.compare(input.password, user?.passwordHash ?? DUMMY_PASSWORD_HASH);
    if (!user || !valid) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.issueTokens(user);
  }

  /**
   * Rotación de refresh token atómica con detección de reutilización.
   * - Token desconocido o caducado → 401.
   * - Token ya revocado (reutilización, o carrera perdida contra otra rotación concurrente)
   *   → se revocan TODAS las sesiones activas del usuario y 401 AUTH_REFRESH_REUSED.
   */
  async refresh(refreshToken: string): Promise<AuthResponse> {
    const tokenHash = this.hashRefreshToken(refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { user: true },
    });
    if (!stored) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    if (stored.revokedAt) {
      await this.revokeAllSessionsAndThrowReuse(stored.userId);
    }
    if (stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const newTokenPlain = randomBytes(32).toString('hex');
    try {
      await this.prisma.$transaction(async (tx) => {
        const now = new Date();
        const revoked = await tx.refreshToken.updateMany({
          where: { id: stored.id, revokedAt: null },
          data: { revokedAt: now },
        });
        if (revoked.count !== 1) {
          throw new RefreshRotationLost();
        }
        const created = await tx.refreshToken.create({
          data: {
            userId: stored.userId,
            tokenHash: this.hashRefreshToken(newTokenPlain),
            expiresAt: this.refreshExpiresAt(),
          },
          select: { id: true },
        });
        await tx.refreshToken.update({
          where: { id: stored.id },
          data: { replacedByTokenId: created.id },
        });
      });
    } catch (error) {
      if (error instanceof RefreshRotationLost) {
        await this.revokeAllSessionsAndThrowReuse(stored.userId);
      }
      throw error;
    }

    return this.buildResponse(stored.user, newTokenPlain);
  }

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hashRefreshToken(refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async revokeAllSessionsAndThrowReuse(userId: string): Promise<never> {
    await this.prisma.refreshToken.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    throw new UnauthorizedException({
      message: 'Refresh token was already used',
      code: AUTH_REFRESH_REUSED,
    });
  }

  private async issueTokens(user: User): Promise<AuthResponse> {
    const refreshToken = randomBytes(32).toString('hex');
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: this.hashRefreshToken(refreshToken),
        expiresAt: this.refreshExpiresAt(),
      },
    });
    return this.buildResponse(user, refreshToken);
  }

  private buildResponse(user: User, refreshToken: string): AuthResponse {
    const payload: JwtPayload = { userId: user.id, email: user.email, role: user.role };
    const accessToken = this.jwtService.sign(payload);
    const response: AuthResponse = {
      accessToken,
      refreshToken,
      expiresIn: this.env.JWT_ACCESS_EXPIRES_IN,
      user: { id: user.id, email: user.email },
    };
    return AuthResponseSchema.parse(response);
  }

  private refreshExpiresAt(): Date {
    return new Date(Date.now() + this.env.REFRESH_TOKEN_TTL_DAYS * DAY_MS);
  }

  private hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
