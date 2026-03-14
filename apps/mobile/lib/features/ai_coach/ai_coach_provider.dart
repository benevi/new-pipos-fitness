import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/dio_error_mapper.dart';
import '../../models/ai_response.dart';
import 'ai_chat_message.dart';
import 'ai_coach_state.dart';

final aiCoachProvider =
    NotifierProvider<AICoachNotifier, AIConversationState>(AICoachNotifier.new);

class AICoachNotifier extends Notifier<AIConversationState> {
  @override
  AIConversationState build() {
    // Keep state alive for the session so tab navigation does not clear the conversation.
    ref.keepAlive();
    return const AIConversationState();
  }

  static const int _maxQuestionLength = 500;

  Future<void> sendQuestion(String rawQuestion) async {
    final question = rawQuestion.trim();
    if (question.isEmpty) return;
    if (question.length > _maxQuestionLength) return;
    if (state.sending) return;

    final userMessage = AIChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: AIChatRole.user,
      content: question,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      sending: true,
      error: null,
      lastFailedQuestion: null,
    );

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/ai-coach/ask',
        data: {'question': question},
      );
      final data = response.data;
      if (data == null) {
        state = state.copyWith(
          sending: false,
          error: 'Invalid response from server.',
          lastFailedQuestion: question,
        );
        return;
      }
      final aiResponse = AIResponse.fromJson(data);
      final assistantMessage = AIChatMessage(
        id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
        role: AIChatRole.assistant,
        content: aiResponse.content,
        responseType: aiResponse.responseType,
        proposalStatus: aiResponse.proposalStatus,
        proposal: aiResponse.proposal,
        rejectionReason: aiResponse.rejectionReason,
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        sending: false,
        error: null,
        lastFailedQuestion: null,
      );
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(
        sending: false,
        error: failure.message,
        lastFailedQuestion: question,
      );
    } on Exception catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Something went wrong. Please try again.',
        lastFailedQuestion: question,
      );
    }
  }

  /// Resend the last failed question without adding a new user message.
  Future<void> retryLastQuestion() async {
    final question = state.lastFailedQuestion;
    if (question == null || question.isEmpty || state.sending) return;
    state = state.copyWith(error: null, lastFailedQuestion: null);
    await _sendQuestionInternal(question);
  }

  Future<void> _sendQuestionInternal(String question) async {
    state = state.copyWith(sending: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.post<Map<String, dynamic>>(
        '/ai-coach/ask',
        data: {'question': question},
      );
      final data = response.data;
      if (data == null) {
        state = state.copyWith(
          sending: false,
          error: 'Invalid response from server.',
          lastFailedQuestion: question,
        );
        return;
      }
      final aiResponse = AIResponse.fromJson(data);
      final assistantMessage = AIChatMessage(
        id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
        role: AIChatRole.assistant,
        content: aiResponse.content,
        responseType: aiResponse.responseType,
        proposalStatus: aiResponse.proposalStatus,
        proposal: aiResponse.proposal,
        rejectionReason: aiResponse.rejectionReason,
      );
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        sending: false,
        error: null,
      );
    } on DioException catch (e) {
      final failure = mapDioException(e);
      state = state.copyWith(
        sending: false,
        error: failure.message,
        lastFailedQuestion: question,
      );
    } on Exception catch (_) {
      state = state.copyWith(
        sending: false,
        error: 'Something went wrong. Please try again.',
        lastFailedQuestion: question,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null, lastFailedQuestion: null);
  }
}
