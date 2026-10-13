import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/course_class.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_text_field.dart';
import 'assignment_detail_screen.dart';
import 'assignment_form_screen.dart';

class AssignmentsListScreen extends StatefulWidget {
  const AssignmentsListScreen({super.key});

  @override
  State<AssignmentsListScreen> createState() => _AssignmentsListScreenState();
}

class _AssignmentsListScreenState extends State<AssignmentsListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssignmentProvider>().fetchAssignments();
      context.read<CourseProvider>().fetchCourses(silent: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await context.read<AssignmentProvider>().fetchAssignments();
    if (!mounted) return;
    await context.read<CourseProvider>().fetchCourses(silent: true);
  }

  Future<void> _handleCreateAssignment() async {
    final created = await Navigator.of(context).push<Assignment?>(
      MaterialPageRoute(
        builder: (_) => const AssignmentFormScreen(),
      ),
    );

    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${created.title}"', style: const TextStyle(fontFamily: 'monospace')),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AssignmentProvider>();
    final courseProvider = context.watch<CourseProvider>();
    final assignments = provider.assignments;
    final courses = courseProvider.courses;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.coral,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ASSIGNMENTS',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${assignments.length} ${assignments.length == 1 ? 'TASK' : 'TASKS'} LISTED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          ZeroButton(
                            label: 'NEW',
                            icon: Icons.add,
                            variant: ZeroButtonVariant.primary,
                            onPressed: _handleCreateAssignment,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Instant Search Bar
                      ZeroTextField(
                        controller: _searchController,
                        hintText: 'Search by title or description...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        onChanged: (val) {
                          provider.setSearchQuery(val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Status Tabs (ALL, PENDING, IN PROGRESS, COMPLETED)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildStatusTab('all', 'ALL', provider.statusFilter, isDark),
                            const SizedBox(width: 8),
                            _buildStatusTab('pending', 'PENDING', provider.statusFilter, isDark),
                            const SizedBox(width: 8),
                            _buildStatusTab('in_progress', 'IN PROGRESS', provider.statusFilter, isDark),
                            const SizedBox(width: 8),
                            _buildStatusTab('completed', 'COMPLETED', provider.statusFilter, isDark),
                          ],
                        ),
                      ),

                      // Course Class Filters (if any courses exist)
                      if (courses.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCourseFilterChip(
                                label: 'ALL COURSES',
                                isSelected: provider.selectedClassId == null,
                                onTap: () => provider.setClassFilter(null),
                                isDark: isDark,
                              ),
                              ...courses.map((CourseClass c) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _buildCourseFilterChip(
                                    label: c.courseName,
                                    isSelected: provider.selectedClassId == c.id,
                                    onTap: () => provider.setClassFilter(c.id),
                                    isDark: isDark,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Content / List Section
              if (provider.isLoading && assignments.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
                  ),
                )
              else if (assignments.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: EmptyState(
                      title: 'No assignments found',
                      message: provider.searchQuery.isNotEmpty || provider.statusFilter != 'all' || provider.selectedClassId != null
                          ? 'No coursework matches your active filter or search criteria.'
                          : 'Get ahead of your academic deadlines by adding your first assignment.',
                      icon: Icons.assignment_outlined,
                      action: provider.searchQuery.isNotEmpty || provider.statusFilter != 'all' || provider.selectedClassId != null
                          ? ZeroButton(
                              label: 'CLEAR FILTERS',
                              variant: ZeroButtonVariant.outline,
                              onPressed: () {
                                _searchController.clear();
                                provider.resetFilters();
                              },
                            )
                          : ZeroButton(
                              label: 'ADD FIRST ASSIGNMENT',
                              variant: ZeroButtonVariant.primary,
                              onPressed: _handleCreateAssignment,
                            ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final assignment = assignments[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAssignmentCard(context, assignment, isDark),
                        );
                      },
                      childCount: assignments.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(String status, String label, String currentStatus, bool isDark) {
    final isSelected = currentStatus == status;

    return GestureDetector(
      onTap: () => context.read<AssignmentProvider>().setStatusFilter(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.coral.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          border: Border.all(
            color: isSelected ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isSelected
                ? AppColors.coral
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white70 : Colors.black87)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context, Assignment assignment, bool isDark) {
    return ZeroCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssignmentDetailScreen(
              assignmentId: assignment.id,
              initialAssignment: assignment,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Course Tag + Urgency Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (assignment.courseClass != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    assignment.courseClass!.courseName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coral,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              UrgencyBadge(
                label: assignment.urgencyLabel,
                isOverdue: assignment.isOverdue,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Assignment Title
          Text(
            assignment.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              decoration: assignment.isCompleted ? TextDecoration.lineThrough : null,
              color: assignment.isCompleted
                  ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),

          if (assignment.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              assignment.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Bottom Bar: Deadline + Inline Status Quick Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('MMM d, HH:mm').format(assignment.deadline),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              _buildInlineStatusPicker(context, assignment, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStatusPicker(BuildContext context, Assignment assignment, bool isDark) {
    Color statusColor;
    String statusText;

    if (assignment.isCompleted) {
      statusColor = AppColors.success;
      statusText = 'COMPLETED';
    } else if (assignment.isInProgress) {
      statusColor = AppColors.warning;
      statusText = 'IN PROGRESS';
    } else {
      statusColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
      statusText = 'PENDING';
    }

    return PopupMenuButton<String>(
      tooltip: 'Change status',
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      onSelected: (newStatus) {
        context.read<AssignmentProvider>().updateStatus(assignment.id, newStatus);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'pending',
          child: Text('PENDING', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        const PopupMenuItem(
          value: 'in_progress',
          child: Text('IN PROGRESS', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.warning)),
        ),
        const PopupMenuItem(
          value: 'completed',
          child: Text('COMPLETED', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.success)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: statusColor),
            ),
            const SizedBox(width: 6),
            Text(
              statusText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 14, color: statusColor),
          ],
        ),
      ),
    );
  }
}
