import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { EquipmentService } from './equipment.service';

@ApiTags('equipment')
@Controller('equipment-items')
export class EquipmentController {
  constructor(private readonly equipmentService: EquipmentService) {}

  @Get()
  @ApiOperation({ summary: 'List all equipment items' })
  findAll() {
    return this.equipmentService.findAll();
  }
}
