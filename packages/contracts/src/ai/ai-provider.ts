/**
 * Interfaz de un futuro proveedor de IA. **Sin implementación ni endpoint en v1.**
 *
 * El coach de IA se retiró de v1 (docs/adr/0003-retirar-coach-ia.md): las explicaciones
 * las da el motor determinista (`rationale[]`). Este tipo deja fijado el contrato que
 * tendría que cumplir una implementación futura según el «Diseño futuro» del ADR-0003:
 * - Feature flag por usuario, desactivado por defecto.
 * - Contexto mínimo y sin identificadores (nunca email ni id de usuario).
 * - El texto del usuario se trata siempre como datos (rol de usuario).
 * - La salida se valida con Zod; toda propuesta se re-verifica contra la BD y el motor:
 *   el proveedor nunca escribe planes.
 * - Límites por usuario y día, timeout y tope de coste.
 */
export interface AiProviderContext {
  /** Perfil de entrenamiento sin identificadores personales. */
  readonly profile: Readonly<Record<string, unknown>>;
  /** Resumen del plan vigente (sesiones y ejercicios por slug). */
  readonly planSummary: Readonly<Record<string, unknown>>;
  /** Últimas series registradas (sin fechas absolutas ni ids). */
  readonly recentSets: ReadonlyArray<Readonly<Record<string, unknown>>>;
}

export type AiProposal =
  | { readonly kind: 'answer'; readonly text: string }
  | { readonly kind: 'swap_exercise'; readonly planExerciseId: string; readonly exerciseSlug: string; readonly reason: string };

export interface AiProviderRequest {
  readonly question: string;
  readonly context: AiProviderContext;
  readonly locale: 'es' | 'en';
  /** Presupuesto máximo de la llamada. */
  readonly timeoutMs: number;
}

export interface AiProvider {
  /** Identificador del proveedor/modelo para auditoría (sin el texto completo de la pregunta). */
  readonly id: string;
  ask(request: AiProviderRequest): Promise<AiProposal>;
}
