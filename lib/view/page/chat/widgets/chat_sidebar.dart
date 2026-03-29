import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_conversation.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ChatSidebar extends StatefulWidget {
  final ValueNotifier<String?> currentConversationId;
  final ValueChanged<String> onConversationSelected;
  final VoidCallback onNewConversation;

  const ChatSidebar({
    super.key,
    required this.currentConversationId,
    required this.onConversationSelected,
    required this.onNewConversation,
  });

  @override
  State<ChatSidebar> createState() => _ChatSidebarState();
}

class _ChatSidebarState extends State<ChatSidebar> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ChatConversation> _filteredConversations() {
    if (_searchQuery.isEmpty) return ChatConversationStore.all();
    return ChatConversationStore.search(_searchQuery);
  }

  void _showConversationMenu(
      BuildContext context, ChatConversation conversation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin:
                  const EdgeInsets.only(top: ModernDesignSystem.spacingS),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingS),
            ListTile(
              leading: Icon(
                conversation.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin,
                color: ModernDesignSystem.primaryGradient.colors.first,
              ),
              title: Text(
                  conversation.isPinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(conversation);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.edit_outlined,
                color: ModernDesignSystem.primaryGradient.colors.first,
              ),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(conversation);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: ModernDesignSystem.warningGradient.colors.first,
              ),
              title: Text(
                'Delete',
                style: TextStyle(
                  color: ModernDesignSystem.warningGradient.colors.first,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _deleteConversation(conversation);
              },
            ),
            const SizedBox(height: ModernDesignSystem.spacingS),
          ],
        ),
      ),
    );
  }

  void _togglePin(ChatConversation conversation) async {
    await ChatConversationStore.put(
      conversation.copyWith(isPinned: !conversation.isPinned),
    );
  }

  void _showRenameDialog(ChatConversation conversation) {
    final controller = TextEditingController(text: conversation.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  ModernDesignSystem.borderRadiusSmall),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ChatConversationStore.put(
                  conversation.copyWith(title: value.trim()));
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                ChatConversationStore.put(
                    conversation.copyWith(title: value));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _deleteConversation(ChatConversation conversation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation'),
        content: const Text(
            'This will permanently delete this conversation and all its messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ChatConversationStore.remove(conversation.id);
              if (widget.currentConversationId.value == conversation.id) {
                widget.currentConversationId.value = null;
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: ModernDesignSystem.warningGradient.colors.first,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final listenable = ChatConversationStore.listenable();

    return Container(
      color: isDark ? const Color(0xFF161622) : const Color(0xFFF7F7FA),
      child: Column(
        children: [
          // Safe area top padding
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                hintStyle: ModernDesignSystem.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.35),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernDesignSystem.spacingM,
                  vertical: ModernDesignSystem.spacingS,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      ModernDesignSystem.borderRadiusSmall),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // New Chat button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingXS,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 42,
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
                    onTap: widget.onNewConversation,
                    borderRadius: BorderRadius.circular(
                        ModernDesignSystem.borderRadiusSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.white, size: 20),
                        const SizedBox(width: ModernDesignSystem.spacingS),
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
          const SizedBox(height: ModernDesignSystem.spacingS),
          // Conversation list
          Expanded(
            child: listenable == null
                ? const Center(child: Text('Store not initialized'))
                : ValueListenableBuilder(
                    valueListenable: listenable,
                    builder: (context, Box<ChatConversation> box, _) {
                      final conversations = _filteredConversations();
                      if (conversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ModernDesignSystem.spacingL,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _searchQuery.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.chat_bubble_outline_rounded,
                                  size: 56,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.black.withValues(alpha: 0.12),
                                ),
                                const SizedBox(
                                    height: ModernDesignSystem.spacingM),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No results found'
                                      : 'No conversations yet',
                                  textAlign: TextAlign.center,
                                  style:
                                      ModernDesignSystem.bodyMedium.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : Colors.black.withValues(alpha: 0.4),
                                  ),
                                ),
                                if (_searchQuery.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: ModernDesignSystem.spacingS),
                                    child: Text(
                                      'Tap "New Chat" above to start',
                                      textAlign: TextAlign.center,
                                      style:
                                          ModernDesignSystem.caption.copyWith(
                                        color: isDark
                                            ? Colors.white
                                                .withValues(alpha: 0.35)
                                            : Colors.black
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }
                      return ValueListenableBuilder<String?>(
                        valueListenable: widget.currentConversationId,
                        builder: (context, selectedId, _) {
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: ModernDesignSystem.spacingS,
                            ),
                            itemCount: conversations.length,
                            itemBuilder: (context, index) {
                              final conv = conversations[index];
                              final isSelected = conv.id == selectedId;
                              return _ConversationTile(
                                conversation: conv,
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () => widget
                                    .onConversationSelected(conv.id),
                                onLongPress: () =>
                                    _showConversationMenu(context, conv),
                                timestamp:
                                    _formatTimestamp(conv.updatedAt),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final String timestamp;

  const _ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ModernDesignSystem.spacingXS / 2,
      ),
      child: Material(
        color: isSelected
            ? (isDark
                ? primaryColor.withValues(alpha: 0.15)
                : primaryColor.withValues(alpha: 0.08))
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS + 2,
            ),
            child: Row(
              children: [
                if (conversation.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(
                        right: ModernDesignSystem.spacingS),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: primaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ModernDesignSystem.bodyMedium.copyWith(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      if (conversation.lastMessagePreview != null &&
                          conversation.lastMessagePreview!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            conversation.lastMessagePreview!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ModernDesignSystem.caption.copyWith(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: ModernDesignSystem.spacingS),
                Text(
                  timestamp,
                  style: ModernDesignSystem.caption.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
