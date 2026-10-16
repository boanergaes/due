class AiMessage {
  final int? id;
  final String role; // 'user' or 'assistant'
  final String content;
  final int tokensUsed;
  final DateTime? createdAt;

  const AiMessage({
    this.id,
    required this.role,
    required this.content,
    this.tokensUsed = 0,
    this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      tokensUsed: json['tokens_used'] is int
          ? json['tokens_used'] as int
          : int.tryParse(json['tokens_used']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'tokens_used': tokensUsed,
        'created_at': createdAt?.toIso8601String(),
      };
}

class AiChatResponse {
  final String reply;
  final int tokensUsed;
  final String? model;
  final List<String> contextSources;
  final AiMessage? userMessage;
  final AiMessage? assistantMessage;

  const AiChatResponse({
    required this.reply,
    required this.tokensUsed,
    this.model,
    required this.contextSources,
    this.userMessage,
    this.assistantMessage,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    final sources = <String>[];
    if (json['context_sources'] is List) {
      for (final s in json['context_sources'] as List) {
        sources.add(s.toString());
      }
    }

    return AiChatResponse(
      reply: json['reply']?.toString() ?? '',
      tokensUsed: json['tokens_used'] is int
          ? json['tokens_used'] as int
          : int.tryParse(json['tokens_used']?.toString() ?? '0') ?? 0,
      model: json['model']?.toString(),
      contextSources: sources,
      userMessage: json['user_message'] is Map<String, dynamic>
          ? AiMessage.fromJson(json['user_message'] as Map<String, dynamic>)
          : null,
      assistantMessage: json['assistant_message'] is Map<String, dynamic>
          ? AiMessage.fromJson(json['assistant_message'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MentionItem {
  final int id;
  final String type; // 'course' or 'assignment'
  final String name;
  final String? detail;
  final String? courseName;

  const MentionItem({
    required this.id,
    required this.type,
    required this.name,
    this.detail,
    this.courseName,
  });

  bool get isCourse => type == 'course' || type == 'class';
  bool get isAssignment => type == 'assignment';

  factory MentionItem.fromJson(Map<String, dynamic> json) {
    return MentionItem(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      type: json['type']?.toString() ?? 'course',
      name: json['name']?.toString() ?? '',
      detail: json['detail']?.toString(),
      courseName: json['course_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
      };
}
