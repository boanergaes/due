import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_class.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import 'course_detail_screen.dart';
import 'course_form_dialog.dart';

class CoursesListScreen extends StatefulWidget {
  const CoursesListScreen({super.key});

  @override
  State<CoursesListScreen> createState() => _CoursesListScreenState();
}

class _CoursesListScreenState extends State<CoursesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses();
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<CourseProvider>().fetchCourses();
  }

  Future<void> _handleCreateCourse() async {
    final created = await CourseFormDialog.show(context);
    if (created != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Created "${created.courseName}"', style: const TextStyle(fontFamily: 'monospace')),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleEditCourse(CourseClass course) async {
    final updated = await CourseFormDialog.show(context, course: course);
    if (updated != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated "${updated.courseName}"', style: const TextStyle(fontFamily: 'monospace')),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleDeleteCourse(CourseClass course) async {
    // If course has active assignments, block deletion with explanation
    if (course.assignmentsCount > 0) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text('Deletion Safeguard', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Text(
            'Cannot delete "${course.courseName}" because it has ${course.assignmentsCount} assignment(s) associated with it.\n\nPlease reassign or delete the assignments first to protect coursework integrity.',
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
      message: 'Are you sure you want to permanently delete "${course.courseName}"?',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final error = await context.read<CourseProvider>().deleteCourse(course);
      if (!mounted) return;

      if (error == null) {
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
    final courses = provider.courses;
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
              'COURSES',
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
            tooltip: 'Add Course',
            icon: const Icon(Icons.add, size: 22),
            onPressed: _handleCreateCourse,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.coral,
        child: provider.isLoading && courses.isEmpty
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
                    // Header Bar with Quick Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${courses.length} ${courses.length == 1 ? 'REGISTERED COURSE' : 'REGISTERED COURSES'}',
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
                          label: const Text('NEW COURSE', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                          onPressed: _handleCreateCourse,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (courses.isEmpty)
                      EmptyState(
                        title: 'No courses registered',
                        message: 'Add your academic subjects and classes to track course syllabi and coursework.',
                        icon: Icons.school_outlined,
                        action: ZeroButton(
                          label: 'ADD FIRST COURSE',
                          variant: ZeroButtonVariant.primary,
                          onPressed: _handleCreateCourse,
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: courses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final course = courses[index];

                          return ZeroCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CourseDetailScreen(
                                    courseId: course.id,
                                    courseName: course.courseName,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.courseName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          if (course.teacherName?.isNotEmpty == true) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  course.teacherName!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Row of Actions: Edit & Delete
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          tooltip: 'Edit',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () => _handleEditCourse(course),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                          tooltip: 'Delete',
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          onPressed: () => _handleDeleteCourse(course),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Badges Row: CH, ECTS, Assignments Count
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (course.creditHours != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.coral.withValues(alpha: 0.12),
                                          border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          '${course.creditHours} CH',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            color: AppColors.coral,
                                          ),
                                        ),
                                      ),
                                    if (course.ects != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                                          border: Border.all(
                                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                          ),
                                        ),
                                        child: Text(
                                          '${course.ects} ECTS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'monospace',
                                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Text(
                                        '${course.assignmentsCount} ${course.assignmentsCount == 1 ? 'TASK' : 'TASKS'}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'monospace',
                                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                        ),
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
