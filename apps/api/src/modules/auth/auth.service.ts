import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes, randomUUID } from 'crypto';
import type { User } from '@prisma/client';
import type { AuthResponse, LoginRequest, RegisterRequest } from '@pipos/contracts';
import { ApiError } from '../../common/api-error';
import { Clock } from '../../common/clock';
import { APP_ENV, type Env } from '../../config/env';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import type { JwtPayload } from './jwt.strategy';

export const BCRYPT_COST = 12;

/**
 * Hash bcrypt (coste 12) de un valor aleatorio descartado. Se compara contra él cuando el
 * usuario no existe para que el tiempo de respuesta de login no revele si el email existe.
 */
export const DUMMY_PASSWORD_HASH = '$2b$12$59YIJW2E1c5ENsg2flI7TeXt/p1IKLv1Q9pvLZ9GuldJFzqTAONRS';

export const AUTH_REFRESH_REUSED = 'AUTH_REFRESH_REUSED';
export const AUTH_REFRESH_RACE = 'AUTH_REFRESH_RACE';

const DAY_MS = 24 * 60 * 60 * 1000;

export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function hashRefreshToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

interface StoredToken {
  id: string;
  userId: string;
  familyId: string;
  expiresAt: Date;
  rotatedAt: Date | null;
  revokedAt: Date | null;
  revokedReason: string | null;
}

