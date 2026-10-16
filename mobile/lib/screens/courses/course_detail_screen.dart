import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ai_message.dart';
import '../../models/course_class.dart';
import '../../providers/ai_chat_provider.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/due_copilot_drawer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/resource_list_widget.dart';
import '../assignments/assignment_detail_screen.dart';
import 'course_form_dialog.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String courseName;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourseDetail(widget.courseId);
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<CourseProvider>().fetchCourseDetail(widget.courseId);
  }

  Future<void> _handleEdit(CourseClass course) async {
    final updated = await CourseFormDialog.show(context, course: course);
    if (updated != null && mounted) {
      context.read<CourseProvider>().fetchCourseDetail(widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course updated successfully', style: TextStyle(fontFamily: 'monospace')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleDelete(CourseClass course) async {
    // If assignments exist, warn immediately
    if (course.assignmentsCount > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text('Deletion Blocked', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Cannot delete "${course.courseName}" because it has ${course.assignmentsCount} active coursework assignment(s) linked to it.\n\nPlease reassign or delete the associated assignments before removing this course.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('UNDERSTOOD'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Course?',
      message: 'Are you sure you want to permanently delete "${course.courseName}"? This action cannot be undone.',
      confirmText: 'DELETE COURSE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final error = await context.read<CourseProvider>().deleteCourse(course);
      if (!mounted) return;

      if (error == null) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${course.courseName}"', style: const TextStyle(fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(error, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final course = provider.selectedCourse;
    final assignments = provider.selectedCourseAssignments;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      endDrawer: const DueCopilotDrawer(),
      appBar: AppBar(
        title: Text(
          course?.courseName ?? widget.courseName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: 'Due Copilot (Gemini AI)',
              icon: const Icon(Icons.smart_toy_outlined, color: AppColors.coral),
              onPressed: () {
                if (course != null) {
                  context.read<AiChatProvider>().addMention(MentionItem(
                        id: course.id,
                        name: course.courseName,
                        type: 'course',
                        courseName: course.courseName,
                      ));
                }
                Scaffold.of(ctx).openEndDrawer();
              },
            ),
          ),
          if (course != null) ...[
            IconButton(
              tooltip: 'Edit Course',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _handleEdit(course),
            ),
            IconButton(
              tooltip: 'Delete Course',
              icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
              onPressed: () => _handleDelete(course),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.coral,
        child: provider.isLoading && course == null
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
                    // Course Overview Card
                    ZeroCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  course?.courseName ?? widget.courseName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Credit Badges
                              Wrap(
                                spacing: 6,
                                children: [
                                  if (course?.creditHours != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.coral.withValues(alpha: 0.12),
                                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        '${course!.creditHours} CH',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: AppColors.coral,
                                        ),
                                      ),
                                    ),
                                  if (course?.ects != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Text(
                                        '${course!.ects} ECTS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                          const SizedBox(height: 14),

                          // Instructor Information
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Instructor: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  (course?.teacherName?.isNotEmpty == true)
                                      ? course!.teacherName!
                                      : 'Not specified',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Contact Information
                          Row(
                            children: [
                              Icon(
                                Icons.alternate_email,
                                size: 16,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Contact: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  (course?.teacherContact?.isNotEmpty == true)
                                      ? course!.teacherContact!
                                      : 'Not specified',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Attached Coursework
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
                              'COURSE ASSIGNMENTS',
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
                          '${assignments.length} TOTAL',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (assignments.isEmpty)
                      EmptyState(
                        title: 'No coursework yet',
                        message: 'There are no assignments linked to this course syllabus.',
                        icon: Icons.assignment_outlined,
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: assignments.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final assignment = assignments[index];
                          final formattedDeadline = DateFormat('MMM d, yyyy • h:mm a')
                              .format(assignment.deadline.toLocal());

                          return ZeroCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AssignmentDetailScreen(
                                    assignmentId: assignment.id,
                                    initialAssignment: assignment,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                context.read<CourseProvider>().fetchCourseDetail(widget.courseId);
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    UrgencyBadge(
                                      label: assignment.urgencyLabel,
                                      isOverdue: assignment.isOverdue,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Text(
                                        assignment.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                          color: assignment.isCompleted
                                              ? AppColors.success
                                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  assignment.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
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
                    const SizedBox(height: 24),

                    // Section: Course Resources & Syllabus
                    ResourceListWidget(
                      resourceableType: 'class',
                      resourceableId: widget.courseId,
                      title: 'COURSE SYLLABUS & RESOURCES',
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
