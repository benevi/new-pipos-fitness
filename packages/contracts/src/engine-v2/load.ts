import { z } from 'zod';

/**
 * Desglose de discos de una barra (PROGRAMACION.md §16.16). Lo calcula `plateBreakdown` del
 * motor; el móvil puede replicarlo sin conexión con la misma regla (algoritmo voraz).
 */
export const PlateBreakdownSchema = z
  .object({
    /** Peso de la barra vacía (kg). */
    barKg: z.number().min(0),
    /** Discos por lado, de mayor a menor (kg). */
    perSide: z.array(z.number().gt(0)),
    /** Kg totales que no se pueden formar con los discos disponibles (0 = cuadra exacto). */
    remainderKg: z.number().min(0),
  })
  .strict();
export type PlateBreakdown = z.infer<typeof PlateBreakdownSchema>;