/** Señal interna: la rotación perdió la carrera (el token ya estaba revocado). */
class RefreshRotationLost extends Error {}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly clock: Clock,
    @Inject(APP_ENV) private readonly env: Env,
    private readonly audit: AuditService,
  ) {}

  async register(input: RegisterRequest): Promise<AuthResponse> {
    const emailNormalized = normalizeEmail(input.email);
    const existing = await this.prisma.user.findUnique({ where: { emailNormalized }, select: { id: true } });
    if (existing) {
      throw new ApiError(HttpStatus.CONFLICT, 'AUTH_EMAIL_TAKEN', 'Email already registered');
    }
    const passwordHash = await bcrypt.hash(input.password, BCRYPT_COST);
    const user = await this.prisma.user.create({
      data: { email: input.email.trim(), emailNormalized, passwordHash },
    });
    return this.issueTokens(user);
  }

  async login(input: LoginRequest): Promise<AuthResponse> {
    const user = await this.prisma.user.findUnique({ where: { emailNormalized: normalizeEmail(input.email) } });
    // Siempre se ejecuta un bcrypt.compare para igualar tiempos exista o no el usuario.
    const valid = await bcrypt.compare(input.password, user?.passwordHash ?? DUMMY_PASSWORD_HASH);
    if (!user || !valid) {
      // Auditoría (issue #17): con un email desconocido no se guarda nada que lo identifique.
      await this.audit.record('login_failed', user?.id ?? null);
      throw new ApiError(HttpStatus.UNAUTHORIZED, 'AUTH_INVALID_CREDENTIALS', 'Invalid email or password');
    }
    await this.audit.record('login_succeeded', user.id);
    return this.issueTokens(user);
  }

  /** Comprueba la contraseña de un usuario autenticado (reautenticación antes de borrar la cuenta). */
  async verifyPassword(userId: string, password: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { passwordHash: true } });
    return bcrypt.compare(password, user?.passwordHash ?? DUMMY_PASSWORD_HASH).then((ok) => ok && !!user);
  }

  /**
   * Rotación de refresh token atómica con detección de reutilización:
   * - Desconocido o caducado → 401 AUTH_REFRESH_INVALID.
   * - Rotado hace menos de REFRESH_REUSE_GRACE_SECONDS → 401 AUTH_REFRESH_RACE, sin revocar nada.
   *   Cubre bien las peticiones simultáneas del mismo cliente (una gana y guarda el par nuevo; las
   *   demás usan ese par). NO recupera una respuesta perdida: solo se guarda el hash del token
   *   nuevo, así que no se puede reenviar, y el cliente que no lo recibió tendrá que volver a
   *   iniciar sesión (la familia no se revoca; el token nuevo caduca sin usarse). Limitación
   *   documentada en docs/SECURITY.md.
   * - Cualquier otra reutilización → se revocan TODAS las sesiones del usuario y
   *   401 AUTH_REFRESH_REUSED.
   */
  async refresh(refreshToken: string): Promise<AuthResponse> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: hashRefreshToken(refreshToken) },
      include: { user: true },
    });
    if (!stored) throw this.invalidRefresh();
    if (stored.revokedAt) await this.rejectReused(stored);
    if (stored.expiresAt < this.clock.now()) throw this.invalidRefresh();

    const newTokenPlain = randomBytes(32).toString('hex');
    try {
      await this.prisma.$transaction(async (tx) => {
        const now = this.clock.now();
        const revoked = await tx.refreshToken.updateMany({
          where: { id: stored.id, revokedAt: null },
          data: { revokedAt: now, rotatedAt: now, revokedReason: 'rotated' },
        });
        if (revoked.count !== 1) throw new RefreshRotationLost();
        const created = await tx.refreshToken.create({
          data: {
            userId: stored.userId,
            familyId: stored.familyId,
            tokenHash: hashRefreshToken(newTokenPlain),
            expiresAt: this.refreshExpiresAt(),
          },
          select: { id: true },
        });
        await tx.refreshToken.update({ where: { id: stored.id }, data: { replacedById: created.id } });
      });
    } catch (error) {
      if (error instanceof RefreshRotationLost) {
        const current = await this.prisma.refreshToken.findUnique({ where: { id: stored.id } });
        await this.rejectReused(current ?? { ...stored, revokedAt: this.clock.now(), rotatedAt: null });
      }
      throw error;
    }
    return this.buildResponse(stored.user, newTokenPlain);
  }

  async logout(refreshToken: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: hashRefreshToken(refreshToken), revokedAt: null },
      data: { revokedAt: this.clock.now(), revokedReason: 'logout' },
    });
  }

  /** ¿Es una carrera benigna (rotado hace menos de la ventana de gracia)? */
  isWithinGrace(token: Pick<StoredToken, 'rotatedAt' | 'revokedReason'>, now: Date): boolean {
    if (token.revokedReason !== 'rotated' || !token.rotatedAt) return false;
    return now.getTime() - token.rotatedAt.getTime() < this.env.REFRESH_REUSE_GRACE_SECONDS * 1000;
  }

  private async rejectReused(token: StoredToken): Promise<never> {
    const now = this.clock.now();
    if (this.isWithinGrace(token, now)) {
      throw new ApiError(
        HttpStatus.UNAUTHORIZED,
        AUTH_REFRESH_RACE,
        'Refresh token was just rotated; use the newest token',
      );
    }
    await this.prisma.$transaction(async (tx) => {
      await tx.refreshToken.updateMany({
        where: { userId: token.userId, revokedAt: null },
        data: { revokedAt: now, revokedReason: 'reuse_detected' },
      });
      await this.audit.record('refresh_reuse_detected', token.userId, tx);
    });
    throw new ApiError(HttpStatus.UNAUTHORIZED, AUTH_REFRESH_REUSED, 'Refresh token was already used');
  }

  private invalidRefresh(): ApiError {
    return new ApiError(HttpStatus.UNAUTHORIZED, 'AUTH_REFRESH_INVALID', 'Invalid or expired refresh token');
  }

  private async issueTokens(user: User): Promise<AuthResponse> {
    const refreshToken = randomBytes(32).toString('hex');
    const id = randomUUID();
    await this.prisma.refreshToken.create({
      data: {
        id,
        familyId: id,
        userId: user.id,
        tokenHash: hashRefreshToken(refreshToken),
        expiresAt: this.refreshExpiresAt(),
      },
    });
    return this.buildResponse(user, refreshToken);
  }

  private buildResponse(user: User, refreshToken: string): AuthResponse {
    const payload: JwtPayload = { userId: user.id, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      refreshToken,
      expiresIn: this.env.JWT_ACCESS_EXPIRES_IN,
      user: { id: user.id, email: user.email },
    };
  }

  private refreshExpiresAt(): Date {
    return new Date(this.clock.now().getTime() + this.env.REFRESH_TOKEN_TTL_DAYS * DAY_MS);
  }
}
