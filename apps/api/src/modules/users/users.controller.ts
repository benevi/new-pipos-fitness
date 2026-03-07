import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { ZodBody } from '../../zod/zod-body.decorator';
import {
  UserGoalsUpdateRequestSchema,
  UserMuscleFocusUpdateRequestSchema,
  UserPreferencesUpdateRequestSchema,
  UserProfileUpdateRequestSchema,
} from '@pipos/contracts';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from './current-user.decorator';
import { UsersService } from './users.service';

@ApiTags('me')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('me')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @ApiOperation({ summary: 'Get current user' })
  getMe(@CurrentUser() user: { id: string }) {
    return this.usersService.getMe(user.id);
  }

  @Put('profile')
  @ZodBody(UserProfileUpdateRequestSchema)
  @ApiOperation({ summary: 'Update profile' })
  updateProfile(
    @CurrentUser() user: { id: string },
    @Body() body: Parameters<UsersService['updateProfile']>[1],
  ) {
    return this.usersService.updateProfile(user.id, body);
  }

  @Put('preferences')
  @ZodBody(UserPreferencesUpdateRequestSchema)
  @ApiOperation({ summary: 'Update preferences' })
  updatePreferences(
    @CurrentUser() user: { id: string },
    @Body() body: Parameters<UsersService['updatePreferences']>[1],
  ) {
    return this.usersService.updatePreferences(user.id, body);
  }

  @Put('goals')
  @ZodBody(UserGoalsUpdateRequestSchema)
  @ApiOperation({ summary: 'Update goals' })
  updateGoals(
    @CurrentUser() user: { id: string },
    @Body() body: Parameters<UsersService['updateGoals']>[1],
  ) {
    return this.usersService.updateGoals(user.id, body);
  }

  @Put('muscle-focus')
  @ZodBody(UserMuscleFocusUpdateRequestSchema)
  @ApiOperation({ summary: 'Update muscle focus' })
  updateMuscleFocus(
    @CurrentUser() user: { id: string },
    @Body() body: Parameters<UsersService['updateMuscleFocus']>[1],
  ) {
    return this.usersService.updateMuscleFocus(user.id, body);
  }
}
