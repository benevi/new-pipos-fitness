import { Body, Controller, Delete, Get, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import {
  AccountExportSchema,
  DeleteAccountRequestSchema,
  MeResponseSchema,
  type DeleteAccountRequest,
} from '@pipos/contracts';
import { Contract } from '../../common/contract';
import { THROTTLE_LIMITS } from '../../config/throttle';
import type { AuthenticatedUser } from '../auth/authenticated-user';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AccountService } from './account.service';

@Controller('me')
@UseGuards(JwtAuthGuard)
export class AccountController {
  constructor(private readonly account: AccountService) {}

  @Get()
  @Contract({ tag: 'account', summary: 'Usuario autenticado', response: MeResponseSchema })
  me(@CurrentUser() user: AuthenticatedUser) {
    return this.account.me(user.id);
  }

  @Get('export')
  @Throttle({ default: THROTTLE_LIMITS.ACCOUNT_SENSITIVE })
  @Contract({ tag: 'account', summary: 'Exportar todos mis datos (JSON, RGPD art. 15 y 20)', response: AccountExportSchema })
  export(@CurrentUser() user: AuthenticatedUser) {
    return this.account.export(user.id);
  }

  @Delete()
  @Throttle({ default: THROTTLE_LIMITS.ACCOUNT_SENSITIVE })
  @Contract({
    tag: 'account',
    summary: 'Borrar la cuenta y todos sus datos (requiere la contraseña)',
    body: DeleteAccountRequestSchema,
    response: null,
    status: 204,
    errors: [403],
  })
  async delete(@CurrentUser() user: AuthenticatedUser, @Body() body: DeleteAccountRequest): Promise<void> {
    await this.account.delete(user.id, body.password);
  }
}
