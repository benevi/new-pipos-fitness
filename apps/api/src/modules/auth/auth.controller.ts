import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ZodBody } from '../../zod/zod-body.decorator';
import {
  LoginRequestSchema,
  LogoutRequestSchema,
  RefreshTokenRequestSchema,
  RegisterRequestSchema,
} from '@pipos/contracts';
import { AuthService } from './auth.service';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @ZodBody(RegisterRequestSchema)
  @ApiOperation({ summary: 'Register a new user' })
  async register(@Body() body: { email: string; password: string }) {
    return this.authService.register(body);
  }

  @Post('login')
  @ZodBody(LoginRequestSchema)
  @ApiOperation({ summary: 'Login' })
  async login(@Body() body: { email: string; password: string }) {
    return this.authService.login(body);
  }

  @Post('refresh')
  @ZodBody(RefreshTokenRequestSchema)
  @ApiOperation({ summary: 'Refresh access token' })
  async refresh(@Body() body: { refreshToken: string }) {
    return this.authService.refresh(body.refreshToken);
  }

  @Post('logout')
  @ZodBody(LogoutRequestSchema)
  @ApiOperation({ summary: 'Revoke refresh token (logout)' })
  async logout(@Body() body: { refreshToken: string }) {
    await this.authService.logout(body.refreshToken);
    return { ok: true };
  }
}
