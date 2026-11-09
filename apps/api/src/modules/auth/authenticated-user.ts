import type { Role } from '@prisma/client';

/** Usuario autenticado que JwtStrategy deja en request.user. */
export interface AuthenticatedUser {
  id: string;
  email: string;
  role: Role;
}
