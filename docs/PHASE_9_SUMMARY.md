# Phase 9 Summary — AI Coach

## Implemented

- Added API module: `apps/api/src/modules/ai-coach`
  - `ai-coach.module.ts`
  - `ai-coach.controller.ts`
  - `ai-coach.service.ts`
  - `context-builder.ts`
  - `response-validator.ts`
- Added endpoint:
  - `POST /ai-coach/ask`
  - Request: `{ "question": "..." }`
  - Response: `{ "responseType": "explanation | answer | proposal", "content": "...", "proposal"?: ... }`

## Contracts

- Added schemas in `packages/contracts/src/schemas/ai-coach.ts`:
  - `AIQuestionRequestSchema`
  - `AIProposalSchema` (currently `exercise_swap`)
  - `AIResponseSchema`
- Exported new schemas via `packages/contracts/src/schemas/index.ts`.

## Context Builder

- Implemented trimmed context aggregation with:
  - User profile summary
  - Training plan summary
  - Nutrition plan summary
  - Progress metrics summary

## Proposal Validation

- Implemented proposal checks for `exercise_swap`:
  - Referenced exercises exist
  - `fromExerciseId` belongs to current training plan
  - Replacement equipment is available
  - Replacement respects location/movement-pattern/difficulty constraints
- Invalid proposals are rejected.

## Tests Added

- `context-builder.spec.ts`:
  - Builds trimmed context
  - Handles missing plans
- `response-validator.spec.ts`:
  - Accepts valid proposal
  - Rejects invalid exercise references
  - Rejects unavailable equipment
  - Rejects movement constraint violations
- `ai-coach.e2e-spec.ts`:
  - Auth guard behavior (`401` without token)
  - Generic Q&A behavior
  - Proposal response behavior for swap request

## Out of Scope (Not Implemented)

- UI
- notifications
- automatic plan changes
- shopping lists
- voice features
