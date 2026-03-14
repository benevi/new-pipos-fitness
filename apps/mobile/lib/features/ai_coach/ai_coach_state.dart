import 'ai_chat_message.dart';

/// Session-only conversation state for AI Coach.
class AIConversationState {
  const AIConversationState({
    this.messages = const [],
    this.sending = false,
    this.error,
  });

  final List<AIChatMessage> messages;
  final bool sending;
  final String? error;

  AIConversationState copyWith({
    List<AIChatMessage>? messages,
    bool? sending,
    String? error,
  }) {
    return AIConversationState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      error: error,
    );
  }
}
