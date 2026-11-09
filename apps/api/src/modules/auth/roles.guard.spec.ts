import { describe, it, expect } from 'vitest';
import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { Roles } from './roles.decorator';
import { RolesGuard } from './roles.guard';
import type { AuthenticatedUser } from './authenticated-user';

class OpenController {
  handler() {}
}

class AdminHandlerController {
  @Roles(Role.admin)
  handler() {}
}

@Roles(Role.admin)
class AdminClassController {
  handler() {}

  @Roles(Role.user, Role.admin)
  relaxed() {}
}

function contextFor(
  cls: new () => object,
  method: string,
  user?: AuthenticatedUser,
): ExecutionContext {
  const instance = new cls() as Record<string, () => void>;
  return {
    getHandler: () => instance[method],
    getClass: () => cls,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  } as unknown as ExecutionContext;
}

const admin: AuthenticatedUser = { id: 'a', email: 'a@x.com', role: Role.admin };
const user: AuthenticatedUser = { id: 'u', email: 'u@x.com', role: Role.user };

describe('RolesGuard', () => {
  const guard = new RolesGuard(new Reflector());

  it('permite si el handler no declara roles', () => {
    expect(guard.canActivate(contextFor(OpenController, 'handler', user))).toBe(true);
  });

  it('permite a ADMIN en un handler @Roles(ADMIN)', () => {
    expect(guard.canActivate(contextFor(AdminHandlerController, 'handler', admin))).toBe(true);
  });

  it('rechaza con 403 a USER en un handler @Roles(ADMIN)', () => {
    expect(() => guard.canActivate(contextFor(AdminHandlerController, 'handler', user))).toThrow(
      ForbiddenException,
    );
  });

  it('rechaza con 401 si no hay usuario autenticado', () => {
    expect(() => guard.canActivate(contextFor(AdminHandlerController, 'handler'))).toThrow(
      UnauthorizedException,
    );
  });

  it('aplica @Roles a nivel de clase', () => {
    expect(() => guard.canActivate(contextFor(AdminClassController, 'handler', user))).toThrow(
      ForbiddenException,
    );
    expect(guard.canActivate(contextFor(AdminClassController, 'handler', admin))).toBe(true);
  });

  it('el @Roles del handler prevalece sobre el de la clase', () => {
    expect(guard.canActivate(contextFor(AdminClassController, 'relaxed', user))).toBe(true);
  });
});
