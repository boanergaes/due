import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/ai_message.dart';
import '../services/api_client.dart';

class AiChatProvider extends ChangeNotifier {
  final ApiClient apiClient;

  int? _currentAssignmentId;
  String? _currentAssignmentTitle;
  List<AiMessage> _messages = [];
  List<String> _contextSources = [];
  int _totalTokens = 0;
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  List<MentionItem> _mentionables = [];
  final List<MentionItem> _activeMentions = [];
  bool _fetchingMentionables = false;

  AiChatProvider({
    required this.apiClient,
    List<AiMessage>? initialMessages,
    int? initialAssignmentId,
  })  : _messages = initialMessages ?? [],
        _currentAssignmentId = initialAssignmentId;

  int? get currentAssignmentId => _currentAssignmentId;
  String? get currentAssignmentTitle => _currentAssignmentTitle;
  List<AiMessage> get messages => _messages;
  List<String> get contextSources => _contextSources;
  int get totalTokens => _totalTokens;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  List<MentionItem> get mentionables => _mentionables;
  List<MentionItem> get activeMentions => _activeMentions;
  bool get fetchingMentionables => _fetchingMentionables;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set or clear focused assignment context
  void setFocus(int? assignmentId, {String? title}) {
    _currentAssignmentId = assignmentId;
    _currentAssignmentTitle = title;
    notifyListeners();
    fetchMessages(assignmentId: assignmentId, assignmentTitle: title);
  }

  /// Add a course or assignment mention
  void addMention(MentionItem item) {
    if (!_activeMentions.any((m) => m.id == item.id && m.type == item.type)) {
      _activeMentions.add(item);
      notifyListeners();
    }
  }

  /// Remove a course or assignment mention
  void removeMention(int id, String type) {
    _activeMentions.removeWhere((m) => m.id == id && m.type == type);
    notifyListeners();
  }

  /// Clear all active mentions
  void clearMentions() {
    _activeMentions.clear();
    notifyListeners();
  }

  /// Fetch courses and assignments available for @mentions
  Future<void> fetchMentionables() async {
    _fetchingMentionables = true;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiConfig.aiMentionables);
      final list = <MentionItem>[];

      if (response is Map<String, dynamic>) {
        if (response['courses'] is List) {
          for (final item in response['courses'] as List) {
            if (item is Map<String, dynamic>) {
              list.add(MentionItem.fromJson(item));
            }
          }
        }
        if (response['assignments'] is List) {
          for (final item in response['assignments'] as List) {
            if (item is Map<String, dynamic>) {
              list.add(MentionItem.fromJson(item));
            }
          }
        }
      }

      _mentionables = list;
    } catch (_) {
      // Keep existing list if offline
    } finally {
      _fetchingMentionables = false;
      notifyListeners();
    }
  }

  /// Fetch previous AI messages and active context (workspace or assignment focused)
  Future<void> fetchMessages({int? assignmentId, String? assignmentTitle}) async {
    final targetId = assignmentId ?? _currentAssignmentId;
    if (targetId != null) {
      _currentAssignmentId = targetId;
    }
    if (assignmentTitle != null) {
      _currentAssignmentTitle = assignmentTitle;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = targetId != null
          ? '${ApiConfig.aiMessages}?assignment_id=$targetId'
          : ApiConfig.aiMessages;

      final response = await apiClient.get(url);

      final List<AiMessage> list = [];
      if (response is Map<String, dynamic>) {
        if (response['messages'] is List) {
          for (final item in response['messages'] as List) {
            if (item is Map<String, dynamic>) {
              list.add(AiMessage.fromJson(item));
            }
          }
        }

        final sources = <String>[];
        if (response['context_sources'] is List) {
          for (final s in response['context_sources'] as List) {
            sources.add(s.toString());
          }
        }

        _contextSources = sources;
        _totalTokens = response['total_tokens'] is int
            ? response['total_tokens'] as int
            : int.tryParse(response['total_tokens']?.toString() ?? '0') ?? 0;
      }

      _messages = list;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Could not load Due Copilot messages: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send prompt to Due Copilot with optional mentions and assignment focus
  Future<AiMessage?> sendMessage(
    String prompt, {
    int? assignmentId,
    List<MentionItem>? explicitMentions,
  }) async {
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return null;

    final targetId = assignmentId ?? _currentAssignmentId;
    final mentionsToSend = explicitMentions ?? List<MentionItem>.from(_activeMentions);

    _isSending = true;
    _errorMessage = null;

    // Optimistically add user message
    final userMsg = AiMessage(
      role: 'user',
      content: trimmed,
      tokensUsed: (trimmed.length / 4).ceil(),
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'message': trimmed,
        'assignment_id': ?targetId,
        if (mentionsToSend.isNotEmpty)
          'mentions': mentionsToSend.map((m) => m.toJson()).toList(),
      };

      final response = await apiClient.post(
        ApiConfig.aiChat,
        body: payload,
      );

      if (response is Map<String, dynamic>) {
        AiMessage? assistantMsg;
        if (response['assistant_message'] is Map<String, dynamic>) {
          assistantMsg = AiMessage.fromJson(
            response['assistant_message'] as Map<String, dynamic>,
          );
        } else if (response['reply'] != null) {
          assistantMsg = AiMessage(
            role: 'assistant',
            content: response['reply'].toString(),
            tokensUsed: response['tokens_used'] is int
                ? response['tokens_used'] as int
                : int.tryParse(response['tokens_used']?.toString() ?? '0') ?? 0,
            createdAt: DateTime.now(),
          );
        }

        if (assistantMsg != null) {
          _messages.add(assistantMsg);
          _totalTokens += assistantMsg.tokensUsed;
        }

        if (response['context_sources'] is List) {
          _contextSources = (response['context_sources'] as List)
              .map((s) => s.toString())
              .toList();
        }

        // Clear active mentions after successful send
        _activeMentions.clear();
        notifyListeners();
        return assistantMsg;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Due Copilot query failed: $e';
      return null;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Clear conversation history (workspace or assignment)
  Future<bool> clearHistory([int? assignmentId]) async {
    final targetId = assignmentId ?? _currentAssignmentId;
    _isLoading = true;
    notifyListeners();

    try {
      final url = targetId != null
          ? '${ApiConfig.aiHistory}?assignment_id=$targetId'
          : ApiConfig.aiHistory;

      await apiClient.delete(url);
      _messages.clear();
      _totalTokens = 0;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to clear conversation: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
