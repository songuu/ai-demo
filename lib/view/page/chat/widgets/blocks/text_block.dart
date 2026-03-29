import 'package:flutter/material.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders markdown text content with optional streaming cursor animation.
class TextBlockWidget extends StatefulWidget {
  final String content;
  final bool isStreaming;

  const TextBlockWidget({
    super.key,
    required this.content,
    this.isStreaming = false,
  });

  @override
  State<TextBlockWidget> createState() => _TextBlockWidgetState();
}

class _TextBlockWidgetState extends State<TextBlockWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorAnimation;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cursorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cursorController, curve: Curves.easeInOut),
    );
    if (widget.isStreaming) {
      _cursorController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TextBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isStreaming && !oldWidget.isStreaming) {
      _cursorController.repeat(reverse: true);
    } else if (!widget.isStreaming && oldWidget.isStreaming) {
      _cursorController.stop();
      _cursorController.reset();
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionArea(
          child: MarkdownBody(
            data: widget.content,
            selectable: false, // Handled by SelectionArea parent
            softLineBreak: true,
            styleSheet: MarkdownStyleSheet(
              p: ModernDesignSystem.bodyMedium.copyWith(color: textColor),
              h1: ModernDesignSystem.headingLarge.copyWith(color: textColor),
              h2: ModernDesignSystem.headingMedium.copyWith(color: textColor),
              h3: ModernDesignSystem.headingSmall.copyWith(color: textColor),
              code: ModernDesignSystem.bodySmall.copyWith(
                fontFamily: 'monospace',
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.06),
                color: isDark
                    ? const Color(0xFFE06C75)
                    : const Color(0xFFD63384),
              ),
              codeblockDecoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF282C34)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(
                  ModernDesignSystem.borderRadiusSmall,
                ),
              ),
              codeblockPadding: const EdgeInsets.all(
                ModernDesignSystem.spacingM,
              ),
              blockquoteDecoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: ModernDesignSystem.primaryGradient.colors.first,
                    width: 3,
                  ),
                ),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
              ),
              blockquotePadding: const EdgeInsets.symmetric(
                horizontal: ModernDesignSystem.spacingM,
                vertical: ModernDesignSystem.spacingS,
              ),
              listBullet: ModernDesignSystem.bodyMedium.copyWith(
                color: textColor,
              ),
              tableHead: ModernDesignSystem.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              tableBody: ModernDesignSystem.bodyMedium.copyWith(
                color: textColor,
              ),
              tableBorder: TableBorder.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                width: 1,
              ),
              tableCellsPadding: const EdgeInsets.all(
                ModernDesignSystem.spacingS,
              ),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                href.launchUrl();
              }
            },
          ),
        ),
        if (widget.isStreaming) _buildStreamingCursor(),
      ],
    );
  }

  Widget _buildStreamingCursor() {
    return AnimatedBuilder(
      animation: _cursorAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _cursorAnimation.value,
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              '|',
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: ModernDesignSystem.primaryGradient.colors.first,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}
