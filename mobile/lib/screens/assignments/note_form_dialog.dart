import 'package:flutter/material.dart';
import '../../models/assignment_note.dart';
import '../../theme/app_colors.dart';
import '../../widgets/zero_button.dart';
import '../../widgets/zero_text_field.dart';

class NoteFormDialog extends StatefulWidget {
  final AssignmentNote? note;

  const NoteFormDialog({super.key, this.note});

  static Future<String?> show(BuildContext context, {AssignmentNote? note}) {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NoteFormDialog(note: note),
    );
  }

  @override
  State<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends State<NoteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final content = _contentController.text.trim();
    Navigator.of(context).pop(content);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'EDIT STUDY NOTE' : 'NEW STUDY NOTE',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ZeroTextField(
                label: 'NOTE CONTENT',
                hintText: 'Record formulas, study tips, or assignment reminders...',
                controller: _contentController,
                maxLines: 4,
                autofocus: true,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Note content cannot be empty';
                  }
                  if (val.trim().length > 5000) {
                    return 'Note cannot exceed 5000 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ZeroButton(
                    label: 'CANCEL',
                    variant: ZeroButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  ZeroButton(
                    label: isEditing ? 'UPDATE' : 'SAVE',
                    icon: isEditing ? Icons.save_outlined : Icons.add,
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
