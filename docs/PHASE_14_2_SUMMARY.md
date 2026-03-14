# Phase 14.2 — AI Coach Scroll Polish

## Summary

Refined AI Coach chat scrolling: auto-scroll only when the user is near the bottom (threshold-based), preserved safe scroll guards, and an optional "New response" chip when the user is scrolled up so they can tap to jump to the latest message. No new product features.

## Files Modified

- **apps/mobile/lib/features/ai_coach/ai_coach_screen.dart**
  - Added `kAiCoachScrollThresholdPx = 120.0` and top-level `isNearBottom(pixels, maxScrollExtent, threshold)`.
  - `_scrollToBottom({bool force = false})`: in post-frame callback, if `!hasClients` return; if `force || isNearBottom(...)` animate to bottom and clear chip; else set `_showNewMessageChip = true`.
  - Body: `Expanded` wraps a `Stack` with `ListView.builder` and an optional positioned "New response" chip at the bottom; tap calls `_scrollToBottom(force: true)` and chip hides.

## Files Created

- **apps/mobile/test/features/ai_coach/ai_coach_scroll_test.dart** — Tests for `isNearBottom` (near bottom, at bottom, empty list, far from bottom, threshold boundary, edge values) and `kAiCoachScrollThresholdPx` in 100–160 range.
- **docs/PHASE_14_2_SUMMARY.md** (this file).

## Near-Bottom Detection Rule

- **Distance:** `maxScrollExtent - pixels`.
- **Rule:** Auto-scroll only when `distance <= threshold` (120 px). If `maxScrollExtent <= 0` (empty list), treat as near bottom and allow scroll so the first message still scrolls into view.

## Auto-Scroll Behavior

- Triggered by `ref.listen` when message count or `sending` changes.
- **Post-frame:** `addPostFrameCallback` so new items are laid out before reading scroll position.
- **Guard:** `if (!_scrollController.hasClients) return` to avoid using a detached controller.
- **Conditional:** If `isNearBottom(controller.position.pixels, controller.position.maxScrollExtent, kAiCoachScrollThresholdPx)` or `force`, run a single `animateTo(maxScrollExtent, 200ms, easeOut)`; otherwise do not scroll and show the "New response" chip.

## New-Message Indicator

- **Added:** A small floating chip at the bottom center of the chat area, shown when new content (message or typing) arrives and the user is **not** near the bottom.
- **Content:** "New response" with a down-arrow icon; uses `AppColors.accent` and `AppColors.surfaceVariant`, `AppRadius.lg`.
- **Action:** Tap scrolls to bottom (`_scrollToBottom(force: true)`) and hides the chip.
- **Cleared:** When the user is near the bottom and we auto-scroll, the chip is cleared so it does not appear after scrolling.

## Known Limitations

- Threshold is fixed at 120 px; not user-configurable.
- Chip does not clear when the user manually scrolls to the bottom (only when we auto-scroll or they tap the chip).
- Single `animateTo` per update; no extra handling for very fast successive updates.

## Commands

```bash
cd apps/mobile
flutter analyze
flutter test
```

No `build_runner` required for this phase.

## Git Tag

```bash
git tag phase-14-2-ai-coach-scroll-polish
```

(Do not push automatically.)
