import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/assignment.dart';
import '../models/course_workload.dart';
import '../models/dashboard_metrics.dart';
import '../services/api_client.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient apiClient;

  DashboardMetrics? _metrics;
  List<Assignment> _upcomingAssignments = [];
  List<Assignment> _overdueAssignments = [];
  List<CourseWorkload> _workloadByClass = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardProvider({
    required this.apiClient,
    DashboardMetrics? initialMetrics,
    List<Assignment>? initialUpcoming,
    List<Assignment>? initialOverdue,
    List<CourseWorkload>? initialWorkload,
  })  : _metrics = initialMetrics,
        _upcomingAssignments = initialUpcoming ?? [],
        _overdueAssignments = initialOverdue ?? [],
        _workloadByClass = initialWorkload ?? [];

  DashboardMetrics? get metrics => _metrics;
  List<Assignment> get upcomingAssignments => _upcomingAssignments;
  List<Assignment> get overdueAssignments => _overdueAssignments;
  List<CourseWorkload> get workloadByClass => _workloadByClass;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasOverdue => (_metrics?.overdue ?? 0) > 0 || _overdueAssignments.isNotEmpty;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch dashboard metrics, upcoming coursework, and overdue items
  Future<void> fetchDashboard({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await apiClient.get(ApiConfig.dashboard);

      if (response != null && response is Map<String, dynamic>) {
        if (response['metrics'] != null) {
          _metrics = DashboardMetrics.fromJson(response['metrics'] as Map<String, dynamic>);
        }

        if (response['upcoming_assignments'] is List) {
          _upcomingAssignments = (response['upcoming_assignments'] as List)
              .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        if (response['overdue_assignments'] is List) {
          _overdueAssignments = (response['overdue_assignments'] as List)
              .map((item) => Assignment.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        if (response['workload_by_class'] is List) {
          _workloadByClass = (response['workload_by_class'] as List)
              .map((item) => CourseWorkload.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        _errorMessage = null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load dashboard data. Pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick toggle or update of assignment status from dashboard feed
  Future<bool> updateAssignmentStatus(int assignmentId, String newStatus) async {
    try {
      final response = await apiClient.patch(
        ApiConfig.assignmentStatus(assignmentId),
        body: {'status': newStatus},
      );

      if (response != null && response['data'] != null) {
        final updated = Assignment.fromJson(response['data'] as Map<String, dynamic>);

        // If completed, remove from upcoming and overdue lists
        if (newStatus == 'completed') {
          _upcomingAssignments.removeWhere((a) => a.id == assignmentId);
          _overdueAssignments.removeWhere((a) => a.id == assignmentId);
        } else {
          // Update in place if still active
          final upIdx = _upcomingAssignments.indexWhere((a) => a.id == assignmentId);
          if (upIdx != -1) {
            _upcomingAssignments[upIdx] = updated;
          }
          final ovIdx = _overdueAssignments.indexWhere((a) => a.id == assignmentId);
          if (ovIdx != -1) {
            _overdueAssignments[ovIdx] = updated;
          }
        }

        // Re-fetch quietly in the background to ensure metric accuracy
        fetchDashboard(silent: true);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
