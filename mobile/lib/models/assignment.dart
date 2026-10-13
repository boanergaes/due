import 'course_class.dart';
import 'assignment_note.dart';

class Assignment {
  final int id;
  final int? userId;
  final int classId;
  final String title;
  final String? description;
  final String status;
  final DateTime deadline;
  final DateTime? completedAt;
  final Map<String, dynamic>? urgency;
  final CourseClass? courseClass;
  final List<AssignmentNote> notes;

  Assignment({
    required this.id,
    this.userId,
    required this.classId,
    required this.title,
    this.description,
    required this.status,
    required this.deadline,
    this.completedAt,
    this.urgency,
    this.courseClass,
    this.notes = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';

  String get urgencyLabel => urgency?['label'] as String? ?? 'UPCOMING';
  String get urgencyColor => urgency?['color'] as String? ?? 'gray';
  bool get isOverdue => urgency?['is_overdue'] as bool? ?? false;
  int? get daysRemaining => urgency?['days_remaining'] as int?;

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      classId: json['class_id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      deadline: DateTime.tryParse(json['deadline']?.toString() ?? '') ??
          DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      urgency: json['urgency'] as Map<String, dynamic>?,
      courseClass: json['course_class'] != null
          ? CourseClass.fromJson(json['course_class'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] is List
          ? (json['notes'] as List)
              .map((n) => AssignmentNote.fromJson(n as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'class_id': classId,
      'title': title,
      'description': description,
      'status': status,
      'deadline': deadline.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'urgency': urgency,
      'course_class': courseClass?.toJson(),
    };
  }

  Assignment copyWith({
    int? id,
    int? userId,
    int? classId,
    String? title,
    String? description,
    String? status,
    DateTime? deadline,
    DateTime? completedAt,
    Map<String, dynamic>? urgency,
    CourseClass? courseClass,
    List<AssignmentNote>? notes,
  }) {
    return Assignment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      urgency: urgency ?? this.urgency,
      courseClass: courseClass ?? this.courseClass,
      notes: notes ?? this.notes,
    );
  }
}
