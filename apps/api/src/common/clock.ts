import { Injectable } from '@nestjs/common';

/** Reloj del servidor inyectable (los tests pueden fijar la hora sin tocar Prisma). */
@Injectable()
export class Clock {
  now(): Date {
    return new Date();
  }
}
