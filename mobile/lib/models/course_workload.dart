class CourseWorkload {
  final int id;
  final String courseName;
  final int? creditHours;
  final int? ects;
  final int totalAssignments;
  final int activeAssignments;
  final int completedAssignments;

  CourseWorkload({
    required this.id,
    required this.courseName,
    this.creditHours,
    this.ects,
    this.totalAssignments = 0,
    this.activeAssignments = 0,
    this.completedAssignments = 0,
  });

  double get completionPercentage =>
      totalAssignments > 0 ? (completedAssignments / totalAssignments) * 100 : 0.0;

  factory CourseWorkload.fromJson(Map<String, dynamic> json) {
    return CourseWorkload(
      id: json['id'] as int? ?? 0,
      courseName: json['course_name'] as String? ?? '',
      creditHours: json['credit_hours'] as int?,
      ects: json['ects'] as int?,
      totalAssignments: json['total_assignments'] as int? ?? 0,
      activeAssignments: json['active_assignments'] as int? ?? 0,
      completedAssignments: json['completed_assignments'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_name': courseName,
      'credit_hours': creditHours,
      'ects': ects,
      'total_assignments': totalAssignments,
      'active_assignments': activeAssignments,
      'completed_assignments': completedAssignments,
    };
  }
}
