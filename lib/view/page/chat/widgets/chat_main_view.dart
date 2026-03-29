import 'package:flutter/material.dart';
import 'package:server_box/chat/model/chat_conversation.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/chat/service/chat_stream_manager.dart';
import 'package:server_box/view/page/chat/widgets/message_list_view.dart';
import 'package:server_box/view/page/chat/widgets/chat_input_bar.dart';
import 'package:server_box/view/page/chat/provider_config_page.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ChatMainView extends StatelessWidget {
  final ValueNotifier<String?> currentConversationId;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNewConversation;

  const ChatMainView({
    super.key,
    required this.currentConversationId,
    this.onMenuPressed,
    this.onNewConversation,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: currentConversationId,
      builder: (context, conversationId, _) {
        if (conversationId == null) {
          return _buildEmptyState(context);
        }
        return _ChatActiveView(
          conversationId: conversationId,
          onMenuPressed: onMenuPressed,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return Scaffold(
      appBar: AppBar(
        leading: onMenuPressed != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuPressed,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Provider settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProviderConfigPage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusLarge + 8),
                  boxShadow: [
                    ...ModernDesignSystem.glowShadow,
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: ModernDesignSystem.spacingL),
              Text(
                'Start a new conversation',
                style: ModernDesignSystem.headingSmall.copyWith(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: ModernDesignSystem.spacingS),
              Text(
                'Select a conversation from the sidebar\nor create a new one to get started.',
                textAlign: TextAlign.center,
                style: ModernDesignSystem.bodyMedium.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                  height: 1.5,
                ),
              ),
              if (onNewConversation != null) ...[
                const SizedBox(height: ModernDesignSystem.spacingL),
                SizedBox(
                  height: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ModernDesignSystem.primaryGradient,
                      borderRadius: BorderRadius.circular(
                          ModernDesignSystem.borderRadiusSmall),
                      boxShadow: ModernDesignSystem.glowShadow,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onNewConversation,
                        borderRadius: BorderRadius.circular(
                            ModernDesignSystem.borderRadiusSmall),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ModernDesignSystem.spacingL,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(
                                  width: ModernDesignSystem.spacingS),
                              Text(
                                'New Chat',
                                style: ModernDesignSystem.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatActiveView extends StatefulWidget {
  final String conversationId;
  final VoidCallback? onMenuPressed;

  const _ChatActiveView({
    required this.conversationId,
    this.onMenuPressed,
  });

  @override
  State<_ChatActiveView> createState() => _ChatActiveViewState();
}

class _ChatActiveViewState extends State<_ChatActiveView> {
  ChatConversation? _conversation;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void didUpdateWidget(_ChatActiveView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _loadConversation();
    }
  }

  void _loadConversation() {
    setState(() {
      _conversation = ChatConversationStore.byId(widget.conversationId);
    });
  }

  String _getModelDisplay() {
    final conv = _conversation;
    if (conv == null) return '';
    final modelId = conv.modelId;
    if (modelId == null || modelId.isEmpty) return 'No model';
    // Shorten model name for display
    if (modelId.length > 28) {
      return '${modelId.substring(0, 25)}...';
    }
    return modelId;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return Scaffold(
      appBar: AppBar(
        leading: widget.onMenuPressed != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onMenuPressed,
              )
            : null,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _conversation?.title ?? 'Chat',
              style: ModernDesignSystem.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          if (_conversation?.modelId != null)
            Padding(
              padding:
                  const EdgeInsets.only(right: ModernDesignSystem.spacingS),
              child: Chip(
                label: Text(
                  _getModelDisplay(),
                  style: ModernDesignSystem.caption.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: primaryColor.withValues(alpha: 0.1),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Provider settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProviderConfigPage(),
                ),
              );
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: Column(
        children: [
          // Streaming indicator
          ValueListenableBuilder<int>(
            valueListenable: ChatStreamManager.streamStateChanged,
            builder: (context, _, __) {
              final isStreaming =
                  ChatStreamManager.isStreaming(widget.conversationId);
              if (!isStreaming) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingXS,
                ),
                color: primaryColor.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: ModernDesignSystem.spacingS),
                    Text(
                      'Generating response...',
                      style: ModernDesignSystem.caption.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Message list
          Expanded(
            child: MessageListView(
              conversationId: widget.conversationId,
            ),
          ),
          // Input bar
          ChatInputBar(
            conversationId: widget.conversationId,
            onMessageSent: _loadConversation,
          ),
        ],
      ),
    );
  }
}
