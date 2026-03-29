import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/chat/store/chat_message_store.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/chat/service/chat_stream_manager.dart';
import 'package:server_box/view/page/chat/widgets/model_selector.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ChatInputBar extends StatefulWidget {
  final String conversationId;
  final VoidCallback? onMessageSent;

  const ChatInputBar({
    super.key,
    required this.conversationId,
    this.onMessageSent,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _webSearchEnabled = false;
  bool _mcpToolsEnabled = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isStreaming =>
      ChatStreamManager.isStreaming(widget.conversationId);

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final conversation = ChatConversationStore.byId(widget.conversationId);
    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation not found')),
        );
      }
      return;
    }

    // Check model before saving - show feedback if missing
    final providerId = conversation.providerId;
    final modelId = conversation.modelId;
    if (providerId == null || modelId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a model first')),
        );
        _showModelSelector();
      }
      return;
    }

    final provider = ChatProviderStore.byId(providerId);
    if (provider == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider not configured')),
        );
      }
      return;
    }

    // Create user message
    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversationId,
      role: 'user',
      content: text,
      status: ChatMessageStatus.complete,
    );
    await ChatMessageStore.put(userMsg);

    // Update conversation metadata
    final preview = text.length > 80 ? text.substring(0, 80) : text;
    await ChatConversationStore.put(conversation.copyWith(
      lastMessagePreview: preview,
      messageCount: conversation.messageCount + 1,
      webSearchEnabled: _webSearchEnabled,
    ));

    _textController.clear();
    widget.onMessageSent?.call();

    final history = ChatMessageStore.forConversation(widget.conversationId);

    ChatStreamManager.startStream(
      conversationId: widget.conversationId,
      provider: provider,
      modelId: modelId,
      history: history,
      temperature: conversation.temperature,
      maxTokens: conversation.maxTokens,
      systemPrompt: conversation.systemPrompt,
      webSearch: _webSearchEnabled,
    );
  }

  void _stopStreaming() {
    ChatStreamManager.cancelStream(widget.conversationId);
  }

  void _showModelSelector() async {
    final conversation = ChatConversationStore.byId(widget.conversationId);
    if (conversation == null) return;

    final result = await ModelSelector.show(
      context,
      currentProviderId: conversation.providerId,
      currentModelId: conversation.modelId,
    );

    if (result != null) {
      await ChatConversationStore.put(conversation.copyWith(
        providerId: result.providerId,
        modelId: result.modelId,
      ));
      widget.onMessageSent?.call(); // Refresh to show updated model
    }
  }

  String _getCurrentModelName() {
    final conversation = ChatConversationStore.byId(widget.conversationId);
    if (conversation?.modelId == null) return 'Select model';
    final modelId = conversation!.modelId!;
    if (modelId.length > 22) return '${modelId.substring(0, 19)}...';
    return modelId;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xDD1A1A2E)
                : const Color(0xDDFFFFFF),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: ModernDesignSystem.spacingM,
            right: ModernDesignSystem.spacingM,
            top: ModernDesignSystem.spacingS,
            bottom: MediaQuery.of(context).padding.bottom +
                ModernDesignSystem.spacingS,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle chips row
              _buildToggleChips(isDark, primaryColor),
              const SizedBox(height: ModernDesignSystem.spacingS),
              // Text input row
              _buildInputRow(isDark, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChips(bool isDark, Color primaryColor) {
    return Row(
      children: [
        // Model selector chip
        GestureDetector(
          onTap: _showModelSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingS + 2,
              vertical: ModernDesignSystem.spacingXS,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(
                  ModernDesignSystem.borderRadiusSmall),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  _getCurrentModelName(),
                  style: ModernDesignSystem.caption.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.expand_more, size: 14, color: primaryColor),
              ],
            ),
          ),
        ),
        const SizedBox(width: ModernDesignSystem.spacingS),
        // Web search toggle
        _ToggleChip(
          icon: Icons.language,
          label: 'Web',
          isEnabled: _webSearchEnabled,
          isDark: isDark,
          primaryColor: primaryColor,
          onTap: () => setState(() => _webSearchEnabled = !_webSearchEnabled),
        ),
        const SizedBox(width: ModernDesignSystem.spacingS),
        // MCP tools toggle
        _ToggleChip(
          icon: Icons.build_outlined,
          label: 'MCP',
          isEnabled: _mcpToolsEnabled,
          isDark: isDark,
          primaryColor: primaryColor,
          onTap: () => setState(() => _mcpToolsEnabled = !_mcpToolsEnabled),
        ),
      ],
    );
  }

  Widget _buildInputRow(bool isDark, Color primaryColor) {
    const sendButtonSize = 44.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: sendButtonSize),
            child: Container(
              decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(
                  ModernDesignSystem.borderRadiusMedium),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
              child: Focus(
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 6,
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: ModernDesignSystem.bodyMedium.copyWith(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: ModernDesignSystem.spacingM,
                      vertical: ModernDesignSystem.spacingS + 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: ModernDesignSystem.spacingS),
        // Send / Stop button
        ValueListenableBuilder<int>(
          valueListenable: ChatStreamManager.streamStateChanged,
          builder: (context, _, __) {
            final streaming = _isStreaming;
            return Container(
              width: sendButtonSize,
              height: sendButtonSize,
              decoration: BoxDecoration(
                gradient: streaming
                    ? ModernDesignSystem.warningGradient
                    : ModernDesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(
                    ModernDesignSystem.borderRadiusSmall + 4),
                boxShadow: ModernDesignSystem.glowShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: streaming ? _stopStreaming : _sendMessage,
                  borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusSmall + 4),
                  child: Icon(
                    streaming ? Icons.stop_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingS,
          vertical: ModernDesignSystem.spacingXS,
        ),
        decoration: BoxDecoration(
          color: isEnabled
              ? primaryColor.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          border: Border.all(
            color: isEnabled
                ? primaryColor.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isEnabled
                  ? primaryColor
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.35)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: ModernDesignSystem.caption.copyWith(
                color: isEnabled
                    ? primaryColor
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.35)),
                fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
