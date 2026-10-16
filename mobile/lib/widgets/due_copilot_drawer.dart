import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import 'upgrade_plan_dialog.dart';
import 'zero_button.dart';
import 'zero_card.dart';

class DueCopilotDrawer extends StatefulWidget {
  const DueCopilotDrawer({super.key});

  @override
  State<DueCopilotDrawer> createState() => _DueCopilotDrawerState();
}

class _DueCopilotDrawerState extends State<DueCopilotDrawer> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showMentionPicker = false;
  String _mentionFilter = '';

  final List<Map<String, String>> _quickChips = [
    {
      'label': 'Summarize Tasks',
      'prompt': 'Summarize my upcoming coursework assignments and imminent deadlines.',
    },
    {
      'label': 'Weekly Study Plan',
      'prompt': 'Create a structured study roadmap for this week based on my active courses and tasks.',
    },
    {
      'label': 'Exam Prep Tips',
      'prompt': 'What are the most effective Socratic methods to review concept notes for my classes?',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ai = context.read<AiChatProvider>();
      ai.fetchMessages();
      ai.fetchMentionables();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleTextChange(String value) {
    final cursor = _promptController.selection.baseOffset;
    if (cursor < 0) return;

    final textBefore = value.substring(0, cursor);
    final atIndex = textBefore.lastIndexOf('@');

    if (atIndex != -1) {
      final query = textBefore.substring(atIndex + 1);
      if (!query.contains('\n') && query.length <= 30) {
        setState(() {
          _showMentionPicker = true;
          _mentionFilter = query.toLowerCase();
        });
        return;
      }
    }

    if (_showMentionPicker) {
      setState(() {
        _showMentionPicker = false;
        _mentionFilter = '';
      });
    }
  }

  void _selectMention(MentionItem item) {
    final ai = context.read<AiChatProvider>();
    ai.addMention(item);

    final text = _promptController.text;
    final cursor = _promptController.selection.baseOffset;
    final textBefore = cursor >= 0 ? text.substring(0, cursor) : text;
    final atIndex = textBefore.lastIndexOf('@');

    String newText;
    int newPos;

    if (atIndex != -1) {
      final beforeAt = text.substring(0, atIndex);
      final afterCursor = cursor >= 0 ? text.substring(cursor) : '';
      newText = '$beforeAt@${item.name} $afterCursor';
      newPos = beforeAt.length + item.name.length + 2;
    } else {
      newText = '$text@${item.name} ';
      newPos = newText.length;
    }

    _promptController.text = newText;
    _promptController.selection = TextSelection.collapsed(offset: newPos);

    setState(() {
      _showMentionPicker = false;
      _mentionFilter = '';
    });

    _focusNode.requestFocus();
  }

  Future<void> _handleSend([String? preset]) async {
    final text = preset ?? _promptController.text;
    if (text.trim().isEmpty) return;

    _promptController.clear();
    setState(() {
      _showMentionPicker = false;
    });

    _scrollToBottom();
    await context.read<AiChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'Clear Conversation?',
          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to clear this study conversation? All active context will be reset.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AiChatProvider>().clearHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subProvider = context.watch<SubscriptionProvider>();
    final aiProvider = context.watch<AiChatProvider>();
    final canUseAi = subProvider.canUseAi;
    final screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      width: screenWidth,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              _buildHeader(context, isDark, aiProvider),

              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),

              // Active Assignment Focus Bar (if any)
              if (aiProvider.currentAssignmentTitle != null)
                _buildFocusBar(context, isDark, aiProvider),

              // Active Context Sources Bar
              _buildContextSourcesBar(context, isDark, aiProvider),

              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),

              // Chat Body / Messages
              Expanded(
                child: !canUseAi
                    ? _buildLockedView(context, isDark)
                    : _buildMessagesView(context, isDark, aiProvider),
              ),

              // Mentions Autocomplete Floating Dropdown (if triggered)
              if (canUseAi && _showMentionPicker)
                _buildMentionDropdown(context, isDark, aiProvider),

              // Footer Composer (Guaranteed above soft keyboard)
              if (canUseAi)
                _buildComposer(context, isDark, aiProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AiChatProvider ai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            color: AppColors.coral.withValues(alpha: 0.15),
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.coral, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    const Text(
                      'DUE COPILOT',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.coral.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Gemini 2.5 Flash',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  ai.currentAssignmentTitle != null
                      ? 'Focused: ${ai.currentAssignmentTitle}'
                      : 'Workspace Study Partner',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          if (ai.totalTokens > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                '${ai.totalTokens}t',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ),
          ],
          if (ai.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Clear history',
              color: AppColors.danger,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: _handleClear,
            ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: 'Close Copilot',
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusBar(BuildContext context, bool isDark, AiChatProvider ai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: AppColors.coral.withValues(alpha: 0.08),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            color: AppColors.coral,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Focused: ${ai.currentAssignmentTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.coral,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ai.setFocus(null),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'UNFOCUS',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextSourcesBar(BuildContext context, bool isDark, AiChatProvider ai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              'CONTEXT: ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            if (ai.contextSources.isEmpty)
              Text(
                'Workspace overview',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              )
            else
              ...ai.contextSources.map((src) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                      color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description_outlined, size: 10, color: AppColors.coral),
                        const SizedBox(width: 4),
                        Text(
                          src,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedView(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              color: AppColors.coral.withValues(alpha: 0.15),
              child: const Icon(Icons.lock_outline, size: 26, color: AppColors.coral),
            ),
            const SizedBox(height: 16),
            const Text(
              'DUE COPILOT REQUIRES GENIUS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock 24/7 personal academic tutoring with Gemini 2.5 Flash. Mention courses and assignments with @ for instant outlines, summaries, and exam prep.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ZeroButton(
              label: 'UPGRADE TO GENIUS (\$9.99/MO)',
              icon: Icons.bolt,
              onPressed: () => UpgradePlanDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesView(BuildContext context, bool isDark, AiChatProvider ai) {
    if (ai.isLoading && ai.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
            SizedBox(height: 12),
            Text(
              'Loading Due Copilot...',
              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (ai.messages.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 44,
              height: 44,
              color: AppColors.coral.withValues(alpha: 0.15),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.coral, size: 24),
            ),
            const SizedBox(height: 12),
            const Text(
              'HOW CAN I HELP YOU TODAY?',
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type @ to reference any course or assignment directly in your query.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Quick Starter Chips
            ..._quickChips.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _handleSend(c['prompt']),
                  child: ZeroCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flash_on, size: 14, color: AppColors.coral),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                c['label']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['prompt']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(14),
      itemCount: ai.messages.length + (ai.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == ai.messages.length) {
          return _buildThinkingIndicator(isDark);
        }

        final msg = ai.messages[index];
        return _buildMessageBubble(context, msg, isDark);
      },
    );
  }

  Widget _buildThinkingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            color: AppColors.coral.withValues(alpha: 0.15),
            child: const Icon(Icons.smart_toy_outlined, color: AppColors.coral, size: 14),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Thinking & analyzing context...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, AiMessage msg, bool isDark) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              color: AppColors.coral.withValues(alpha: 0.15),
              child: const Icon(Icons.smart_toy_outlined, color: AppColors.coral, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? const Color(0xFF1E1E22) : const Color(0xFFE8E8EC))
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                border: Border.all(
                  color: isUser
                      ? (isDark ? const Color(0xFF323238) : const Color(0xFFCCCCCC))
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isUser ? 'YOU' : 'DUE COPILOT',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ),
                      if (msg.tokensUsed > 0)
                        Text(
                          '${msg.tokensUsed}t',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
              child: const Icon(Icons.person_outline, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMentionDropdown(BuildContext context, bool isDark, AiChatProvider ai) {
    final matches = ai.mentionables.where((item) {
      if (_mentionFilter.isEmpty) return true;
      return item.name.toLowerCase().contains(_mentionFilter) ||
          (item.courseName?.toLowerCase().contains(_mentionFilter) ?? false);
    }).take(8).toList();

    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: (screenHeight * 0.25).clamp(100.0, 160.0)),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            child: const Text(
              'MENTION COURSE OR ASSIGNMENT (@)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.coral,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: matches.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              itemBuilder: (context, idx) {
                final item = matches[idx];
                final isCourse = item.isCourse;

                return InkWell(
                  onTap: () => _selectMention(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCourse
                                ? AppColors.info.withValues(alpha: 0.15)
                                : AppColors.success.withValues(alpha: 0.15),
                            border: Border.all(
                              color: isCourse
                                  ? AppColors.info.withValues(alpha: 0.4)
                                  : AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            isCourse ? 'COURSE' : 'TASK',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCourse ? AppColors.info : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (item.detail != null)
                                Text(
                                  item.detail!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context, bool isDark, AiChatProvider ai) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final effectiveBottom = bottomInset > 0 ? bottomInset + 8 : paddingBottom + 10;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, effectiveBottom),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Mention Chips Row
          if (ai.activeMentions.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'REFERENCED: ',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  ...ai.activeMentions.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              m.isCourse ? Icons.school_outlined : Icons.check_box_outlined,
                              size: 11,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 120),
                              child: Text(
                                m.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.coral,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            InkWell(
                              onTap: () => ai.removeMention(m.id, m.type),
                              child: const Icon(Icons.close, size: 12, color: AppColors.coral),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // @ Mention Picker Button
              IconButton(
                icon: const Icon(Icons.alternate_email, size: 20),
                tooltip: 'Mention course or task (@)',
                color: _showMentionPicker ? AppColors.coral : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                onPressed: () {
                  setState(() {
                    _showMentionPicker = !_showMentionPicker;
                    _mentionFilter = '';
                  });
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 6),

              // Text Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _promptController,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: _handleTextChange,
                    onSubmitted: (_) => _handleSend(),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ask Due Copilot anything... Type @ to mention',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send Button
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  onPressed: ai.isSending ? null : () => _handleSend(),
                  child: ai.isSending
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
