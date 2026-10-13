import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/assignment.dart';
import '../models/assignment_note.dart';
import '../services/api_client.dart';

class AssignmentProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<Assignment> _assignments = [];
  Assignment? _selectedAssignment;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Filter and search state
  String _statusFilter = 'all'; // 'all', 'pending', 'in_progress', 'completed'
  int? _selectedClassId;
  String _searchQuery = '';
  String? _urgencyFilter;

  AssignmentProvider({
    required this.apiClient,
    List<Assignment>? initialAssignments,
    Assignment? initialSelectedAssignment,
  })  : _assignments = initialAssignments ?? [],
        _selectedAssignment = initialSelectedAssignment;

  List<Assignment> get assignments => _assignments;
  Assignment? get selectedAssignment => _selectedAssignment;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  String get statusFilter => _statusFilter;
  int? get selectedClassId => _selectedClassId;
  String get searchQuery => _searchQuery;
  String? get urgencyFilter => _urgencyFilter;

  int get totalCount => _assignments.length;
  int get pendingCount => _assignments.where((a) => a.isPending).length;
  int get inProgressCount => _assignments.where((a) => a.isInProgress).length;
  int get completedCount => _assignments.where((a) => a.isCompleted).length;
  int get overdueCount => _assignments.where((a) => a.isOverdue && !a.isCompleted).length;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets the active status filter ('all', 'pending', 'in_progress', 'completed')
  void setStatusFilter(String status) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    notifyListeners();
    fetchAssignments();
  }

  /// Sets the active course class filter
  void setClassFilter(int? classId) {
    if (_selectedClassId == classId) return;
    _selectedClassId = classId;
    notifyListeners();
    fetchAssignments();
  }

  /// Sets search query for title & description
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    fetchAssignments();
  }

  /// Sets urgency preset filter ('overdue', 'due_today', 'due_soon', 'upcoming')
  void setUrgencyFilter(String? urgency) {
    if (_urgencyFilter == urgency) return;
    _urgencyFilter = urgency;
    notifyListeners();
    fetchAssignments();
  }

  /// Reset all filters back to default
  void resetFilters() {
    _statusFilter = 'all';
    _selectedClassId = null;
    _searchQuery = '';
    _urgencyFilter = null;
    notifyListeners();
    fetchAssignments();
  }

  /// Fetch assignments with active filters applied
  Future<void> fetchAssignments({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final queryParams = <String>['all=1'];

      if (_statusFilter != 'all') {
        queryParams.add('status=$_statusFilter');
      }

      if (_selectedClassId != null) {
        queryParams.add('class_id=$_selectedClassId');
      }

      if (_searchQuery.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(_searchQuery.trim())}');
      }

      if (_urgencyFilter != null && _urgencyFilter!.isNotEmpty) {
        queryParams.add('urgency=$_urgencyFilter');
      }

      final url = '${ApiConfig.assignments}?${queryParams.join('&')}';
      final response = await apiClient.get(url);

      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          _assignments = data
              .map((a) => Assignment.fromJson(a as Map<String, dynamic>))
              .toList();
        }
        _errorMessage = null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load assignments. Pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch full assignment detail including notes
  Future<Assignment?> fetchAssignmentDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiConfig.assignmentDetail(id));

      if (response != null && response['data'] != null) {
        final assignmentData = response['data'] as Map<String, dynamic>;
        _selectedAssignment = Assignment.fromJson(assignmentData);

        // Update in cached list if present
        final index = _assignments.indexWhere((a) => a.id == id);
        if (index != -1 && _selectedAssignment != null) {
          _assignments[index] = _selectedAssignment!;
        }

        _errorMessage = null;
        return _selectedAssignment;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Failed to load assignment details.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new assignment
  Future<Assignment?> createAssignment({
    required int classId,
    required String title,
    String? description,
    required String status,
    required DateTime deadline,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'class_id': classId,
        'title': title,
        'description': description,
        'status': status,
        'deadline': deadline.toIso8601String(),
      };

      final response = await apiClient.post(ApiConfig.assignments, body: body);

      if (response != null && response['data'] != null) {
        final created = Assignment.fromJson(response['data'] as Map<String, dynamic>);
        _assignments.insert(0, created);
        _errorMessage = null;
        notifyListeners();
        return created;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Failed to create assignment. Please check your network.';
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Update an existing assignment
  Future<Assignment?> updateAssignment(
    int id, {
    required int classId,
    required String title,
    String? description,
    required String status,
    required DateTime deadline,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'class_id': classId,
        'title': title,
        'description': description,
        'status': status,
        'deadline': deadline.toIso8601String(),
      };

      final response = await apiClient.put(ApiConfig.assignmentDetail(id), body: body);

      if (response != null && response['data'] != null) {
        final updated = Assignment.fromJson(response['data'] as Map<String, dynamic>);
        final index = _assignments.indexWhere((a) => a.id == id);
        if (index != -1) {
          _assignments[index] = updated;
        }
        if (_selectedAssignment?.id == id) {
          _selectedAssignment = updated;
        }
        _errorMessage = null;
        notifyListeners();
        return updated;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Failed to update assignment.';
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Quick inline status toggle / switcher
  Future<bool> updateStatus(int id, String newStatus) async {
    // Optimistically update locally
    final index = _assignments.indexWhere((a) => a.id == id);
    final previousStatus = index != -1 ? _assignments[index].status : null;

    if (index != -1) {
      _assignments[index] = _assignments[index].copyWith(status: newStatus);
      if (_selectedAssignment?.id == id) {
        _selectedAssignment = _selectedAssignment!.copyWith(status: newStatus);
      }
      notifyListeners();
    }

    try {
      final response = await apiClient.patch(
        ApiConfig.assignmentStatus(id),
        body: {'status': newStatus},
      );

      if (response != null && response['data'] != null) {
        final updated = Assignment.fromJson(response['data'] as Map<String, dynamic>);
        if (index != -1) {
          _assignments[index] = updated;
        }
        if (_selectedAssignment?.id == id) {
          _selectedAssignment = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } on ApiException catch (e) {
      // Revert optimistic update
      if (index != -1 && previousStatus != null) {
        _assignments[index] = _assignments[index].copyWith(status: previousStatus);
        if (_selectedAssignment?.id == id) {
          _selectedAssignment = _selectedAssignment!.copyWith(status: previousStatus);
        }
      }
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      if (index != -1 && previousStatus != null) {
        _assignments[index] = _assignments[index].copyWith(status: previousStatus);
        if (_selectedAssignment?.id == id) {
          _selectedAssignment = _selectedAssignment!.copyWith(status: previousStatus);
        }
      }
      _errorMessage = 'Failed to update status.';
      notifyListeners();
      return false;
    }
  }

  /// Delete an assignment
  Future<bool> deleteAssignment(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.delete(ApiConfig.assignmentDetail(id));
      _assignments.removeWhere((a) => a.id == id);
      if (_selectedAssignment?.id == id) {
        _selectedAssignment = null;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete assignment.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch notes for an assignment
  Future<List<AssignmentNote>> fetchNotes(int assignmentId) async {
    try {
      final response = await apiClient.get(ApiConfig.assignmentNotes(assignmentId));
      if (response != null && response is Map<String, dynamic> && response['data'] is List) {
        final notes = (response['data'] as List)
            .map((n) => AssignmentNote.fromJson(n as Map<String, dynamic>))
            .toList();

        if (_selectedAssignment?.id == assignmentId) {
          _selectedAssignment = _selectedAssignment!.copyWith(notes: notes);
          notifyListeners();
        }
        return notes;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add a study note to an assignment
  Future<AssignmentNote?> addNote(int assignmentId, String content) async {
    try {
      final body = {'content': content};
      final response = await apiClient.post(ApiConfig.assignmentNotes(assignmentId), body: body);

      if (response != null && response['data'] != null) {
        final createdNote = AssignmentNote.fromJson(response['data'] as Map<String, dynamic>);

        if (_selectedAssignment?.id == assignmentId) {
          final updatedNotes = [createdNote, ..._selectedAssignment!.notes];
          _selectedAssignment = _selectedAssignment!.copyWith(notes: updatedNotes);

          // Also update list if cached
          final idx = _assignments.indexWhere((a) => a.id == assignmentId);
          if (idx != -1) {
            _assignments[idx] = _assignments[idx].copyWith(notes: updatedNotes);
          }
          notifyListeners();
        }
        return createdNote;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Failed to add note.';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing note
  Future<AssignmentNote?> updateNote(int assignmentId, int noteId, String content) async {
    try {
      final body = {'content': content};
      final response = await apiClient.put(
        ApiConfig.assignmentNoteDetail(assignmentId, noteId),
        body: body,
      );

      if (response != null && response['data'] != null) {
        final updatedNote = AssignmentNote.fromJson(response['data'] as Map<String, dynamic>);

        if (_selectedAssignment?.id == assignmentId) {
          final updatedNotes = _selectedAssignment!.notes.map((n) {
            return n.id == noteId ? updatedNote : n;
          }).toList();
          _selectedAssignment = _selectedAssignment!.copyWith(notes: updatedNotes);

          final idx = _assignments.indexWhere((a) => a.id == assignmentId);
          if (idx != -1) {
            _assignments[idx] = _assignments[idx].copyWith(notes: updatedNotes);
          }
          notifyListeners();
        }
        return updatedNote;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _errorMessage = 'Failed to update note.';
      notifyListeners();
      return null;
    }
  }

  /// Delete a note
  Future<bool> deleteNote(int assignmentId, int noteId) async {
    try {
      await apiClient.delete(ApiConfig.assignmentNoteDetail(assignmentId, noteId));

      if (_selectedAssignment?.id == assignmentId) {
        final updatedNotes = _selectedAssignment!.notes.where((n) => n.id != noteId).toList();
        _selectedAssignment = _selectedAssignment!.copyWith(notes: updatedNotes);

        final idx = _assignments.indexWhere((a) => a.id == assignmentId);
        if (idx != -1) {
          _assignments[idx] = _assignments[idx].copyWith(notes: updatedNotes);
        }
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete note.';
      notifyListeners();
      return false;
    }
  }
}
