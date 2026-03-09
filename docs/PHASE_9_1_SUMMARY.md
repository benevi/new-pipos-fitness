# Phase 9.1 — AI Coach Hardening

No new product features. Safety, structure, and robustness improvements to the AI Coach layer.

## Files Modified

- `packages/contracts/src/schemas/ai-coach.ts` — Expanded proposal discriminated union, added `proposalStatus` field
- `apps/api/src/modules/ai-coach/response-validator.ts` — Returns `ValidationResult` with `proposalStatus` and `rejectionReason` (no silent failures)
- `apps/api/src/modules/ai-coach/ai-coach.service.ts` — Normalizer + validator pipeline, async audit persistence
- `apps/api/src/modules/ai-coach/ai-coach.module.ts` — Registered `AIResponseNormalizerService`
- `apps/api/src/modules/ai-coach/context-builder.ts` — Context minimization policy comments, exercise ID list cap
- `docs/ARCHITECTURE.md` — Added "AI Coach Safety Model" section

## New Files

- `apps/api/src/modules/ai-coach/ai-response-normalizer.ts` — Schema-enforced output normalization with safe fallback
- `apps/api/src/modules/ai-coach/ai-response-normalizer.spec.ts` — Tests for normalizer
- `packages/contracts/src/schemas/ai-coach.test.ts` — Tests for discriminated union + proposalStatus
- `docs/PHASE_9_1_SUMMARY.md` — This file

## Prisma Schema Changes

New model `AIInteraction`:

| Field            | Type     | Notes                                |
|------------------|----------|--------------------------------------|
| id               | String   | UUID PK                              |
| userId           | String   | FK to User                           |
| createdAt        | DateTime | Default now()                        |
| question         | String   | User question (trimmed to 2000 chars)|
| responseType     | String   | explanation / answer / proposal      |
| proposalType     | String?  | exercise_swap, etc. (nullable)       |
| proposalValid    | Boolean  | true if proposal passed validation   |
| contextSummary   | Json     | Trimmed context metadata             |
| responseSummary  | Json     | Trimmed response metadata            |

Index: `@@index([userId, createdAt])`

## Proposal Schema Changes

`AIProposalSchema` is now a discriminated union supporting:

- `exercise_swap` (implemented)
- `exercise_remove` (schema only)
- `exercise_add` (schema only)
- `nutrition_swap` (schema only)
- `volume_adjustment` (schema only)

`AIResponseSchema` now requires `proposalStatus: "valid" | "rejected"` when `responseType === "proposal"`.

## Normalization Layer

`AIResponseNormalizerService` processes raw AI output before validation:

1. Rejects null/non-object input → safe fallback
2. Requires `responseType` and non-empty `content`
3. Strips unexpected fields
4. Validates against `AIResponseSchema`
5. Falls back to: `{ responseType: "answer", content: "I'm not confident..." }`

## Audit Mechanism

Each `/ai-coach/ask` call persists an `AIInteraction` record asynchronously (fire-and-forget, never blocks API response). Stores:

- Question text (capped)
- Response type and proposal type
- Whether proposal passed validation
- Trimmed context summary (plan existence, adherence, fatigue)
- Trimmed response summary (type, status, rejection reason, content length)

Does NOT store full LLM prompt or response text.

## Example AIInteraction Record

```json
{
  "id": "uuid",
  "userId": "user-1",
  "createdAt": "2026-03-09T...",
  "question": "Can you swap an exercise?",
  "responseType": "proposal",
  "proposalType": "exercise_swap",
  "proposalValid": true,
  "contextSummary": {
    "hasTrainingPlan": true,
    "hasNutritionPlan": true,
    "adherenceScore": 0.8,
    "fatigueDetected": false
  },
  "responseSummary": {
    "responseType": "proposal",
    "proposalType": "exercise_swap",
    "proposalStatus": "valid",
    "rejectionReason": null,
    "contentLength": 72
  }
}
```

## Example Normalized AI Response

```json
{
  "responseType": "answer",
  "content": "I'm not confident about that suggestion. Please consult your plan directly."
}
```
