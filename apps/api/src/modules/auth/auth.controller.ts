import { Body, Controller, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  AuthResponseSchema,
  LoginRequestSchema,
  LogoutRequestSchema,
  OkResponseSchema,
  RefreshTokenRequestSchema,
  RegisterRequestSchema,
  type LoginRequest,
  type LogoutRequest,
  type OkResponse,
  type RefreshTokenRequest,
  type RegisterRequest,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import { THROTTLE_LIMITS } from '../../config/throttle';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: THROTTLE_LIMITS.AUTH_CREDENTIALS })
  @Contract({
    tag: 'auth',
    summary: 'Registrar usuario',
    auth: false,
    body: RegisterRequestSchema,
    response: AuthResponseSchema,
    status: 201,
    errors: [409],
  })
  register(@Body() body: RegisterRequest) {
    return this.authService.register(body);
  }

  @Post('login')
  @Throttle({ default: THROTTLE_LIMITS.AUTH_CREDENTIALS })
  @Contract({ tag: 'auth', summary: 'Iniciar sesión', auth: false, body: LoginRequestSchema, response: AuthResponseSchema })
  login(@Body() body: LoginRequest) {
    return this.authService.login(body);
  }

  @Post('refresh')
  @Throttle({ default: THROTTLE_LIMITS.AUTH_REFRESH })
  @Contract({
    tag: 'auth',
    summary: 'Rotar el refresh token',
    description:
      '401 AUTH_REFRESH_RACE si el token se rotó hace menos de REFRESH_REUSE_GRACE_SECONDS (no revoca nada); ' +
      '401 AUTH_REFRESH_REUSED si es una reutilización (revoca todas las sesiones).',
    auth: false,
    body: RefreshTokenRequestSchema,
    response: AuthResponseSchema,
  })
  refresh(@Body() body: RefreshTokenRequest) {
    return this.authService.refresh(body.refreshToken);
  }

  @Post('logout')
  @Throttle({ default: THROTTLE_LIMITS.AUTH_REFRESH })
  @Contract({ tag: 'auth', summary: 'Revocar el refresh token', auth: false, body: LogoutRequestSchema, response: OkResponseSchema })
  async logout(@Body() body: LogoutRequest): Promise<OkResponse> {
    await this.authService.logout(body.refreshToken);
    return { ok: true };
  }
}
