# Phase 14 — AI Coach UI

## Summary

User interface for the AI Coach: chat screen, message list, input with send, proposal cards for `responseType == proposal`, loading and error states. Session-only persistence (no local storage).

## Files Created

- `apps/mobile/lib/features/ai_coach/ai_chat_message.dart` — Immutable chat message model (id, role, content, responseType, proposalStatus, proposal).
- `apps/mobile/lib/features/ai_coach/ai_coach_state.dart` — Conversation state (messages, sending, error).
- `apps/mobile/lib/features/ai_coach/ai_coach_provider.dart` — Notifier that sends questions to `POST /ai-coach/ask`, appends user/assistant messages, handles errors.
- `apps/mobile/lib/features/ai_coach/widgets/ai_proposal_card.dart` — Proposal card: type label, valid (green) / rejected (red) badge; outlined style.
- `apps/mobile/test/features/ai_coach/ai_chat_message_test.dart`
- `apps/mobile/test/features/ai_coach/ai_coach_state_test.dart`
- `apps/mobile/test/features/ai_coach/ai_coach_provider_test.dart`
- `apps/mobile/test/features/ai_coach/ai_coach_screen_test.dart`
- `apps/mobile/test/features/ai_coach/ai_proposal_card_test.dart`

## Files Modified

- `apps/mobile/lib/features/ai_coach/ai_coach_screen.dart` — Replaced placeholder with chat UI: AppBar, message list, typing indicator, error bar, input row (max 500 chars, trim, no empty), send button disabled while sending.

## Provider Architecture

- **aiCoachProvider**: `NotifierProvider<AICoachNotifier, AIConversationState>`.
- **State**: `AIConversationState`: `messages: List<AIChatMessage>`, `sending: bool`, `error: String?`.
- **Actions**: `sendQuestion(question)` — trims, rejects empty or length > 500; appends user message; sets `sending = true`; calls `POST /ai-coach/ask`; on success appends assistant message from `AIResponse`; on `DioException` sets `error` from `mapDioException`; on other exception sets generic error. `clearError()` clears `error`.
- **Concurrency**: When `sending` is true, `sendQuestion` returns without sending.

## Chat Message Model

- **AIChatMessage**: id, role (user | assistant), content, responseType, proposalStatus, proposal (optional map).
- **AIChatRole**: enum user, assistant.

## Message Flow

1. User types and taps send (or submit).
2. Notifier trims input; if empty or length > 500, no-op.
3. Append user message to state; set `sending = true`; clear `error`.
4. `POST /ai-coach/ask` with `{ "question": "<trimmed>" }`.
5. On success: parse `AIResponse`, append assistant message with content, responseType, proposalStatus, proposal; set `sending = false`.
6. On failure: set `error`, `sending = false`; user can dismiss error and retry.

## Proposal UI Behavior

- When assistant message has `responseType == 'proposal'` and `proposal != null`, a proposal card is rendered below the message bubble.
- Card shows: human-readable proposal type (exercise_swap → "Exercise swap", etc.), and status badge: **valid** (green) or **rejected** (red).
- No automatic plan modification; display only.

## Known Limitations

- Conversation is not persisted to local storage; only in-memory for the app session.
- Rejected proposals do not show a rejection reason from the API (contract does not expose it in the response).
- Input limited to 500 characters; no voice input, history viewer, or analytics (out of scope).

## Commands

```bash
cd apps/mobile
flutter analyze
flutter test
```

## Git Tag

```bash
git tag phase-14-ai-coach-ui
```

(Do not push automatically.)
