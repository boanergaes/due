class AssignmentNote {
  final int id;
  final int assignmentId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AssignmentNote({
    required this.id,
    required this.assignmentId,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory AssignmentNote.fromJson(Map<String, dynamic> json) {
    return AssignmentNote(
      id: json['id'] as int? ?? 0,
      assignmentId: json['assignment_id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'content': content,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
