# ADR-0003: Retirar el coach de IA de v1 y sustituirlo por explicabilidad del motor

**Estado**: Propuesto · **Fecha**: 2026-11-09

## Contexto
`ai-coach.service.ts` busca palabras clave (`swap`, `cambiar`, `why`) y devuelve frases fijas en español; `AI_PROVIDER_KEY` no se usa. Se anuncia como «AI-powered». Lo que el usuario necesita de verdad es entender **por qué** su plan es así, y eso el motor determinista puede explicarlo sin LLM.

## Decisión
- Eliminar el módulo `ai-coach`, la tabla `AiInteraction`, la pantalla de chat y los modelos Dart asociados.
- El motor emite `rationale[]` por plan, sesión y ejercicio, en castellano, generado a partir de reglas (ADR-0006).
- Dejar en `packages/contracts` una interfaz `AiProvider` sin implementación ni endpoint, y este ADR con el diseño futuro.

### Diseño futuro (no implementado)
1. Feature flag por usuario, desactivado por defecto.
2. Contexto mínimo: perfil sin identificadores, plan actual y últimas N series; nunca email ni id.
3. El texto del usuario va siempre en el rol de usuario, tratado como datos.
4. Salida validada con Zod (unión discriminada estricta); si no valida, respuesta segura por defecto.
5. Toda propuesta (p. ej. cambiar un ejercicio) se re-verifica contra la BD y las restricciones del motor; el LLM no escribe planes.
6. Límites por usuario y día, timeout, tope de coste mensual y registro de uso sin el texto completo.
7. Evaluación offline con un conjunto de preguntas y respuestas esperadas antes de activarlo.

## Consecuencias
- **Más fácil:** cero coste de LLM, cero superficie de prompt injection, README honesto.
- **Más difícil:** sin preguntas libres en v1.
- **Requiere confirmación:** borra un módulo y una tabla. Cubierto por «APRUEBO fase 0».

## Alternativas
- **Implementar el LLM ahora.** Contra: coste, riesgo y evaluación que no aportan al objetivo de v1. Rechazada.
- **Dejar el stub.** Contra: viola «nada falso». Rechazada.

## Revisión
- Reabrir cuando v1 tenga usuarios reales y las explicaciones deterministas no resuelvan las dudas más frecuentes.
