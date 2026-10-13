class CourseClass {
  final int id;
  final int? userId;
  final String courseName;
  final String? teacherName;
  final String? teacherContact;
  final double? creditHours;
  final double? ects;
  final int assignmentsCount;

  CourseClass({
    required this.id,
    this.userId,
    required this.courseName,
    this.teacherName,
    this.teacherContact,
    this.creditHours,
    this.ects,
    this.assignmentsCount = 0,
  });

  factory CourseClass.fromJson(Map<String, dynamic> json) {
    return CourseClass(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      courseName: json['course_name'] as String? ?? '',
      teacherName: json['teacher_name'] as String?,
      teacherContact: json['teacher_contact'] as String?,
      creditHours: (json['credit_hours'] != null)
          ? double.tryParse(json['credit_hours'].toString())
          : null,
      ects: (json['ects'] != null)
          ? double.tryParse(json['ects'].toString())
          : null,
      assignmentsCount: json['assignments_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_name': courseName,
      'teacher_name': teacherName,
      'teacher_contact': teacherContact,
      'credit_hours': creditHours,
      'ects': ects,
      'assignments_count': assignmentsCount,
    };
  }

  CourseClass copyWith({
    int? id,
    int? userId,
    String? courseName,
    String? teacherName,
    String? teacherContact,
    double? creditHours,
    double? ects,
    int? assignmentsCount,
  }) {
    return CourseClass(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseName: courseName ?? this.courseName,
      teacherName: teacherName ?? this.teacherName,
      teacherContact: teacherContact ?? this.teacherContact,
      creditHours: creditHours ?? this.creditHours,
      ects: ects ?? this.ects,
      assignmentsCount: assignmentsCount ?? this.assignmentsCount,
    );
  }
}
