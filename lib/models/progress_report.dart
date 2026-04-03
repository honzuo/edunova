class ProgressReport {
  final int completedTasks;
  final int pendingTasks;
  final int totalStudyMinutes;
  final double completionRate;
  final Map<String, int> weeklyStudyMinutes;

  ProgressReport({
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalStudyMinutes,
    required this.completionRate,
    required this.weeklyStudyMinutes,
  });

  ProgressReport copyWith({
    int? completedTasks,
    int? pendingTasks,
    int? totalStudyMinutes,
    double? completionRate,
    Map<String, int>? weeklyStudyMinutes,
  }) {
    return ProgressReport(
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      completionRate: completionRate ?? this.completionRate,
      weeklyStudyMinutes: weeklyStudyMinutes ?? this.weeklyStudyMinutes,
    );
  }
}