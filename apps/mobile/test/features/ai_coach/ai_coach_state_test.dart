import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/ai_coach/ai_chat_message.dart';
import 'package:pipos_fitness/features/ai_coach/ai_coach_state.dart';

void main() {
  group('AIConversationState', () {
    test('default state is empty', () {
      const state = AIConversationState();
      expect(state.messages, isEmpty);
      expect(state.sending, false);
      expect(state.error, isNull);
    });

    test('copyWith adds messages and sending', () {
      const msg = AIChatMessage(
        id: '1',
        role: AIChatRole.user,
        content: 'Hi',
      );
      final state = const AIConversationState().copyWith(
        messages: [msg],
        sending: true,
      );
      expect(state.messages.length, 1);
      expect(state.messages.first.content, 'Hi');
      expect(state.sending, true);
    });

    test('copyWith error clears when passing null', () {
      final state = const AIConversationState().copyWith(error: 'Fail');
      expect(state.error, 'Fail');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('lastFailedQuestion set when send fails', () {
      final state = const AIConversationState().copyWith(
        error: 'Network error',
        lastFailedQuestion: 'Why was my proposal rejected?',
      );
      expect(state.lastFailedQuestion, 'Why was my proposal rejected?');
    });
  });
}
