import 'package:flutter_test/flutter_test.dart';
import 'package:pipos_fitness/features/ai_coach/ai_chat_message.dart';

void main() {
  group('AIChatMessage', () {
    test('holds user role and content', () {
      const msg = AIChatMessage(
        id: '1',
        role: AIChatRole.user,
        content: 'Hello',
      );
      expect(msg.role, AIChatRole.user);
      expect(msg.content, 'Hello');
      expect(msg.responseType, isNull);
      expect(msg.proposal, isNull);
    });

    test('holds assistant message with proposal fields', () {
      const msg = AIChatMessage(
        id: '2',
        role: AIChatRole.assistant,
        content: 'Here is a proposal',
        responseType: 'proposal',
        proposalStatus: 'valid',
        proposal: {'type': 'exercise_swap', 'fromExerciseId': 'a', 'toExerciseId': 'b'},
      );
      expect(msg.role, AIChatRole.assistant);
      expect(msg.responseType, 'proposal');
      expect(msg.proposalStatus, 'valid');
      expect(msg.proposal!['type'], 'exercise_swap');
    });

    test('holds rejectionReason when proposal is rejected', () {
      const msg = AIChatMessage(
        id: '3',
        role: AIChatRole.assistant,
        content: 'Rejected',
        responseType: 'proposal',
        proposalStatus: 'rejected',
        proposal: {'type': 'exercise_swap'},
        rejectionReason: 'Equipment not available for replacement',
      );
      expect(msg.rejectionReason, 'Equipment not available for replacement');
    });

    test('copyWith preserves unspecified fields', () {
      const msg = AIChatMessage(
        id: '3',
        role: AIChatRole.assistant,
        content: 'Original',
      );
      final updated = msg.copyWith(content: 'Updated');
      expect(updated.id, '3');
      expect(updated.role, AIChatRole.assistant);
      expect(updated.content, 'Updated');
    });
  });

  group('AIChatRole', () {
    test('has user and assistant', () {
      expect(AIChatRole.values, [AIChatRole.user, AIChatRole.assistant]);
    });
  });
}
