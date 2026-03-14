import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import 'ai_chat_message.dart';
import 'ai_coach_provider.dart';
import 'ai_coach_state.dart';
import 'widgets/ai_proposal_card.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  static const int _maxLength = 500;

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final notifier = ref.read(aiCoachProvider.notifier);

    ref.listen<AIConversationState>(aiCoachProvider, (_, next) {
      if (next.messages.length != state.messages.length || next.sending) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              itemCount: state.messages.length + (state.sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < state.messages.length) {
                  return _ChatBubble(message: state.messages[index]);
                }
                return const _TypingIndicator();
              },
            ),
          ),
          if (state.error != null) _ErrorBar(
            message: state.error!,
            onRetry: notifier.clearError,
          ),
          _InputRow(
            controller: _textController,
            maxLength: _maxLength,
            sending: state.sending,
            onSend: () {
              final text = _textController.text.trim();
              if (text.isEmpty || text.length > _maxLength) return;
              notifier.sendQuestion(text);
              _textController.clear();
            },
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AIChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AIChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.accent
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppRadius.md),
                    topRight: const Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(isUser ? AppRadius.md : 2),
                    bottomRight: Radius.circular(isUser ? 2 : AppRadius.md),
                  ),
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? Colors.white : AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              if (message.responseType == 'proposal' && message.proposal != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: AiProposalCard(
                    proposal: message.proposal!,
                    status: message.proposalStatus,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 64,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(),
                SizedBox(width: AppSpacing.xs),
                _Dot(),
                SizedBox(width: AppSpacing.xs),
                _Dot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.error.withValues(alpha: 0.15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.controller,
    required this.maxLength,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final int maxLength;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              maxLength: maxLength,
              enabled: !sending,
              decoration: const InputDecoration(
                hintText: 'Ask the AI coach...',
                counterText: '',
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: sending
                ? null
                : () {
                    final text = controller.text.trim();
                    if (text.isEmpty || text.length > maxLength) return;
                    onSend();
                  },
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
