import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ZeroButtonVariant { primary, outline, danger }

class ZeroButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ZeroButtonVariant variant;
  final IconData? icon;
  final double? width;

  const ZeroButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = ZeroButtonVariant.primary,
    this.icon,
    this.width,
  });


  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case ZeroButtonVariant.primary:
        backgroundColor = AppColors.coral;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
      case ZeroButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = Theme.of(context).colorScheme.onSurface;
        borderSide = BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkBorder
              : AppColors.lightBorder,
          width: 1,
        );
        break;
      case ZeroButtonVariant.danger:
        backgroundColor = AppColors.danger;
        foregroundColor = Colors.white;
        borderSide = BorderSide.none;
        break;
    }

    final child = isLoading
        ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: foregroundColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          );

    return SizedBox(
      width: width,
      height: 44,
      child: Material(
        color: onPressed == null || isLoading
            ? backgroundColor.withValues(alpha: 0.5)
            : backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: borderSide,
        ),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
