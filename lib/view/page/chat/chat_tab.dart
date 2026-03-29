import 'package:flutter/material.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';
import 'package:server_box/view/page/chat/widgets/chat_sidebar.dart';
import 'package:server_box/view/page/chat/widgets/chat_main_view.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final _currentConversationId = ValueNotifier<String?>(null);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _currentConversationId.dispose();
    super.dispose();
  }

  void _onConversationSelected(String? id) {
    _currentConversationId.value = id;
    // Close drawer on narrow screens
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _createNewConversation() {
    final providers = ChatProviderStore.enabled();
    String? defaultProviderId;
    String? defaultModelId;
    if (providers.isNotEmpty) {
      defaultProviderId = providers.first.id;
      if (providers.first.models.isNotEmpty) {
        defaultModelId = providers.first.models.first;
      }
    }

    final conversation = ChatConversationStore.create(
      providerId: defaultProviderId,
      modelId: defaultModelId,
    );
    _currentConversationId.value = conversation.id;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return _buildWideLayout();
        } else {
          return _buildNarrowLayout();
        }
      },
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 300,
        child: SafeArea(
          child: ChatSidebar(
            currentConversationId: _currentConversationId,
            onConversationSelected: _onConversationSelected,
            onNewConversation: _createNewConversation,
          ),
        ),
      ),
      body: ChatMainView(
        currentConversationId: _currentConversationId,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        onNewConversation: _createNewConversation,
      ),
      floatingActionButton: ValueListenableBuilder<String?>(
        valueListenable: _currentConversationId,
        builder: (_, id, __) =>
            id == null ? _buildFab() : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWideLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: ChatSidebar(
              currentConversationId: _currentConversationId,
              onConversationSelected: _onConversationSelected,
              onNewConversation: _createNewConversation,
            ),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          Expanded(
            child: ChatMainView(
              currentConversationId: _currentConversationId,
              onNewConversation: _createNewConversation,
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<String?>(
        valueListenable: _currentConversationId,
        builder: (_, id, __) =>
            id == null ? _buildFab() : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
        boxShadow: ModernDesignSystem.glowShadow,
      ),
      child: FloatingActionButton(
        onPressed: _createNewConversation,
        backgroundColor: Colors.transparent,
        elevation: 0,
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}
