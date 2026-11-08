import { SetMetadata } from '@nestjs/common';
import type { UserRole } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Restringe un handler/controlador a ciertos roles. Debe combinarse con
 * `@UseGuards(JwtAuthGuard, RolesGuard)` (en ese orden).
 */
export const Roles = (...roles: UserRole[]) => SetMetadata(ROLES_KEY, roles);
