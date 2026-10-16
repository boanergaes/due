import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../models/assignment.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import 'upgrade_plan_dialog.dart';
import 'zero_button.dart';
import 'zero_card.dart';

class AssignmentAiChatSheet extends StatefulWidget {
  final Assignment assignment;

  const AssignmentAiChatSheet({
    super.key,
    required this.assignment,
  });

  static Future<void> show(BuildContext context, Assignment assignment) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AssignmentAiChatSheet(assignment: assignment),
    );
  }

  @override
  State<AssignmentAiChatSheet> createState() => _AssignmentAiChatSheetState();
}

class _AssignmentAiChatSheetState extends State<AssignmentAiChatSheet> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    'Summarize assignment requirements',
    'Break this down into milestones',
    'Explain attached resources',
    'Review notes for edge cases',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ai = context.read<AiChatProvider>();
      ai.setFocus(widget.assignment.id, title: widget.assignment.title);
      ai.fetchMessages();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
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

  Future<void> _handleSend([String? preset]) async {
    final text = preset ?? _promptController.text;
    if (text.trim().isEmpty) return;

    _promptController.clear();
    _scrollToBottom();

    await context.read<AiChatProvider>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _handleClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will delete all previous messages for this assignment tutor session.',
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
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AiChatProvider>().clearHistory(widget.assignment.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subProvider = context.watch<SubscriptionProvider>();
    final aiProvider = context.watch<AiChatProvider>();
    final canUseAi = subProvider.canUseAi;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        border: const Border(
          top: BorderSide(color: AppColors.darkBorder, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Bar
            _buildHeader(context, isDark, aiProvider),

            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            // Content
            Expanded(
              child: !canUseAi
                  ? _buildLockedGeniusView(context, isDark)
                  : _buildChatView(context, isDark, aiProvider),
            ),

            if (canUseAi)
              _buildInputBar(context, isDark, aiProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, AiChatProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            color: AppColors.coral,
            margin: const EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'DUE COPILOT',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      color: AppColors.coral.withValues(alpha: 0.15),
                      child: const Text(
                        'GEMINI 1.5 FLASH',
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
                const SizedBox(height: 2),
                Text(
                  aiProvider.contextSources.isNotEmpty
                      ? 'Grounded in: ${aiProvider.contextSources.join(", ")}'
                      : widget.assignment.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (aiProvider.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 20),
              tooltip: 'Clear History',
              onPressed: _handleClear,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Close Copilot',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedGeniusView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ZeroCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                color: AppColors.coral.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 26,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'GENIUS TIER REQUIRED',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Due Copilot is powered by Google Gemini. It analyzes your assignment instructions, attached notes, and uploaded resource files to provide 24/7 personalized Socratic study guidance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ZeroButton(
                label: 'UPGRADE TO GENIUS (\$9.99/MO)',
                icon: Icons.bolt,
                onPressed: () async {
                  await UpgradePlanDialog.show(
                    context,
                    initialTier: 'premium',
                    featureRequired: 'ai',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatView(BuildContext context, bool isDark, AiChatProvider aiProvider) {
    if (aiProvider.isLoading && aiProvider.messages.isEmpty) {
      return Center(
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
              'Loading study session...',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Intro banner
        ZeroCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.coral),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Due Copilot acts as an academic tutor. Ask for conceptual explanations, milestone breakdowns, or study outlines.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Suggested prompt chips if messages are few
        if (aiProvider.messages.isEmpty) ...[
          const Text(
            'SUGGESTED PROMPTS',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _suggestedPrompts.map((p) {
              return GestureDetector(
                onTap: () => _handleSend(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.north_east, size: 12, color: AppColors.coral),
                      const SizedBox(width: 6),
                      Text(
                        p,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Message Bubbles
        ...aiProvider.messages.map((m) => _buildMessageBubble(m, isDark)),

        if (aiProvider.isSending) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                color: AppColors.coral,
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analyzing assignment context...',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMessageBubble(AiMessage m, bool isDark) {
    final isUser = m.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              color: AppColors.coral,
              margin: const EdgeInsets.only(right: 8, top: 2),
              child: const Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? const Color(0xFF231616) : const Color(0xFFFFF1F0))
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                border: Border.all(
                  color: isUser
                      ? AppColors.coral.withValues(alpha: 0.5)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    m.content,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontFamily: !isUser && m.content.contains('```') ? 'monospace' : null,
                    ),
                  ),
                  if (m.tokensUsed > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${m.tokensUsed} tokens',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, bool isDark, AiChatProvider aiProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask Due Copilot a question...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppColors.coral, width: 1.5),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            width: 42,
            child: Material(
              color: AppColors.coral,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              child: InkWell(
                onTap: aiProvider.isSending ? null : () => _handleSend(),
                borderRadius: BorderRadius.zero,
                child: const Center(
                  child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
