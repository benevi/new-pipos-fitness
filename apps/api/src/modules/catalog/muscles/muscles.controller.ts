import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { MusclesService } from './muscles.service';

@ApiTags('muscles')
@Controller('muscles')
export class MusclesController {
  constructor(private readonly musclesService: MusclesService) {}

  @Get()
  @ApiOperation({ summary: 'List all muscles' })
  findAll() {
    return this.musclesService.findAll();
  }
}
