import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../prisma/prisma.service';

@Injectable()
export class EquipmentService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.equipmentItem.findMany({
      orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });
  }
}
