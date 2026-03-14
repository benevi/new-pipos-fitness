/// Immutable chat message for AI Coach conversation.
class AIChatMessage {
  const AIChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.responseType,
    this.proposalStatus,
    this.proposal,
    this.rejectionReason,
  });

  final String id;
  final AIChatRole role;
  final String content;
  final String? responseType;
  final String? proposalStatus;
  final Map<String, dynamic>? proposal;
  final String? rejectionReason;

  AIChatMessage copyWith({
    String? id,
    AIChatRole? role,
    String? content,
    String? responseType,
    String? proposalStatus,
    Map<String, dynamic>? proposal,
    String? rejectionReason,
  }) {
    return AIChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      responseType: responseType ?? this.responseType,
      proposalStatus: proposalStatus ?? this.proposalStatus,
      proposal: proposal ?? this.proposal,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

enum AIChatRole { user, assistant }
