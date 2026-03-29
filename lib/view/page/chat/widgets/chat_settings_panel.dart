import 'package:flutter/material.dart';
import 'package:server_box/chat/model/chat_conversation.dart';
import 'package:server_box/chat/store/chat_conversation_store.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';
import 'package:server_box/chat/store/mcp_server_store.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Right-side settings panel for per-conversation settings.
class ChatSettingsPanel extends StatefulWidget {
  final ChatConversation conversation;
  final VoidCallback? onChanged;

  const ChatSettingsPanel({
    super.key,
    required this.conversation,
    this.onChanged,
  });

  @override
  State<ChatSettingsPanel> createState() => _ChatSettingsPanelState();
}

class _ChatSettingsPanelState extends State<ChatSettingsPanel> {
  late ChatConversation _conv;
  late final TextEditingController _systemPromptCtrl;
  late final TextEditingController _maxTokensCtrl;

  @override
  void initState() {
    super.initState();
    _conv = widget.conversation;
    _systemPromptCtrl =
        TextEditingController(text: _conv.systemPrompt ?? '');
    _maxTokensCtrl =
        TextEditingController(text: _conv.maxTokens.toString());
  }

  @override
  void didUpdateWidget(covariant ChatSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _conv = widget.conversation;
      _systemPromptCtrl.text = _conv.systemPrompt ?? '';
      _maxTokensCtrl.text = _conv.maxTokens.toString();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _systemPromptCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  Future<void> _persist(ChatConversation updated) async {
    _conv = updated;
    await ChatConversationStore.put(updated);
    widget.onChanged?.call();
  }

  // ---------------------------------------------------------------------------
  // Model selection
  // ---------------------------------------------------------------------------

  void _showModelSelector() {
    final providers = ChatProviderStore.enabled();
    if (providers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No enabled providers')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
          children: [
            Text(
              'Select Model',
              style: ModernDesignSystem.headingSmall.copyWith(
                color: Theme.of(ctx).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),
            for (final provider in providers) ...[
              Padding(
                padding: const EdgeInsets.only(
                    bottom: ModernDesignSystem.spacingXS),
                child: Text(
                  provider.name,
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ),
              if (provider.models.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: ModernDesignSystem.spacingS),
                  child: Text(
                    'No models available',
                    style: ModernDesignSystem.caption.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                ...provider.models.map(
                  (modelId) => ListTile(
                    dense: true,
                    title: Text(modelId),
                    selected: _conv.providerId == provider.id &&
                        _conv.modelId == modelId,
                    onTap: () async {
                      final updated = _conv.copyWith(
                        providerId: provider.id,
                        modelId: modelId,
                      );
                      await _persist(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              const Divider(),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Model Selection ----
          _sectionTitle('Model'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          GlassmorphismCard(
            onTap: _showModelSelector,
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _providerLabel(),
                        style: ModernDesignSystem.caption.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _conv.modelId ?? 'Not selected',
                        style: ModernDesignSystem.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),

          // ---- System Prompt ----
          _sectionTitle('System Prompt'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          TextField(
            controller: _systemPromptCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter a system prompt...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            minLines: 2,
            onChanged: (text) {
              _persist(_conv.copyWith(
                systemPrompt: text.isEmpty ? null : text,
              ));
            },
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),

          // ---- Temperature ----
          _sectionTitle('Temperature'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _conv.temperature,
                  min: 0.0,
                  max: 2.0,
                  divisions: 40,
                  label: _conv.temperature.toStringAsFixed(2),
                  onChanged: (val) {
                    setState(() {
                      _conv = _conv.copyWith(temperature: val);
                    });
                  },
                  onChangeEnd: (val) {
                    _persist(_conv.copyWith(temperature: val));
                  },
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  _conv.temperature.toStringAsFixed(2),
                  style: ModernDesignSystem.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),

          // ---- Max Tokens ----
          _sectionTitle('Max Tokens'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          TextField(
            controller: _maxTokensCtrl,
            decoration: const InputDecoration(
              hintText: '4096',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null && parsed > 0) {
                _persist(_conv.copyWith(maxTokens: parsed));
              }
            },
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),

          // ---- Web Search ----
          _sectionTitle('Web Search'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable web search',
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            value: _conv.webSearchEnabled,
            onChanged: (enabled) async {
              final updated =
                  _conv.copyWith(webSearchEnabled: enabled);
              await _persist(updated);
              setState(() {});
            },
          ),
          const SizedBox(height: ModernDesignSystem.spacingL),

          // ---- MCP Servers ----
          _sectionTitle('MCP Servers'),
          const SizedBox(height: ModernDesignSystem.spacingS),
          _buildMcpServerList(theme),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: ModernDesignSystem.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  String _providerLabel() {
    if (_conv.providerId == null) return 'Provider';
    final provider = ChatProviderStore.byId(_conv.providerId!);
    return provider?.name ?? _conv.providerId!;
  }

  Widget _buildMcpServerList(ThemeData theme) {
    final servers = McpServerStore.all();
    if (servers.isEmpty) {
      return Text(
        'No MCP servers configured',
        style: ModernDesignSystem.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      children: servers.map((server) {
        final isSelected = _conv.mcpServerIds.contains(server.id);
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            server.name,
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            server.type.toUpperCase(),
            style: ModernDesignSystem.caption.copyWith(
              color:
                  theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          secondary: StatusIndicator(
            isOnline: server.enabled,
            size: 10,
            showPulse: false,
          ),
          value: isSelected,
          onChanged: (checked) async {
            final ids = List<String>.from(_conv.mcpServerIds);
            if (checked == true) {
              if (!ids.contains(server.id)) ids.add(server.id);
            } else {
              ids.remove(server.id);
            }
            final updated = _conv.copyWith(mcpServerIds: ids);
            await _persist(updated);
            setState(() {});
          },
        );
      }).toList(),
    );
  }
}
