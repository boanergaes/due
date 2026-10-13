import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/course_class.dart';
import '../../providers/assignment_provider.dart';
import '../../providers/course_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_card.dart';
import '../../widgets/zero_text_field.dart';

class AssignmentFormScreen extends StatefulWidget {
  final Assignment? assignment;
  final int? preselectedClassId;

  const AssignmentFormScreen({
    super.key,
    this.assignment,
    this.preselectedClassId,
  });

  @override
  State<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends State<AssignmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  int? _selectedClassId;
  String _selectedStatus = 'pending';
  late DateTime _selectedDeadline;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isEditing => widget.assignment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.assignment;
    _titleController = TextEditingController(text: a?.title ?? '');
    _descriptionController = TextEditingController(text: a?.description ?? '');
    _selectedClassId = a?.classId ?? widget.preselectedClassId;
    _selectedStatus = a?.status ?? 'pending';
    _selectedDeadline = a?.deadline ?? DateTime.now().add(const Duration(days: 2));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courses = context.read<CourseProvider>().courses;
      if (courses.isEmpty) {
        context.read<CourseProvider>().fetchCourses(silent: true);
      }
      if (_selectedClassId == null && courses.isNotEmpty) {
        setState(() {
          _selectedClassId = courses.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDeadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null) {
      setState(() {
        _errorMessage = 'Please select a course for this assignment.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final provider = context.read<AssignmentProvider>();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    Assignment? result;
    if (isEditing) {
      result = await provider.updateAssignment(
        widget.assignment!.id,
        classId: _selectedClassId!,
        title: title,
        description: description.isNotEmpty ? description : null,
        status: _selectedStatus,
        deadline: _selectedDeadline,
      );
    } else {
      result = await provider.createAssignment(
        classId: _selectedClassId!,
        title: title,
        description: description.isNotEmpty ? description : null,
        status: _selectedStatus,
        deadline: _selectedDeadline,
      );
    }

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = provider.errorMessage ?? 'Failed to save assignment.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courses = context.watch<CourseProvider>().courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'EDIT ASSIGNMENT' : 'NEW ASSIGNMENT',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Course Selector
                const Text(
                  'COURSE CLASS',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (courses.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: const Text(
                      'No courses available. Please add a course first.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedClassId != null && courses.any((c) => c.id == _selectedClassId)
                            ? _selectedClassId
                            : null,
                        hint: const Text('Select a course...', style: TextStyle(fontSize: 13)),
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.zero,
                        items: courses.map((CourseClass c) {
                          return DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(
                              c.courseName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClassId = val;
                          });
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Assignment Title
                ZeroTextField(
                  label: 'ASSIGNMENT TITLE',
                  hintText: 'e.g. Distributed Consensus Lab 2',
                  controller: _titleController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Assignment title is required';
                    }
                    if (val.trim().length > 255) {
                      return 'Title cannot exceed 255 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                ZeroTextField(
                  label: 'DESCRIPTION (OPTIONAL)',
                  hintText: 'Detailed instructions, lecture references, or deliverables...',
                  controller: _descriptionController,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Status Selector
                const Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip('pending', 'PENDING'),
                    const SizedBox(width: 8),
                    _buildStatusChip('in_progress', 'IN PROGRESS'),
                    const SizedBox(width: 8),
                    _buildStatusChip('completed', 'COMPLETED'),
                  ],
                ),
                const SizedBox(height: 16),

                // Deadline Picker Card
                const Text(
                  'DUE DATE & TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                ZeroCard(
                  padding: const EdgeInsets.all(14),
                  onTap: _pickDeadline,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.coral),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(_selectedDeadline),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.12),
                          border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Action Buttons
                ZeroButton(
                  label: isEditing ? 'UPDATE ASSIGNMENT' : 'CREATE ASSIGNMENT',
                  icon: isEditing ? Icons.save_outlined : Icons.add,
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 10),
                ZeroButton(
                  label: 'CANCEL',
                  variant: ZeroButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedStatus == value;

    Color activeColor;
    if (value == 'completed') {
      activeColor = AppColors.success;
    } else if (value == 'in_progress') {
      activeColor = AppColors.warning;
    } else {
      activeColor = AppColors.coral;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.15)
                : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
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
