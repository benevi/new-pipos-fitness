import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class MusclesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.muscle.findMany({
      orderBy: [{ region: 'asc' }, { name: 'asc' }],
    });
  }
}
