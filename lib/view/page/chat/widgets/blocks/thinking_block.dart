import 'package:flutter/material.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders a collapsible thinking/reasoning section with a left accent border.
class ThinkingBlockWidget extends StatefulWidget {
  final String content;

  const ThinkingBlockWidget({
    super.key,
    required this.content,
  });

  @override
  State<ThinkingBlockWidget> createState() => _ThinkingBlockWidgetState();
}

class _ThinkingBlockWidgetState extends State<ThinkingBlockWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedTextColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.45);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusSmall,
        ),
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left gradient accent border
            Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: ModernDesignSystem.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    ModernDesignSystem.borderRadiusSmall,
                  ),
                  bottomLeft: Radius.circular(
                    ModernDesignSystem.borderRadiusSmall,
                  ),
                ),
              ),
            ),
            // Content area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (always visible)
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusSmall,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ModernDesignSystem.spacingM,
                        vertical: ModernDesignSystem.spacingS,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: ModernDesignSystem
                                .primaryGradient.colors.first,
                          ),
                          const SizedBox(width: ModernDesignSystem.spacingS),
                          Expanded(
                            child: Text(
                              'Thinking...',
                              style:
                                  ModernDesignSystem.bodySmall.copyWith(
                                color: mutedTextColor,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0.0,
                            duration: ModernDesignSystem.animationMedium,
                            curve: ModernDesignSystem.animationCurve,
                            child: Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expandable content
                  AnimatedSize(
                    duration: ModernDesignSystem.animationMedium,
                    curve: ModernDesignSystem.animationCurve,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(
                              left: ModernDesignSystem.spacingM,
                              right: ModernDesignSystem.spacingM,
                              bottom: ModernDesignSystem.spacingM,
                            ),
                            child: SelectableText(
                              widget.content,
                              style:
                                  ModernDesignSystem.bodySmall.copyWith(
                                color: mutedTextColor,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
