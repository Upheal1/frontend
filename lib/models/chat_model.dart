// Chat models for the UpHeal AI Chat API.

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.metadata = const {},
    required this.createdAt,
  });

  final String role;
  final String content;
  final Map<String, dynamic> metadata;
  final String createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'metadata': metadata,
        'created_at': createdAt,
      };

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatResponse {
  const ChatResponse({
    required this.sessionId,
    required this.messageId,
    required this.assistantMessage,
    required this.history,
    this.relevantTaskId,
  });

  final String sessionId;
  final String messageId;
  final ChatMessage assistantMessage;
  final List<ChatMessage> history;
  final String? relevantTaskId;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final historyList = json['history'] as List<dynamic>? ?? [];
    return ChatResponse(
      sessionId: json['session_id'] as String? ?? '',
      messageId: json['message_id'] as String? ?? '',
      assistantMessage: ChatMessage.fromJson(
        json['assistant_message'] as Map<String, dynamic>? ?? {},
      ),
      history: historyList
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      relevantTaskId: json['relevant_task_id'] as String?,
    );
  }
}

class ChatHistoryResponse {
  const ChatHistoryResponse({
    required this.sessionId,
    required this.messages,
    required this.totalCount,
  });

  final String sessionId;
  final List<ChatMessage> messages;
  final int totalCount;

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return ChatHistoryResponse(
      sessionId: json['session_id'] as String? ?? '',
      messages: messagesList
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int? ?? 0,
    );
  }
}

class ChatSession {
  const ChatSession({
    required this.sessionId,
    required this.messages,
    this.lastMessage,
    this.createdAt,
    this.updatedAt,
  });

  final String sessionId;
  final List<ChatMessage> messages;
  final String? lastMessage;
  final String? createdAt;
  final String? updatedAt;

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    final messagesList = json['messages'] as List<dynamic>? ?? [];
    return ChatSession(
      sessionId: json['session_id'] as String? ?? '',
      messages: messagesList
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}