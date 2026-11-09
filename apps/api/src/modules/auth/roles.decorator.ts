import { SetMetadata } from '@nestjs/common';
import type { Role } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Restringe un handler/controlador a ciertos roles. Debe combinarse con
 * `@UseGuards(JwtAuthGuard, RolesGuard)` (en ese orden).
 */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
