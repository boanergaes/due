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

  Future<void> _selectStartDate() async {
    final provider = context.read<AssignmentProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      provider.setDateRange(picked, provider.endDate);
    }
  }

  Future<void> _selectEndDate() async {
    final provider = context.read<AssignmentProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.endDate ?? provider.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      provider.setDateRange(provider.startDate, picked);
    }
  }

  void _handleResetFilters() {
    _searchController.clear();
    context.read<AssignmentProvider>().resetFilters();
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
              'ASSIGNMENTS',
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
            tooltip: 'Add Assignment',
            icon: const Icon(Icons.add, size: 22),
            onPressed: _handleCreateAssignment,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.coral,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${assignments.length} ${assignments.length == 1 ? 'TASK LISTED' : 'TASKS LISTED'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'monospace',
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('NEW ASSIGNMENT', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
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
                      const SizedBox(height: 12),

                      // Dropdown Filters: Course & Urgency
                      Row(
                        children: [
                          // Course Dropdown
                          Expanded(
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                border: Border.all(
                                  color: provider.selectedClassId != null
                                      ? AppColors.coral
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: provider.selectedClassId,
                                  isExpanded: true,
                                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: provider.selectedClassId != null ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(
                                        'All Courses (${courses.length})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    ...courses.map((CourseClass c) {
                                      return DropdownMenuItem<int?>(
                                        value: c.id,
                                        child: Text(
                                          c.courseName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) => provider.setClassFilter(val),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Urgency Dropdown
                          Expanded(
                            child: Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                border: Border.all(
                                  color: provider.urgencyFilter != null
                                      ? AppColors.coral
                                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: provider.urgencyFilter,
                                  isExpanded: true,
                                  dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    fontWeight: provider.urgencyFilter != null ? FontWeight.bold : FontWeight.normal,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  items: const [
                                    DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('All Deadlines', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'overdue',
                                      child: Text('Overdue', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'due_today',
                                      child: Text('Due Today', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'due_soon',
                                      child: Text('Due Soon (<48h)', overflow: TextOverflow.ellipsis),
                                    ),
                                    DropdownMenuItem<String?>(
                                      value: 'upcoming',
                                      child: Text('Upcoming Future', overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                  onChanged: (val) => provider.setUrgencyFilter(val),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Date Range & Reset Filters Toolbar
                      Row(
                        children: [
                          // Start Date
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectStartDate,
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  border: Border.all(
                                    color: provider.startDate != null
                                        ? AppColors.coral
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 13,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        provider.startDate != null
                                            ? DateFormat('MM/dd/yy').format(provider.startDate!)
                                            : 'From Date',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: provider.startDate != null
                                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // End Date
                          Expanded(
                            child: GestureDetector(
                              onTap: _selectEndDate,
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                  border: Border.all(
                                    color: provider.endDate != null
                                        ? AppColors.coral
                                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      size: 13,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        provider.endDate != null
                                            ? DateFormat('MM/dd/yy').format(provider.endDate!)
                                            : 'To Date',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: provider.endDate != null
                                              ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
                                              : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Single Reset Filters Button
                          if (provider.hasActiveFilters) ...[
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _handleResetFilters,
                              child: Container(
                                height: 34,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.1),
                                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh, size: 13, color: AppColors.danger),
                                    SizedBox(width: 3),
                                    Text(
                                      'RESET',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
                      message: provider.hasActiveFilters
                          ? 'No coursework matches your active filter or search criteria. Tap RESET above to view all tasks.'
                          : 'Get ahead of your academic deadlines by adding your first assignment.',
                      icon: Icons.assignment_outlined,
                      action: provider.hasActiveFilters
                          ? null
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
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      assignment.courseClass!.courseName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.coral,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(width: 8),
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
