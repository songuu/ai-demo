import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/view/page/chat/widgets/blocks/text_block.dart';
import 'package:server_box/view/page/chat/widgets/blocks/code_block.dart';
import 'package:server_box/view/page/chat/widgets/blocks/thinking_block.dart';
import 'package:server_box/view/page/chat/widgets/blocks/tool_block.dart';
import 'package:server_box/view/page/chat/widgets/blocks/citation_block.dart';
import 'package:server_box/view/page/chat/widgets/blocks/error_block.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isStreaming;
  final VoidCallback? onDelete;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.onDelete,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingM,
          vertical: ModernDesignSystem.spacingS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) _buildAvatar(context, isUser),
            if (!isUser)
              const SizedBox(width: ModernDesignSystem.spacingS),
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildContentBubble(context, isUser, isDark, primaryColor),
                  if (_isHovering || widget.message.isError)
                    _buildActionRow(context, isUser, isDark, primaryColor),
                ],
              ),
            ),
            if (isUser)
              const SizedBox(width: ModernDesignSystem.spacingS),
            if (isUser) _buildAvatar(context, isUser),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: isUser ? ModernDesignSystem.primaryGradient : null,
        color: isUser
            ? null
            : (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06)),
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 18,
        color: isUser
            ? Colors.white
            : (isDark ? primaryColor : primaryColor),
      ),
    );
  }

  Widget _buildContentBubble(
    BuildContext context,
    bool isUser,
    bool isDark,
    Color primaryColor,
  ) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final isError = widget.message.isError;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      decoration: BoxDecoration(
        gradient: isUser ? ModernDesignSystem.primaryGradient : null,
        color: isUser
            ? null
            : (isError
                ? (isDark
                    ? const Color(0xFFFF8A80).withValues(alpha: 0.1)
                    : const Color(0xFFE57373).withValues(alpha: 0.08))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04))),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(ModernDesignSystem.borderRadiusMedium),
          topRight:
              const Radius.circular(ModernDesignSystem.borderRadiusMedium),
          bottomLeft: Radius.circular(
              isUser ? ModernDesignSystem.borderRadiusMedium : 4),
          bottomRight: Radius.circular(
              isUser ? 4 : ModernDesignSystem.borderRadiusMedium),
        ),
        border: isUser
            ? null
            : Border.all(
                color: isError
                    ? (isDark
                        ? const Color(0xFFFF8A80).withValues(alpha: 0.3)
                        : const Color(0xFFE57373).withValues(alpha: 0.35))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06)),
              ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? primaryColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildContent(isUser, isDark),
    );
  }

  Widget _buildContent(bool isUser, bool isDark) {
    final message = widget.message;
    final textColor = isUser ? Colors.white : null;

    // If message has structured blocks, render them
    if (message.blocks.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < message.blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: ModernDesignSystem.spacingS),
            _buildBlock(message.blocks[i], isUser, isDark),
          ],
        ],
      );
    }

    // Fallback: render content as text/markdown
    if (message.content.isEmpty && widget.isStreaming) {
      return _buildStreamingPlaceholder();
    }

    if (isUser) {
      // User messages displayed as plain text with white color
      return Text(
        message.content,
        style: ModernDesignSystem.bodyMedium.copyWith(
          color: textColor,
        ),
      );
    }

    // Assistant text rendered as markdown
    return TextBlockWidget(
      content: message.content,
      isStreaming: widget.isStreaming,
    );
  }

  Widget _buildBlock(
      Map<String, dynamic> block, bool isUser, bool isDark) {
    final type = block['type'] as String? ?? '';
    final content = block['content'] as String? ?? '';

    switch (type) {
      case ChatBlockType.text:
        if (isUser) {
          return Text(
            content,
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: Colors.white,
            ),
          );
        }
        return TextBlockWidget(
          content: content,
          isStreaming: widget.isStreaming &&
              block == widget.message.blocks.last,
        );

      case ChatBlockType.code:
        return CodeBlockWidget(
          code: content,
          language: block['language'] as String?,
        );

      case ChatBlockType.thinking:
        return ThinkingBlockWidget(
          content: content,
        );

      case ChatBlockType.toolUse:
        return ToolBlockWidget(
          data: block,
        );

      case ChatBlockType.toolResult:
        return ToolBlockWidget(
          data: block,
          isResult: true,
        );

      case ChatBlockType.citation:
        return CitationBlockWidget(
          data: block,
        );

      case ChatBlockType.error:
        return ErrorBlockWidget(message: content);

      case ChatBlockType.image:
        // Placeholder for image support
        return Container(
          padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius:
                BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined,
                  size: 18,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4)),
              const SizedBox(width: ModernDesignSystem.spacingS),
              Text(
                'Image',
                style: ModernDesignSystem.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        );

      default:
        // Unknown block type - render content as text
        if (content.isNotEmpty) {
          return Text(
            content,
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: isUser ? Colors.white : null,
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  Widget _buildStreamingPlaceholder() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ModernDesignSystem.primaryGradient.colors.first,
          ),
        ),
        const SizedBox(width: ModernDesignSystem.spacingS),
        Text(
          'Thinking...',
          style: ModernDesignSystem.bodySmall.copyWith(
            color: ModernDesignSystem.primaryGradient.colors.first,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    bool isUser,
    bool isDark,
    Color primaryColor,
  ) {
    final timestamp = _formatTime(widget.message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(top: ModernDesignSystem.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timestamp,
            style: ModernDesignSystem.caption.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: ModernDesignSystem.spacingS),
          _ActionIconButton(
            icon: Icons.copy_outlined,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: widget.message.displayContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            isDark: isDark,
          ),
          if (widget.onDelete != null)
            _ActionIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Delete',
              onPressed: widget.onDelete,
              isDark: isDark,
              isDestructive: true,
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isDark;
  final bool isDestructive;

  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? ModernDesignSystem.warningGradient.colors.first
        : (isDark
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.35));

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
