import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/assignment.dart';
import '../models/course_class.dart';
import '../services/api_client.dart';

class CourseProvider extends ChangeNotifier {
  final ApiClient apiClient;

  List<CourseClass> _courses = [];
  CourseClass? _selectedCourse;
  List<Assignment> _selectedCourseAssignments = [];
  bool _isLoading = false;
  String? _errorMessage;

  CourseProvider({
    required this.apiClient,
    List<CourseClass>? initialCourses,
    CourseClass? initialSelectedCourse,
    List<Assignment>? initialAssignments,
  })  : _courses = initialCourses ?? [],
        _selectedCourse = initialSelectedCourse,
        _selectedCourseAssignments = initialAssignments ?? [];

  List<CourseClass> get courses => _courses;
  CourseClass? get selectedCourse => _selectedCourse;
  List<Assignment> get selectedCourseAssignments => _selectedCourseAssignments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Fetch all courses belonging to the user
  Future<void> fetchCourses({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await apiClient.get('${ApiConfig.classes}?all=1');

      if (response != null && response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          _courses = data
              .map((c) => CourseClass.fromJson(c as Map<String, dynamic>))
              .toList();
        }
        _errorMessage = null;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load courses. Please pull down to retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch detailed syllabus and attached assignments for a course
  Future<CourseClass?> fetchCourseDetail(int courseId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get(ApiConfig.classDetail(courseId));

      if (response != null && response['data'] != null) {
        final courseData = response['data'] as Map<String, dynamic>;
        _selectedCourse = CourseClass.fromJson(courseData);

        if (courseData['assignments'] is List) {
          _selectedCourseAssignments = (courseData['assignments'] as List)
              .map((a) => Assignment.fromJson(a as Map<String, dynamic>))
              .toList();
        } else {
          _selectedCourseAssignments = [];
        }

        _errorMessage = null;
        return _selectedCourse;
      }
      return null;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Failed to load course details.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new course
  Future<CourseClass?> createCourse({
    required String courseName,
    String? teacherName,
    String? teacherContact,
    double? creditHours,
    double? ects,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'course_name': courseName,
        'teacher_name': teacherName,
        'teacher_contact': teacherContact,
        'credit_hours': creditHours,
        'ects': ects,
      };

      final response = await apiClient.post(ApiConfig.classes, body: body);

      if (response != null && response['data'] != null) {
        final created = CourseClass.fromJson(response['data'] as Map<String, dynamic>);
        _courses.insert(0, created);
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
      _errorMessage = 'Unable to create course. Check your network.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing course
  Future<CourseClass?> updateCourse(
    int courseId, {
    required String courseName,
    String? teacherName,
    String? teacherContact,
    double? creditHours,
    double? ects,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'course_name': courseName,
        'teacher_name': teacherName,
        'teacher_contact': teacherContact,
        'credit_hours': creditHours,
        'ects': ects,
      };

      final response = await apiClient.put(ApiConfig.classDetail(courseId), body: body);

      if (response != null && response['data'] != null) {
        final updated = CourseClass.fromJson(response['data'] as Map<String, dynamic>);
        final idx = _courses.indexWhere((c) => c.id == courseId);
        if (idx != -1) {
          _courses[idx] = updated;
        }
        if (_selectedCourse?.id == courseId) {
          _selectedCourse = updated;
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
      _errorMessage = 'Unable to update course.';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a course (with backend assignment protection handling)
  /// Returns null on success, or an error string if blocked (e.g. assignments exist)
  Future<String?> deleteCourse(CourseClass course) async {
    try {
      await apiClient.delete(ApiConfig.classDetail(course.id));
      _courses.removeWhere((c) => c.id == course.id);
      if (_selectedCourse?.id == course.id) {
        _selectedCourse = null;
        _selectedCourseAssignments = [];
      }
      notifyListeners();
      return null; // Success
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Failed to delete course. Please check your network.';
    }
  }
}
