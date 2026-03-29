import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders a syntax-highlighted code block with language label and copy button.
class CodeBlockWidget extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBlockWidget({
    super.key,
    required this.code,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final highlightTheme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final bgColor = isDark ? const Color(0xFF282C34) : const Color(0xFFF6F8FA);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusSmall,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with language label and copy button
          _buildHeader(context, isDark),
          // Divider
          Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // Code content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
            child: HighlightView(
              code.trimRight(),
              language: language ?? 'plaintext',
              theme: highlightTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernDesignSystem.spacingM,
        vertical: ModernDesignSystem.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Language label
          Text(
            language?.toUpperCase() ?? 'CODE',
            style: ModernDesignSystem.caption.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          // Copy button
          _CopyButton(code: code, isDark: isDark),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String code;
  final bool isDark;

  const _CopyButton({required this.code, required this.isDark});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.45);

    return InkWell(
      onTap: _copyToClipboard,
      borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.all(ModernDesignSystem.spacingXS),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 14,
              color: _copied ? Colors.green : iconColor,
            ),
            const SizedBox(width: ModernDesignSystem.spacingXS),
            Text(
              _copied ? 'Copied' : 'Copy',
              style: ModernDesignSystem.caption.copyWith(
                color: _copied ? Colors.green : iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
