import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/assignment_note.dart';
import '../../providers/assignment_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import 'assignment_form_screen.dart';
import 'note_form_dialog.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final int assignmentId;
  final Assignment? initialAssignment;

  const AssignmentDetailScreen({
    super.key,
    required this.assignmentId,
    this.initialAssignment,
  });

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssignmentProvider>().fetchAssignmentDetail(widget.assignmentId);
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<AssignmentProvider>().fetchAssignmentDetail(widget.assignmentId);
  }

  Future<void> _handleEdit(Assignment assignment) async {
    final updated = await Navigator.of(context).push<Assignment?>(
      MaterialPageRoute(
        builder: (_) => AssignmentFormScreen(assignment: assignment),
      ),
    );

    if (updated != null && mounted) {
      context.read<AssignmentProvider>().fetchAssignmentDetail(widget.assignmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment updated successfully', style: TextStyle(fontFamily: 'monospace')),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleDelete(Assignment assignment) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Assignment?',
      message: 'Are you sure you want to permanently delete "${assignment.title}"? Any attached notes will also be removed.',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AssignmentProvider>().deleteAssignment(assignment.id);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${assignment.title}"', style: const TextStyle(fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete assignment', style: TextStyle(fontFamily: 'monospace')),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  Future<void> _handleStatusChange(String newStatus) async {
    await context.read<AssignmentProvider>().updateStatus(widget.assignmentId, newStatus);
  }

  Future<void> _handleAddNote() async {
    final content = await NoteFormDialog.show(context);
    if (content != null && content.isNotEmpty && mounted) {
      final created = await context.read<AssignmentProvider>().addNote(widget.assignmentId, content);
      if (mounted && created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study note added', style: TextStyle(fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  Future<void> _handleEditNote(AssignmentNote note) async {
    final content = await NoteFormDialog.show(context, note: note);
    if (content != null && content.isNotEmpty && mounted) {
      final updated = await context.read<AssignmentProvider>().updateNote(widget.assignmentId, note.id, content);
      if (mounted && updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study note updated', style: TextStyle(fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteNote(AssignmentNote note) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Note?',
      message: 'Are you sure you want to permanently delete this study note?',
      confirmText: 'DELETE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AssignmentProvider>().deleteNote(widget.assignmentId, note.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note deleted', style: TextStyle(fontFamily: 'monospace')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AssignmentProvider>();
    final assignment = provider.selectedAssignment ?? widget.initialAssignment;

    if (provider.isLoading && assignment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ASSIGNMENT DETAIL', style: TextStyle(fontFamily: 'monospace')),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2),
        ),
      );
    }

    if (assignment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ASSIGNMENT DETAIL', style: TextStyle(fontFamily: 'monospace')),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              const Text(
                'Assignment not found',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'It may have been deleted.',
                style: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ASSIGNMENT DETAIL',
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 15,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Assignment',
            onPressed: () => _handleEdit(assignment),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            tooltip: 'Delete Assignment',
            onPressed: () => _handleDelete(assignment),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.coral,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urgency Banner
              _buildUrgencyBanner(assignment, isDark),
              const SizedBox(height: 16),

              // Course Badge & Title Card
              ZeroCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (assignment.courseClass != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withValues(alpha: 0.12),
                              border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              assignment.courseClass!.courseName,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
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
                    const SizedBox(height: 12),
                    Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                        decoration: assignment.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (assignment.courseClass?.teacherName?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            assignment.courseClass!.teacherName!,
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
              const SizedBox(height: 16),

              // Inline Status Selector
              const Text(
                'STATUS WORKFLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ZeroCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _buildStatusSegment('pending', 'PENDING', assignment.status, isDark),
                    const SizedBox(width: 6),
                    _buildStatusSegment('in_progress', 'IN PROGRESS', assignment.status, isDark),
                    const SizedBox(width: 6),
                    _buildStatusSegment('completed', 'COMPLETED', assignment.status, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deadline & Timeline Card
              const Text(
                'SCHEDULE & DEADLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ZeroCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined, size: 18, color: AppColors.coral),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DUE DATE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, MMM d, yyyy • HH:mm').format(assignment.deadline),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (assignment.completedAt != null) ...[
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COMPLETED AT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE, MMM d, yyyy • HH:mm').format(assignment.completedAt!),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description Card
              const Text(
                'DESCRIPTION & INSTRUCTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ZeroCard(
                padding: const EdgeInsets.all(16),
                child: assignment.description?.isNotEmpty == true
                    ? Text(
                        assignment.description!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      )
                    : Text(
                        'No detailed instructions provided for this assignment.',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Interactive Coursework Notes Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COURSEWORK NOTES (${assignment.notes.length})',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleAddNote,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 14, color: AppColors.coral),
                          SizedBox(width: 4),
                          Text(
                            'ADD NOTE',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (assignment.notes.isEmpty)
                ZeroCard(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 28,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No study notes attached yet.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ZeroButton(
                          label: 'ADD FIRST NOTE',
                          icon: Icons.add,
                          variant: ZeroButtonVariant.outline,
                          onPressed: _handleAddNote,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...assignment.notes.map((note) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ZeroCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.content,
                            style: const TextStyle(fontSize: 13, height: 1.45),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (note.createdAt != null)
                                Text(
                                  DateFormat('MMM d, yyyy • HH:mm').format(note.createdAt!),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    tooltip: 'Edit Note',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _handleEditNote(note),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                                    tooltip: 'Delete Note',
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(4),
                                    onPressed: () => _handleDeleteNote(note),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyBanner(Assignment assignment, bool isDark) {
    if (assignment.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text(
              'COURSEWORK COMPLETED',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    if (assignment.isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'OVERDUE: THIS ASSIGNMENT IS PAST ITS DEADLINE',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, color: AppColors.coral, size: 18),
          const SizedBox(width: 8),
          Text(
            'ACTIVE DEADLINE: ${assignment.urgencyLabel}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSegment(String status, String label, String currentStatus, bool isDark) {
    final isSelected = currentStatus == status;

    Color activeColor;
    if (status == 'completed') {
      activeColor = AppColors.success;
    } else if (status == 'in_progress') {
      activeColor = AppColors.warning;
    } else {
      activeColor = AppColors.coral;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => _handleStatusChange(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? activeColor
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
