import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class FoodsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(limit = 500, cursor?: string) {
    return this.prisma.food.findMany({
      select: { id: true, name: true },
      orderBy: { id: 'asc' },
      take: limit,
      ...(cursor
        ? { skip: 1, cursor: { id: cursor } }
        : {}),
    });
  }
}
