import 'ai_chat_message.dart';

/// Session-only conversation state for AI Coach.
class AIConversationState {
  const AIConversationState({
    this.messages = const [],
    this.sending = false,
    this.error,
    this.lastFailedQuestion,
  });

  final List<AIChatMessage> messages;
  final bool sending;
  final String? error;
  /// When set, the last send failed; retry will resend this without adding a new user message.
  final String? lastFailedQuestion;

  AIConversationState copyWith({
    List<AIChatMessage>? messages,
    bool? sending,
    String? error,
    String? lastFailedQuestion,
  }) {
    return AIConversationState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: error,
      lastFailedQuestion: lastFailedQuestion,
    );
  }
}
