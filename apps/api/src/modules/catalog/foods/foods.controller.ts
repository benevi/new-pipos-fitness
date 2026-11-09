import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { FoodsListQuerySchema, type FoodsListQuery } from '@pipos/contracts';
import { ZodQuery } from '../../../zod/zod-param';
import { FoodsService } from './foods.service';

@ApiTags('foods')
@Controller('foods')
export class FoodsController {
  constructor(private readonly foodsService: FoodsService) {}

  @Get()
  @ApiOperation({ summary: 'List foods (id + name) with optional cursor pagination' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'cursor', required: false, type: String })
  findAll(@ZodQuery(FoodsListQuerySchema) query: FoodsListQuery) {
    return this.foodsService.findAll(query.limit, query.cursor);
  }
}
