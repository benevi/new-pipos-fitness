import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import type { Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { APP_ENV, type Env } from '../../config/env';
import type { AuthenticatedUser } from './authenticated-user';

export type JwtPayload = {
  userId: string;
  role: Role;
  iat?: number;
  exp?: number;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(APP_ENV) env: Env,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: env.JWT_ACCESS_SECRET,
      algorithms: ['HS256'],
    });
  }

  /**
   * El rol se lee de la base de datos (fuente de verdad), no del token: un cambio de rol
   * o el borrado del usuario se aplican sin esperar a que caduque el access token.
   */
  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.userId },
      select: { id: true, email: true, role: true },
    });
    if (!user) {
      throw new UnauthorizedException();
    }
    return { id: user.id, email: user.email, role: user.role };
  }
}
