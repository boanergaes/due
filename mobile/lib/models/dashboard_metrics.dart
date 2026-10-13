class DashboardMetrics {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int overdue;
  final int dueToday;
  final double completionRate;
  final int completedOnTime;
  final double? onTimeRate;
  final int completedRecently;

  DashboardMetrics({
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.overdue = 0,
    this.dueToday = 0,
    this.completionRate = 0.0,
    this.completedOnTime = 0,
    this.onTimeRate,
    this.completedRecently = 0,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      inProgress: json['in_progress'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueToday: json['due_today'] as int? ?? 0,
      completionRate: (json['completion_rate'] != null)
          ? double.tryParse(json['completion_rate'].toString()) ?? 0.0
          : 0.0,
      completedOnTime: json['completed_on_time'] as int? ?? 0,
      onTimeRate: (json['on_time_rate'] != null)
          ? double.tryParse(json['on_time_rate'].toString())
          : null,
      completedRecently: json['completed_recently'] as int? ?? 0,
    );
  }
}
