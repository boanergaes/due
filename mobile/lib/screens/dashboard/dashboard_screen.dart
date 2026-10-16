import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAssignments;
  final VoidCallback? onNavigateToCourses;

  const DashboardScreen({
    super.key,
    this.onNavigateToAssignments,
    this.onNavigateToCourses,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchDashboard();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<DashboardProvider>().fetchDashboard();
  }

  void _showCompletionConfirmation(BuildContext context, Assignment assignment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: Text(
          'Do you want to mark "${assignment.title}" as completed?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await context
                  .read<DashboardProvider>()
                  .updateAssignmentStatus(assignment.id, 'completed');

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text(
                      'Completed: ${assignment.title}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                );
              }
            },
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final metrics = dashboard.metrics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              color: AppColors.coral,
              margin: const EdgeInsets.only(right: 8),
            ),
            const Text(
              'DASHBOARD',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Due Copilot (Gemini AI)',
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.coral, size: 20),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
          IconButton(
            tooltip: 'Refresh Dashboard',
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: dashboard.isLoading ? null : _handleRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.coral,
        child: dashboard.isLoading && metrics == null
            ? const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                  ),
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Student Greeting Header
                    ZeroCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'WELCOME BACK,',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.2,
                                        fontFamily: 'monospace',
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.name.toUpperCase() ?? 'STUDENT',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(alpha: 0.12),
                                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'ACADEMIC TRACKER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: isDark ? AppColors.coral : AppColors.coralDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Error Notification if any
                    if (dashboard.errorMessage != null) ...[
                      ZeroCard(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                        borderColor: AppColors.danger.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dashboard.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16, color: AppColors.danger),
                              onPressed: dashboard.clearError,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Overdue Alert Banner (When Overdue assignments exist)
                    if (dashboard.hasOverdue) ...[
                      ZeroCard(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                        borderColor: AppColors.danger,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  color: AppColors.danger,
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'OVERDUE ATTENTION REQUIRED (${metrics?.overdue ?? dashboard.overdueAssignments.length})',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You have overdue coursework that requires immediate completion to protect your grade.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ZeroButton(
                              label: 'VIEW OVERDUE ASSIGNMENTS',
                              variant: ZeroButtonVariant.danger,
                              onPressed: widget.onNavigateToAssignments,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section: Overview Metrics Grid (2 columns)
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 14,
                          color: AppColors.coral,
                          margin: const EdgeInsets.only(right: 6),
                        ),
                        const Text(
                          'COURSEWORK METRICS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.25,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MetricCard(
                          label: 'Total',
                          value: '${metrics?.total ?? 0}',
                          icon: Icons.assignment_outlined,
                          accentColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        MetricCard(
                          label: 'Pending',
                          value: '${metrics?.pending ?? 0}',
                          icon: Icons.hourglass_empty_outlined,
                          accentColor: AppColors.warning,
                        ),
                        MetricCard(
                          label: 'In Progress',
                          value: '${metrics?.inProgress ?? 0}',
                          icon: Icons.pending_actions_outlined,
                          accentColor: AppColors.coral,
                        ),
                        MetricCard(
                          label: 'Completed',
                          value: '${metrics?.completed ?? 0}',
                          icon: Icons.check_circle_outline,
                          accentColor: AppColors.success,
                        ),
                        MetricCard(
                          label: 'Overdue',
                          value: '${metrics?.overdue ?? 0}',
                          icon: Icons.alarm_off_outlined,
                          accentColor: AppColors.danger,
                        ),
                        MetricCard(
                          label: 'Due Today',
                          value: '${metrics?.dueToday ?? 0}',
                          icon: Icons.today_outlined,
                          accentColor: AppColors.coral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: Performance Analysis
                    ZeroCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.trending_up, size: 16, color: AppColors.coral),
                                  SizedBox(width: 8),
                                  Text(
                                    'PERFORMANCE ANALYSIS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'AGGREGATES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Completion Rate Progress Bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'COMPLETION RATE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '${metrics?.completionRate.toStringAsFixed(1) ?? '0.0'}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ((metrics?.completionRate ?? 0) / 100).clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coral),
                            borderRadius: BorderRadius.zero,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${metrics?.completed ?? 0} finished',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              Text(
                                '${(metrics?.total ?? 0) - (metrics?.completed ?? 0)} remaining',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(height: 16),

                          // On-Time Completion Rate
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ON-TIME RATE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Finished prior to scheduled deadline.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (metrics?.onTimeRate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '${metrics!.onTimeRate!.toStringAsFixed(1)}% ON-TIME',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: AppColors.success,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                  child: Text(
                                    'NO TASKS YET',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(height: 16),

                          // 7-Day Completion Velocity
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '7-DAY VELOCITY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '${metrics?.completedRecently ?? 0} ${(metrics?.completedRecently ?? 0) == 1 ? 'task' : 'tasks'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: Workload by Course
                    ZeroCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bar_chart, size: 16, color: AppColors.coral),
                                  SizedBox(width: 8),
                                  Text(
                                    'WORKLOAD BY COURSE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.onNavigateToCourses != null)
                                GestureDetector(
                                  onTap: widget.onNavigateToCourses,
                                  child: Text(
                                    'ALL COURSES (${dashboard.workloadByClass.length}) →',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.coral,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (dashboard.workloadByClass.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 28,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No courses registered yet.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dashboard.workloadByClass.length,
                              separatorBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Divider(
                                  height: 1,
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                final course = dashboard.workloadByClass[index];
                                final percent = course.completionPercentage;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                color: AppColors.coral,
                                                margin: const EdgeInsets.only(right: 8),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  course.courseName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (course.creditHours != null) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${course.creditHours} CH',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontFamily: 'monospace',
                                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '${course.activeAssignments}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                              ),
                                              const TextSpan(text: ' active / '),
                                              TextSpan(text: '${course.totalAssignments} total'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(
                                      value: (percent / 100).clamp(0.0, 1.0),
                                      minHeight: 5,
                                      backgroundColor: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coral),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Upcoming Deadlines Feed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 14,
                              color: AppColors.coral,
                              margin: const EdgeInsets.only(right: 6),
                            ),
                            const Text(
                              'UPCOMING DEADLINES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        if (dashboard.upcomingAssignments.isNotEmpty && widget.onNavigateToAssignments != null)
                          GestureDetector(
                            onTap: widget.onNavigateToAssignments,
                            child: const Text(
                              'VIEW ALL →',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.coral,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (dashboard.upcomingAssignments.isEmpty)
                      EmptyState(
                        title: 'No impending deadlines',
                        message: 'All your academic coursework is currently completed or up to date.',
                        icon: Icons.check_circle_outline,
                        action: widget.onNavigateToAssignments != null
                            ? ZeroButton(
                                label: 'VIEW ALL ASSIGNMENTS',
                                variant: ZeroButtonVariant.outline,
                                onPressed: widget.onNavigateToAssignments,
                              )
                            : null,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: dashboard.upcomingAssignments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final assignment = dashboard.upcomingAssignments[index];
                          final formattedDeadline = DateFormat('MMM d, yyyy • h:mm a')
                              .format(assignment.deadline.toLocal());

                          return ZeroCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Course Class & Urgency Badge
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if (assignment.courseClass != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                                                border: Border.all(
                                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                                ),
                                              ),
                                              child: Text(
                                                assignment.courseClass!.courseName.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'monospace',
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                ),
                                              ),
                                            ),
                                          UrgencyBadge(
                                            label: assignment.urgencyLabel,
                                            isOverdue: assignment.isOverdue,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quick Status Completion Action
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_box_outline_blank,
                                        size: 22,
                                      ),
                                      tooltip: 'Mark completed',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _showCompletionConfirmation(context, assignment),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedDeadline,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
