import 'package:flutter/material.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders an error message with a red-tinted card appearance.
class ErrorBlockWidget extends StatelessWidget {
  final String message;

  const ErrorBlockWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFC62828);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: ModernDesignSystem.spacingM,
        vertical: ModernDesignSystem.spacingS + 2,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? errorColor.withValues(alpha: 0.12)
            : errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusSmall,
        ),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: errorColor.withValues(alpha: 0.9),
          ),
          const SizedBox(width: ModernDesignSystem.spacingS),
          Expanded(
            child: SelectableText(
              message,
              style: ModernDesignSystem.bodySmall.copyWith(
                color: errorColor,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
