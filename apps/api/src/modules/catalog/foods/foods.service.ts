import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class FoodsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.food.findMany({
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    });
  }
}
