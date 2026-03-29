import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders MCP tool calls and their results with collapsible input/output.
class ToolBlockWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isResult;

  const ToolBlockWidget({
    super.key,
    required this.data,
    this.isResult = false,
  });

  @override
  State<ToolBlockWidget> createState() => _ToolBlockWidgetState();
}

class _ToolBlockWidgetState extends State<ToolBlockWidget> {
  bool _inputExpanded = false;
  bool _outputExpanded = false;

  String get _toolName => widget.data['name'] as String? ?? 'Unknown Tool';

  String? get _status => widget.data['status'] as String?;

  Map<String, dynamic>? get _input =>
      widget.data['input'] as Map<String, dynamic>?;

  dynamic get _output => widget.data['output'];

  String _formatJson(dynamic data) {
    if (data == null) return '';
    try {
      if (data is String) {
        // Try to parse as JSON for pretty-printing
        final parsed = json.decode(data);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool header
          _buildHeader(context, isDark),
          // Input section
          if (_input != null && _input!.isNotEmpty)
            _buildCollapsibleSection(
              context: context,
              isDark: isDark,
              title: 'Input',
              content: _formatJson(_input),
              isExpanded: _inputExpanded,
              onToggle: () => setState(() => _inputExpanded = !_inputExpanded),
            ),
          // Output section
          if (_output != null)
            _buildCollapsibleSection(
              context: context,
              isDark: isDark,
              title: 'Output',
              content: _output is String
                  ? _output as String
                  : _formatJson(_output),
              isExpanded: _outputExpanded,
              onToggle: () =>
                  setState(() => _outputExpanded = !_outputExpanded),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      child: Row(
        children: [
          // Tool icon
          Container(
            padding: const EdgeInsets.all(ModernDesignSystem.spacingXS + 2),
            decoration: BoxDecoration(
              gradient: ModernDesignSystem.primaryGradient,
              borderRadius: BorderRadius.circular(
                ModernDesignSystem.borderRadiusSmall,
              ),
            ),
            child: const Icon(
              Icons.build_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: ModernDesignSystem.spacingS),
          // Tool name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _toolName,
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.isResult)
                  Text(
                    'Tool Result',
                    style: ModernDesignSystem.caption.copyWith(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          // Status indicator
          _buildStatusIndicator(isDark),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isDark) {
    switch (_status) {
      case 'running':
        return SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(
              ModernDesignSystem.primaryGradient.colors.first,
            ),
          ),
        );
      case 'success':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: ModernDesignSystem.secondaryGradient,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 14,
            color: Colors.white,
          ),
        );
      case 'error':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: ModernDesignSystem.warningGradient,
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 14,
            color: Colors.white,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCollapsibleSection({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String content,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final mutedColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.45);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider
        Container(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        // Section header
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: ModernDesignSystem.caption.copyWith(
                    color: mutedColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: ModernDesignSystem.animationMedium,
                  curve: ModernDesignSystem.animationCurve,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: mutedColor,
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
          child: isExpanded
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    left: ModernDesignSystem.spacingM,
                    right: ModernDesignSystem.spacingM,
                    bottom: ModernDesignSystem.spacingM,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      content,
                      style: ModernDesignSystem.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.black.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
