import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_class.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_text_field.dart';

class CourseFormDialog extends StatefulWidget {
  final CourseClass? course;

  const CourseFormDialog({super.key, this.course});

  static Future<CourseClass?> show(BuildContext context, {CourseClass? course}) {
    return showDialog<CourseClass?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CourseFormDialog(course: course),
    );
  }

  @override
  State<CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseNameController;
  late final TextEditingController _teacherNameController;
  late final TextEditingController _teacherContactController;
  late final TextEditingController _creditHoursController;
  late final TextEditingController _ectsController;

  bool _isSubmitting = false;
  String? _dialogError;

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _courseNameController = TextEditingController(text: c?.courseName ?? '');
    _teacherNameController = TextEditingController(text: c?.teacherName ?? '');
    _teacherContactController = TextEditingController(text: c?.teacherContact ?? '');
    _creditHoursController = TextEditingController(
      text: c?.creditHours != null
          ? (c!.creditHours! % 1 == 0 ? c.creditHours!.toInt().toString() : c.creditHours!.toString())
          : '',
    );
    _ectsController = TextEditingController(
      text: c?.ects != null
          ? (c!.ects! % 1 == 0 ? c.ects!.toInt().toString() : c.ects!.toString())
          : '',
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _teacherNameController.dispose();
    _teacherContactController.dispose();
    _creditHoursController.dispose();
    _ectsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _dialogError = null;
    });

    final provider = context.read<CourseProvider>();
    final courseName = _courseNameController.text.trim();
    final teacherName = _teacherNameController.text.trim();
    final teacherContact = _teacherContactController.text.trim();
    final creditHours = double.tryParse(_creditHoursController.text.trim());
    final ects = double.tryParse(_ectsController.text.trim());

    CourseClass? result;

    if (isEditing) {
      result = await provider.updateCourse(
        widget.course!.id,
        courseName: courseName,
        teacherName: teacherName.isNotEmpty ? teacherName : null,
        teacherContact: teacherContact.isNotEmpty ? teacherContact : null,
        creditHours: creditHours,
        ects: ects,
      );
    } else {
      result = await provider.createCourse(
        courseName: courseName,
        teacherName: teacherName.isNotEmpty ? teacherName : null,
        teacherContact: teacherContact.isNotEmpty ? teacherContact : null,
        creditHours: creditHours,
        ects: ects,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _dialogError = provider.errorMessage ?? 'Failed to save course. Check your entries.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with coral accent
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 16,
                      color: AppColors.coral,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(
                      isEditing ? 'EDIT COURSE' : 'NEW COURSE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isEditing
                      ? 'Update course syllabus, instructor, and credit metrics.'
                      : 'Register a new subject to track its coursework and deadlines.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 20),

                if (_dialogError != null) ...[
                  ZeroCard(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                    borderColor: AppColors.danger.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _dialogError!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Course Name (Required)
                ZeroTextField(
                  label: 'Course Name *',
                  hintText: 'e.g., Computer Systems Architecture',
                  controller: _courseNameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a course name.';
                    }
                    if (value.trim().length > 255) {
                      return 'Course name must not exceed 255 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Instructor Name
                ZeroTextField(
                  label: 'Teacher / Instructor Name',
                  hintText: 'e.g., Dr. Alan Turing',
                  controller: _teacherNameController,
                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                ),
                const SizedBox(height: 14),

                // Instructor Contact
                ZeroTextField(
                  label: 'Instructor Contact / Email',
                  hintText: 'e.g., professor@university.edu',
                  controller: _teacherContactController,
                  prefixIcon: const Icon(Icons.alternate_email, size: 18),
                ),
                const SizedBox(height: 14),

                // Academic Credits Row
                Row(
                  children: [
                    Expanded(
                      child: ZeroTextField(
                        label: 'Credit Hours (CH)',
                        hintText: 'e.g., 3',
                        controller: _creditHoursController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed < 0 || parsed > 100) {
                              return 'Enter 0-100';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ZeroTextField(
                        label: 'ECTS Credits',
                        hintText: 'e.g., 5.0',
                        controller: _ectsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final parsed = double.tryParse(value.trim());
                            if (parsed == null || parsed < 0 || parsed > 100) {
                              return 'Enter 0-100';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      child: const Text('CANCEL'),
                    ),
                    const SizedBox(width: 10),
                    ZeroButton(
                      label: isEditing ? 'SAVE CHANGES' : 'CREATE COURSE',
                      isLoading: _isSubmitting,
                      onPressed: _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
