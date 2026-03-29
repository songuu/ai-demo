import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/chat/service/chat_stream_manager.dart';
import 'package:server_box/chat/store/chat_message_store.dart';
import 'package:server_box/view/page/chat/widgets/chat_message_bubble.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class MessageListView extends StatefulWidget {
  final String conversationId;

  const MessageListView({
    super.key,
    required this.conversationId,
  });

  @override
  State<MessageListView> createState() => _MessageListViewState();
}

class _MessageListViewState extends State<MessageListView> {
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void didUpdateWidget(MessageListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversationId != widget.conversationId) {
      _loadMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    setState(() {
      _messages = ChatMessageStore.forConversation(widget.conversationId);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: ModernDesignSystem.animationMedium,
          curve: ModernDesignSystem.animationCurve,
        );
      }
    });
  }

  void _deleteMessage(ChatMessage message) {
    ChatMessageStore.remove(message.id);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listenable = ChatMessageStore.listenable();

    if (listenable == null) {
      return const Center(child: Text('Message store not initialized'));
    }

    return ValueListenableBuilder(
      valueListenable: listenable,
      builder: (context, Box<ChatMessage> box, _) {
        _messages = ChatMessageStore.forConversation(widget.conversationId);

        if (_messages.isEmpty) {
          return _buildEmptyMessages(isDark);
        }

        // Schedule scroll after build
        _scrollToBottom();

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingM,
            vertical: ModernDesignSystem.spacingS,
          ),
          itemCount: _messages.length + 1, // +1 for streaming message slot
          itemBuilder: (context, index) {
            if (index < _messages.length) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: ModernDesignSystem.spacingM,
                ),
                child: ChatMessageBubble(
                  message: _messages[index],
                  onDelete: () => _deleteMessage(_messages[index]),
                ),
              );
            }

            // Streaming message slot
            return ValueListenableBuilder<int>(
              valueListenable: ChatStreamManager.streamStateChanged,
              builder: (context, _, __) {
                final streamNotifier = ChatStreamManager.getStreamingMessage(
                    widget.conversationId);
                if (streamNotifier == null) return const SizedBox.shrink();

                return ValueListenableBuilder<ChatMessage>(
                  valueListenable: streamNotifier,
                  builder: (context, streamMsg, _) {
                    _scrollToBottom();
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: ModernDesignSystem.spacingM,
                      ),
                      child: ChatMessageBubble(
                        message: streamMsg,
                        isStreaming: true,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyMessages(bool isDark) {
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernDesignSystem.spacingXL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(
                    ModernDesignSystem.borderRadiusMedium),
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 32,
                color: primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingL),
            Text(
              'Send a message to begin',
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.45),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ModernDesignSystem.spacingXS),
            Text(
              'Type below and press Enter or tap Send',
              style: ModernDesignSystem.caption.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
