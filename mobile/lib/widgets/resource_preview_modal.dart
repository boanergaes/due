import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/study_resource.dart';
import '../theme/app_colors.dart';
import 'zero_button.dart';
import 'zero_card.dart';

class ResourcePreviewModal extends StatelessWidget {
  final StudyResource resource;

  const ResourcePreviewModal({
    super.key,
    required this.resource,
  });

  static Future<void> show(BuildContext context, StudyResource resource) {
    return showDialog(
      context: context,
      builder: (ctx) => ResourcePreviewModal(resource: resource),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildTypeBadge(resource, isDark),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title.isNotEmpty
                                    ? resource.title
                                    : resource.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${resource.fileName} • ${resource.formattedSize}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _buildContent(context, isDark),
              ),

              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 16),

              // Footer Actions
              Row(
                children: [
                  if (resource.hasExtractedText && resource.extractedText != null)
                    Expanded(
                      child: ZeroButton(
                        label: 'COPY TEXT',
                        variant: ZeroButtonVariant.outline,
                        icon: Icons.copy,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: resource.extractedText!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resource text copied to clipboard',
                                  style: TextStyle(fontFamily: 'monospace')),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            ),
                          );
                        },
                      ),
                    ),
                  if (resource.hasExtractedText && resource.extractedText != null)
                    const SizedBox(width: 10),
                  Expanded(
                    child: ZeroButton(
                      label: 'CLOSE',
                      variant: resource.hasExtractedText
                          ? ZeroButtonVariant.primary
                          : ZeroButtonVariant.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(StudyResource r, bool isDark) {
    String label = 'FILE';
    Color color = AppColors.coral;

    if (r.isPdf) {
      label = 'PDF';
      color = const Color(0xFFEF4444);
    } else if (r.isImage) {
      label = 'IMG';
      color = const Color(0xFF10B981);
    } else if (r.isText) {
      label = 'TXT';
      color = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (resource.hasExtractedText && resource.extractedText?.isNotEmpty == true) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121214) : const Color(0xFFF9FAFB),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: SelectableText(
            resource.extractedText!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return Center(
      child: ZeroCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              resource.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : resource.isImage
                      ? Icons.image_outlined
                      : Icons.insert_drive_file_outlined,
              size: 48,
              color: AppColors.coral,
            ),
            const SizedBox(height: 14),
            Text(
              resource.title.isNotEmpty ? resource.title : resource.fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${resource.mimeType} • ${resource.formattedSize}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            if (resource.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Uploaded ${DateFormat('MMM d, yyyy').format(resource.createdAt!)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
