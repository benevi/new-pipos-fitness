# Phase 14.1 — AI Coach UX Hardening

## Summary

UX improvements for AI Coach: rejection reason in proposal cards, session-level conversation persistence across tab navigation, robust auto-scroll, retry for failed send without duplicating messages, and logout clearing conversation. No new product features; backend response shape extended additively with optional `rejectionReason`.

## Files Created

- `docs/PHASE_14_1_SUMMARY.md` (this file)

## Files Modified

### Backend

- **packages/contracts/src/schemas/ai-coach.ts** — Added optional `rejectionReason: z.string().optional()` to `AIResponseSchema`. Additive; existing responses remain valid.
- **apps/api/src/modules/ai-coach/ai-coach.service.ts** — When validator returns `rejectionReason`, the service includes it in the returned response: `return { ...response, rejectionReason }` for rejected proposals.

### Mobile

- **apps/mobile/lib/models/ai_response.dart** — Added optional `rejectionReason`; regenerated freezed/json.
- **apps/mobile/lib/features/ai_coach/ai_chat_message.dart** — Added optional `rejectionReason`.
- **apps/mobile/lib/features/ai_coach/ai_coach_state.dart** — Added `lastFailedQuestion` for retry without duplicating the user message.
- **apps/mobile/lib/features/ai_coach/ai_coach_provider.dart** — `ref.keepAlive()` in `build()` for session persistence; `lastFailedQuestion` set on send failure; `retryLastQuestion()` and `_sendQuestionInternal()`; pass `rejectionReason` into assistant messages; `clearError()` clears `lastFailedQuestion`.
- **apps/mobile/lib/features/ai_coach/ai_coach_screen.dart** — Error bar: `canRetry`, `onDismiss`, `onRetry`; show Retry when `lastFailedQuestion != null`; pass `rejectionReason` to `AiProposalCard`; comment on auto-scroll.
- **apps/mobile/lib/features/ai_coach/widgets/ai_proposal_card.dart** — Optional `rejectionReason`; when rejected and reason present, show short text below status badge.
- **apps/mobile/lib/features/auth/auth_provider.dart** — Invalidate `aiCoachProvider` in `_invalidateProtectedProviders()` so logout clears conversation.

### Tests

- **apps/mobile/test/features/ai_coach/ai_chat_message_test.dart** — Test `rejectionReason` on message.
- **apps/mobile/test/features/ai_coach/ai_coach_state_test.dart** — Test `lastFailedQuestion`.
- **apps/mobile/test/features/ai_coach/ai_coach_provider_test.dart** — Retry without duplicating message; invalidate clears conversation.
- **apps/mobile/test/features/ai_coach/ai_proposal_card_test.dart** — Rejection reason when present; no crash when null.

## Backend Response Shape

- **Additive only.** Existing `AIResponse` fields unchanged.
- **New optional field:** `rejectionReason?: string` — Present when `proposalStatus === 'rejected'`; human-readable reason from the validator. If absent, mobile shows rejected status only.

## Conversation Persistence Strategy

- **Provider:** `NotifierProvider<AICoachNotifier, AIConversationState>` with `ref.keepAlive()` in `build()`. The provider is kept alive for the app session so tab switches do not dispose it; conversation survives navigation.
- **Clear on logout:** `auth_provider._invalidateProtectedProviders()` invalidates `aiCoachProvider`. On next read the provider rebuilds to initial empty state. Same path runs on user logout and on forced logout (session expired).

## Rejection Reason Rendering

- When `responseType === 'proposal'` and `proposalStatus === 'rejected'`, the proposal card shows the status badge and, when present and non-empty, the `rejectionReason` text below the type/status row. If `rejectionReason` is missing, only the "Rejected" badge is shown; no crash.

## Retry UX

- On send failure the user message remains in the list; `error` and `lastFailedQuestion` are set. Error bar shows message, **Retry** (when `lastFailedQuestion != null`), and **Dismiss**.
- **Retry:** Calls `retryLastQuestion()`, which resends the last failed question via `_sendQuestionInternal(question)` without adding a new user message. On success an assistant message is appended; on failure error and `lastFailedQuestion` are set again.
- **Dismiss:** Clears `error` and `lastFailedQuestion`; error bar hides.

## Auto-Scroll Strategy

- `_scrollToBottom()` is called when message count or `sending` changes (via `ref.listen`). It uses `WidgetsBinding.instance.addPostFrameCallback` so the list has laid out new items, then animates to `maxScrollExtent`. Guard `if (!_scrollController.hasClients) return` avoids exceptions when the list is not yet mounted.

## Known Limitations

- Conversation is not persisted to disk; only in-memory for the session.
- Rejection reason depends on backend; old API versions without `rejectionReason` still work (card shows rejected only).
- Auto-scroll always scrolls to bottom on new content; no “only if user is near bottom” logic in this phase.

## Commands

```bash
# Mobile
cd apps/mobile
flutter analyze
dart run build_runner build --delete-conflicting-outputs
flutter test

# Backend (if needed)
cd packages/contracts && pnpm test
cd apps/api && pnpm test -- src/modules/ai-coach
```

## Git Tag

```bash
git tag phase-14-1-ai-coach-ux-hardening
```

(Do not push automatically.)
