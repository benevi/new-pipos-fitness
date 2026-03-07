import { ConflictException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import type {
  AuthResponse,
  LoginRequest,
  RegisterRequest,
} from '@pipos/contracts';
import { AuthResponseSchema } from '@pipos/contracts';
import { createHash, randomBytes } from 'crypto';
import type { User } from '@prisma/client';

const SALT_ROUNDS = 10;
const REFRESH_EXPIRES_MS = 7 * 24 * 60 * 60 * 1000; // 7 days

export const AUTH_REFRESH_REUSED = 'AUTH_REFRESH_REUSED';

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async register(input: RegisterRequest): Promise<AuthResponse> {
    const emailNormalized = normalizeEmail(input.email);
    const existing = await this.prisma.user.findUnique({
      where: { emailNormalized },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
    }
    const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);
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
    if (!user) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const valid = await bcrypt.compare(input.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }
    return this.issueTokens(user);
  }

  async refresh(refreshToken: string): Promise<AuthResponse> {
    const tokenHash = this.hashRefreshToken(refreshToken);
    const stored = await this.prisma.refreshToken.findFirst({
      where: { tokenHash },
      include: { user: true },
    });
    if (!stored || stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
    if (stored.revokedAt) {
      throw new UnauthorizedException({
        message: 'Refresh token was already used',
        code: AUTH_REFRESH_REUSED,
      });
    }
    const newTokenPlain = randomBytes(32).toString('hex');
    const newTokenHash = this.hashRefreshToken(newTokenPlain);
    const expiresAt = new Date(Date.now() + REFRESH_EXPIRES_MS);
    const newRecord = await this.prisma.refreshToken.create({
      data: {
        userId: stored.userId,
        tokenHash: newTokenHash,
        expiresAt,
      },
      select: { id: true },
    });
    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date(), replacedByTokenId: newRecord.id },
    });
    const accessToken = this.jwtService.sign(
      { userId: stored.user.id, email: stored.user.email },
      { expiresIn: process.env.JWT_ACCESS_EXPIRES ?? '15m' },
    );
    const expiresIn = 15 * 60;
    const response: AuthResponse = {
      accessToken,
      refreshToken: newTokenPlain,
      expiresIn,
      user: { id: stored.user.id, email: stored.user.email },
    };
    return AuthResponseSchema.parse(response);
  }

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hashRefreshToken(refreshToken);
    const stored = await this.prisma.refreshToken.findFirst({
      where: { tokenHash },
    });
    if (stored && !stored.revokedAt) {
      await this.prisma.refreshToken.update({
        where: { id: stored.id },
        data: { revokedAt: new Date() },
      });
    }
  }

  private async issueTokens(
    user: User,
    options?: { createdByIp?: string; userAgent?: string },
  ): Promise<AuthResponse> {
    const accessToken = this.jwtService.sign(
      { userId: user.id, email: user.email },
      { expiresIn: process.env.JWT_ACCESS_EXPIRES ?? '15m' },
    );
    const refreshToken = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + REFRESH_EXPIRES_MS);
    const tokenHash = this.hashRefreshToken(refreshToken);
    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash,
        expiresAt,
        createdByIp: options?.createdByIp,
        userAgent: options?.userAgent,
      },
    });
    const expiresIn = 15 * 60;
    const response: AuthResponse = {
      accessToken,
      refreshToken,
      expiresIn,
      user: { id: user.id, email: user.email },
    };
    return AuthResponseSchema.parse(response);
  }

  private hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
