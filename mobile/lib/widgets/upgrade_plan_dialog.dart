import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_colors.dart';
import 'zero_button.dart';
import 'zero_card.dart';
import 'zero_text_field.dart';

class UpgradePlanDialog extends StatefulWidget {
  final String? initialTier;
  final String? featureRequired;

  const UpgradePlanDialog({
    super.key,
    this.initialTier,
    this.featureRequired,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialTier,
    String? featureRequired,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => UpgradePlanDialog(
        initialTier: initialTier,
        featureRequired: featureRequired,
      ),
    );
  }

  @override
  State<UpgradePlanDialog> createState() => _UpgradePlanDialogState();
}

class _UpgradePlanDialogState extends State<UpgradePlanDialog> {
  late String _selectedTier;
  String _selectedInterval = 'monthly';
  int _step = 0; // 0: select & card details, 1: processing

  String _processingStage = 'Authorizing Card...';

  final _cardholderController = TextEditingController(text: 'Student User');
  final _cardNumberController = TextEditingController(text: '4242 4242 4242 4242');
  final _expController = TextEditingController(text: '12/28');
  final _cvcController = TextEditingController(text: '123');

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier ?? (widget.featureRequired == 'ai' ? 'premium' : 'basic');
  }

  @override
  void dispose() {
    _cardholderController.dispose();
    _cardNumberController.dispose();
    _expController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckout() async {
    setState(() {
      _step = 1;
      _processingStage = 'Authorizing Card...';
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _processingStage = 'Creating Secure Token...';
    });

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    setState(() {
      _processingStage = 'Activating Plan...';
    });

    final expParts = _expController.text.split('/');
    final expMonth = expParts.isNotEmpty ? expParts[0].trim() : '12';
    final expYear = expParts.length > 1 ? expParts[1].trim() : '28';

    final subProvider = context.read<SubscriptionProvider>();
    final success = await subProvider.checkout(
      tier: _selectedTier,
      interval: _selectedInterval,
      cardholderName: _cardholderController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      expMonth: expMonth,
      expYear: expYear,
      cvc: _cvcController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome to ${_selectedTier == 'premium' ? 'Genius' : 'Scholar'} Tier! Features unlocked.',
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    } else {
      setState(() {
        _step = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subProvider.errorMessage ?? 'Subscription upgrade failed',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _step == 1
              ? _buildProcessingView(isDark)
              : _buildFormView(isDark),
        ),
      ),
    );
  }

  Widget _buildProcessingView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _processingStage.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Simulating zero-DB-query cryptographic provisioning...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFormView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  color: AppColors.coral,
                  margin: const EdgeInsets.only(right: 8),
                ),
                const Text(
                  'UPGRADE SUBSCRIPTION',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Unlock study resources storage and Gemini-powered assignment copilot.',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // Interval Toggle (Monthly / Annual)
        Row(
          children: [
            Expanded(
              child: _buildIntervalSegment('monthly', 'MONTHLY BILLING', isDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildIntervalSegment('annual', 'ANNUAL (SAVE 18%)', isDark),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tier Selection Cards
        Row(
          children: [
            Expanded(
              child: _buildTierCard(
                tier: 'basic',
                name: 'SCHOLAR',
                price: _selectedInterval == 'monthly' ? '\$4.99' : '\$49.00',
                period: _selectedInterval == 'monthly' ? '/mo' : '/yr',
                badge: 'RESOURCES',
                features: ['Unlimited Files', '500 MB Storage', 'In-App Viewers'],
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTierCard(
                tier: 'premium',
                name: 'GENIUS',
                price: _selectedInterval == 'monthly' ? '\$9.99' : '\$99.00',
                period: _selectedInterval == 'monthly' ? '/mo' : '/yr',
                badge: 'GEMINI AI',
                features: ['All Scholar perks', 'Gemini AI Copilot', '5 GB Fast Storage'],
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Simulated Test Payment Form
        ZeroCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TEST PAYMENT METHOD',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.coral.withValues(alpha: 0.15),
                    child: const Text(
                      'SIMULATED',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ZeroTextField(
                label: 'CARDHOLDER NAME',
                controller: _cardholderController,
              ),
              const SizedBox(height: 8),
              ZeroTextField(
                label: 'CARD NUMBER',
                controller: _cardNumberController,
                prefixIcon: const Icon(Icons.credit_card, size: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ZeroTextField(
                      label: 'EXPIRY',
                      hintText: 'MM/YY',
                      controller: _expController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZeroTextField(
                      label: 'CVC',
                      hintText: '123',
                      controller: _cvcController,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Submit Button
        ZeroButton(
          label: _selectedTier == 'premium'
              ? 'ACTIVATE GENIUS TIER'
              : 'ACTIVATE SCHOLAR TIER',
          icon: Icons.bolt,
          onPressed: _handleCheckout,
        ),
      ],
    );
  }

  Widget _buildIntervalSegment(String interval, String label, bool isDark) {
    final isSelected = _selectedInterval == interval;
    return GestureDetector(
      onTap: () => setState(() => _selectedInterval = interval),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.coral.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover),
          border: Border.all(
            color: isSelected ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                ? AppColors.coral
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String tier,
    required String name,
    required String price,
    required String period,
    required String badge,
    required List<String> features,
    required bool isDark,
  }) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF221516) : const Color(0xFFFFF1F0))
              : (isDark ? AppColors.darkSurfaceHover : AppColors.lightSurfaceHover),
          border: Border.all(
            color: isSelected ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? AppColors.coral : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.coral : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  period,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 12, color: AppColors.coral),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
