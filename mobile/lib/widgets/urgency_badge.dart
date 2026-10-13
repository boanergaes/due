import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UrgencyBadge extends StatelessWidget {
  final String label;
  final String? color;
  final bool isOverdue;

  const UrgencyBadge({
    super.key,
    required this.label,
    this.color,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    final normalized = label.toUpperCase();

    if (isOverdue || normalized.contains('OVERDUE')) {
      textColor = AppColors.danger;
      bgColor = AppColors.danger.withValues(alpha: 0.12);
      borderColor = AppColors.danger.withValues(alpha: 0.35);
    } else if (normalized.contains('TODAY')) {
      textColor = AppColors.coral;
      bgColor = AppColors.coral.withValues(alpha: 0.12);
      borderColor = AppColors.coral.withValues(alpha: 0.35);
    } else if (normalized.contains('SOON')) {
      textColor = AppColors.warning;
      bgColor = AppColors.warning.withValues(alpha: 0.12);
      borderColor = AppColors.warning.withValues(alpha: 0.35);
    } else {
      textColor = AppColors.darkTextSecondary;
      bgColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white.withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: textColor,
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
