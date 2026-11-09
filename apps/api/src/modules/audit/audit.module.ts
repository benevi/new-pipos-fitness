import { Global, Module } from '@nestjs/common';
import { AuditService } from './audit.service';

/** Registro de auditoría (issue #17); global porque lo usan auth, perfil, consentimiento y cuenta. */
@Global()
@Module({
  providers: [AuditService],
  exports: [AuditService],
})
export class AuditModule {}
