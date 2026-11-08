import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ZodBody } from '../../zod/zod-body.decorator';
import {
  LoginRequestSchema,
  LogoutRequestSchema,
  RefreshTokenRequestSchema,
  RegisterRequestSchema,
} from '@pipos/contracts';
import { THROTTLE_LIMITS } from '../../config/throttle';
import { AuthService } from './auth.service';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: THROTTLE_LIMITS.AUTH_CREDENTIALS })
  @ZodBody(RegisterRequestSchema)
  @ApiOperation({ summary: 'Register a new user' })
  async register(@Body() body: { email: string; password: string }) {
    return this.authService.register(body);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: THROTTLE_LIMITS.AUTH_CREDENTIALS })
  @ZodBody(LoginRequestSchema)
  @ApiOperation({ summary: 'Login' })
  async login(@Body() body: { email: string; password: string }) {
    return this.authService.login(body);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: THROTTLE_LIMITS.AUTH_REFRESH })
  @ZodBody(RefreshTokenRequestSchema)
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() body: { refreshToken: string }) {
    return this.authService.refresh(body.refreshToken);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: THROTTLE_LIMITS.AUTH_REFRESH })
  @ZodBody(LogoutRequestSchema)
  @ApiOperation({ summary: 'Revoke refresh token (logout)' })
  async logout(@Body() body: { refreshToken: string }) {
    await this.authService.logout(body.refreshToken);
    return { ok: true };
  }
}
