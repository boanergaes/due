import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/study_resource.dart';
import '../providers/resource_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import 'confirm_dialog.dart';
import 'resource_preview_modal.dart';
import 'upgrade_plan_dialog.dart';
import 'zero_button.dart';
import 'zero_card.dart';

class ResourceListWidget extends StatefulWidget {
  final String resourceableType; // 'class' or 'assignment'
  final int resourceableId;
  final String title;

  const ResourceListWidget({
    super.key,
    required this.resourceableType,
    required this.resourceableId,
    this.title = 'STUDY RESOURCES',
  });

  @override
  State<ResourceListWidget> createState() => _ResourceListWidgetState();
}

class _ResourceListWidgetState extends State<ResourceListWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ResourceProvider>().fetchResources(
            type: widget.resourceableType,
            id: widget.resourceableId,
          );
    });
  }

  Future<void> _handleUpload() async {
    final subProvider = context.read<SubscriptionProvider>();
    if (!subProvider.canUploadResources) {
      final upgraded = await UpgradePlanDialog.show(
        context,
        initialTier: 'basic',
        featureRequired: 'resources',
      );
      if (upgraded != true) return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'webp',
          'txt',
          'md',
          'doc',
          'docx',
          'zip',
        ],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (!mounted) return;

      final resourceProvider = context.read<ResourceProvider>();
      final uploaded = await resourceProvider.uploadResource(
        type: widget.resourceableType,
        id: widget.resourceableId,
        title: pickedFile.name,
        filePath: pickedFile.path,
        fileBytes: pickedFile.bytes,
        fileName: pickedFile.name,
      );

      if (!mounted) return;

      if (uploaded != null) {
        // Also refresh subscription to reflect storage usage update
        context.read<SubscriptionProvider>().fetchSubscription();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Uploaded "${pickedFile.name}"',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resourceProvider.uploadError ?? 'Failed to upload resource',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'File picker error: $e',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _handleDelete(StudyResource resource) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Resource?',
      message: 'Are you sure you want to remove "${resource.title}"? Your storage quota will be freed up.',
      confirmText: 'DELETE FILE',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ResourceProvider>().deleteResource(
            resource.id,
            type: widget.resourceableType,
            parentId: widget.resourceableId,
          );

      if (!mounted) return;

      if (success) {
        context.read<SubscriptionProvider>().fetchSubscription();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted "${resource.title}"',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resourceProvider = context.watch<ResourceProvider>();
    final resources = resourceProvider.getResources(
      widget.resourceableType,
      widget.resourceableId,
    );
    final isLoading = resourceProvider.isLoading(
      widget.resourceableType,
      widget.resourceableId,
    );
    final isUploading = resourceProvider.isUploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
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
                Text(
                  '${widget.title} (${resources.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: isUploading ? null : _handleUpload,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUploading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                        ),
                      )
                    else ...[
                      const Icon(Icons.upload_file, size: 14, color: AppColors.coral),
                      const SizedBox(width: 4),
                      const Text(
                        'UPLOAD FILE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (isLoading && resources.isEmpty)
          ZeroCard(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading study files...',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (resources.isEmpty)
          ZeroCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 28,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'No study files uploaded yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Attach PDFs, slides, diagrams, notes or lab files.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ZeroButton(
                  label: 'ATTACH FILE',
                  icon: Icons.add,
                  variant: ZeroButtonVariant.outline,
                  onPressed: _handleUpload,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resources.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final r = resources[index];
              return ZeroCard(
                padding: const EdgeInsets.all(12),
                onTap: () => ResourcePreviewModal.show(context, r),
                child: Row(
                  children: [
                    _buildBadge(r),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title.isNotEmpty ? r.title : r.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                r.formattedSize,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              if (r.createdAt != null) ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d').format(r.createdAt!),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                              if (r.hasExtractedText) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  color: AppColors.coral.withValues(alpha: 0.12),
                                  child: const Text(
                                    'AI READY',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                      tooltip: 'Preview Resource',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => ResourcePreviewModal.show(context, r),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 16, color: AppColors.danger),
                      tooltip: 'Delete Resource',
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () => _handleDelete(r),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBadge(StudyResource r) {
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
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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
}
