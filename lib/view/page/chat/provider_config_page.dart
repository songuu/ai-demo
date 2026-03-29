import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_provider.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';
import 'package:server_box/chat/service/chat_api_service.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class ProviderConfigPage extends StatefulWidget {
  const ProviderConfigPage({super.key});

  @override
  State<ProviderConfigPage> createState() => _ProviderConfigPageState();
}

class _ProviderConfigPageState extends State<ProviderConfigPage> {
  static const _providerTypes = [
    'openai',
    'anthropic',
    'google',
    'openrouter',
    'openclaw',
    'custom',
  ];

  static const _defaultHosts = {
    'openai': 'https://api.openai.com/v1',
    'anthropic': 'https://api.anthropic.com',
    'google': 'https://generativelanguage.googleapis.com',
    'openrouter': 'https://openrouter.ai/api/v1',
    'openclaw': 'https://api.openclaw.com/v1',
    'custom': '',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listenable = ChatProviderStore.listenable();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Settings'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProviderDialog(context),
        child: const Icon(Icons.add),
      ),
      body: listenable == null
          ? const Center(child: Text('Store not initialized'))
          : ValueListenableBuilder<Box<ChatProvider>>(
              valueListenable: listenable,
              builder: (context, box, _) {
                final providers = ChatProviderStore.all();
                if (providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        Text(
                          'No providers configured',
                          style: ModernDesignSystem.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingL),
                        GradientButton(
                          text: 'Add Provider',
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                          onPressed: () => _showProviderDialog(context),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _ProviderCard(
                      provider: provider,
                      onEdit: () =>
                          _showProviderDialog(context, existing: provider),
                      onDelete: () =>
                          _showDeleteConfirmation(context, provider),
                      onToggleEnabled: (enabled) async {
                        await ChatProviderStore.put(
                          provider.copyWith(enabled: enabled),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _showProviderDialog(
    BuildContext context, {
    ChatProvider? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      builder: (ctx) => _ProviderEditSheet(
        existing: existing,
        providerTypes: _providerTypes,
        defaultHosts: _defaultHosts,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ChatProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text(
          'Are you sure you want to delete "${provider.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ChatProviderStore.remove(provider.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider card widget
// ---------------------------------------------------------------------------

class _ProviderCard extends StatelessWidget {
  final ChatProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  const _ProviderCard({
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassmorphismCard(
      margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: ModernDesignSystem.headingSmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: ModernDesignSystem.spacingXS),
                    Row(
                      children: [
                        _TypeBadge(type: provider.type),
                        const SizedBox(width: ModernDesignSystem.spacingS),
                        Flexible(
                          child: Text(
                            provider.apiHost,
                            style: ModernDesignSystem.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.enabled,
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (provider.models.isNotEmpty)
                Expanded(
                  child: Text(
                    '${provider.models.length} models',
                    style: ModernDesignSystem.caption.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                color: Colors.red.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type badge
// ---------------------------------------------------------------------------

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  Color _badgeColor() {
    switch (type) {
      case 'openai':
        return const Color(0xFF10A37F);
      case 'anthropic':
        return const Color(0xFFD97757);
      case 'google':
        return const Color(0xFF4285F4);
      case 'openrouter':
        return const Color(0xFF6366F1);
      case 'openclaw':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernDesignSystem.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        type,
        style: ModernDesignSystem.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / Edit bottom sheet
// ---------------------------------------------------------------------------

class _ProviderEditSheet extends StatefulWidget {
  final ChatProvider? existing;
  final List<String> providerTypes;
  final Map<String, String> defaultHosts;

  const _ProviderEditSheet({
    this.existing,
    required this.providerTypes,
    required this.defaultHosts,
  });

  @override
  State<_ProviderEditSheet> createState() => _ProviderEditSheetState();
}

class _ProviderEditSheetState extends State<_ProviderEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _keyCtrl;
  late String _selectedType;
  late List<String> _models;
  bool _testing = false;
  String? _testResult;
  bool _fetching = false;
  bool _modelsExpanded = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _hostCtrl = TextEditingController(text: e?.apiHost ?? '');
    _keyCtrl = TextEditingController(text: e?.apiKey ?? '');
    _selectedType = e?.type ?? 'openai';
    _models = List<String>.from(e?.models ?? <String>[]);
    if (!_isEditing) {
      _hostCtrl.text = widget.defaultHosts[_selectedType] ?? '';
    }
    if (_models.isNotEmpty) {
      _modelsExpanded = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  void _onTypeChanged(String? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      if (!_isEditing ||
          widget.defaultHosts.values.contains(_hostCtrl.text)) {
        _hostCtrl.text = widget.defaultHosts[type] ?? '';
      }
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });

    final tempProvider = ChatProvider(
      id: widget.existing?.id ?? 'test',
      name: _nameCtrl.text,
      type: _selectedType,
      apiHost: _hostCtrl.text.trim(),
      apiKey: _keyCtrl.text.trim(),
    );
    final error = await ChatApiService.testConnection(tempProvider);
    if (!mounted) return;
    setState(() {
      _testResult = error ?? 'Success: Connection OK';
      _testing = false;
    });
  }

  Future<void> _fetchModels() async {
    setState(() {
      _fetching = true;
    });

    try {
      final tempProvider = ChatProvider(
        id: widget.existing?.id ?? 'temp',
        name: _nameCtrl.text,
        type: _selectedType,
        apiHost: _hostCtrl.text.trim(),
        apiKey: _keyCtrl.text.trim(),
        models: _models,
      );
      final fetched = await ChatApiService.fetchModels(tempProvider);
      if (!mounted) return;
      setState(() {
        _models = fetched;
        _modelsExpanded = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetched ${fetched.length} model(s)')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch models: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      }
    }
  }

  void _addModel() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Model'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Model ID',
            hintText: 'e.g. gpt-4o',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final id = controller.text.trim();
            if (id.isNotEmpty) {
              setState(() {
                _models.add(id);
                _modelsExpanded = true;
              });
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                setState(() {
                  _models.add(id);
                  _modelsExpanded = true;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  void _removeModel(int index) {
    setState(() {
      _models.removeAt(index);
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final host = _hostCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
    final key = _keyCtrl.text.trim();

    if (name.isEmpty || host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and API Host are required')),
      );
      return;
    }

    final provider = widget.existing?.copyWith(
          name: name,
          type: _selectedType,
          apiHost: host,
          apiKey: key,
          models: _models,
        ) ??
        ChatProvider(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          type: _selectedType,
          apiHost: host,
          apiKey: key,
          models: _models,
        );

    await ChatProviderStore.put(provider);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: ModernDesignSystem.spacingM,
        right: ModernDesignSystem.spacingM,
        top: ModernDesignSystem.spacingM,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            ModernDesignSystem.spacingM,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              _isEditing ? 'Edit Provider' : 'Add Provider',
              style: ModernDesignSystem.headingSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingL),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. My OpenAI',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),

            // Type
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: widget.providerTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: _onTypeChanged,
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),

            // API Host
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: 'API Host URL',
                hintText: 'https://api.example.com/v1',
                helperText: 'No trailing slash',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),

            // API Key
            TextField(
              controller: _keyCtrl,
              decoration: const InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: ModernDesignSystem.spacingL),

            // Test connection
            OutlinedButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering, size: 18),
              label: Text(_testing ? 'Testing...' : 'Test Connection'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: ModernDesignSystem.spacingS),
              Text(
                _testResult!,
                style: ModernDesignSystem.bodySmall.copyWith(
                  color: _testResult!.startsWith('Success')
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
            const SizedBox(height: ModernDesignSystem.spacingL),

            // Models section
            _buildModelsSection(theme),
            const SizedBox(height: ModernDesignSystem.spacingL),

            // Save
            GradientButton(
              text: _isEditing ? 'Update' : 'Save',
              onPressed: _save,
            ),
            const SizedBox(height: ModernDesignSystem.spacingS),
          ],
        ),
      ),
    );
  }

  Widget _buildModelsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _modelsExpanded = !_modelsExpanded),
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Row(
              children: [
                Icon(
                  _modelsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                const SizedBox(width: ModernDesignSystem.spacingS),
                Text(
                  'Models (${_models.length})',
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Fetch models button
                TextButton.icon(
                  onPressed: _fetching ? null : _fetchModels,
                  icon: _fetching
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download_outlined, size: 18),
                  label: Text(
                    _fetching ? 'Fetching...' : 'Fetch Models',
                    style: ModernDesignSystem.bodySmall,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add model manually',
                  onPressed: _addModel,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        if (_modelsExpanded && _models.isNotEmpty)
          ...List.generate(_models.length, (i) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: ModernDesignSystem.spacingXS),
              child: Row(
                children: [
                  const SizedBox(width: ModernDesignSystem.spacingL),
                  Expanded(
                    child: Text(
                      _models[i],
                      style: ModernDesignSystem.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    onPressed: () => _removeModel(i),
                    visualDensity: VisualDensity.compact,
                    color: Colors.red.shade400,
                    iconSize: 18,
                  ),
                ],
              ),
            );
          }),
        if (_modelsExpanded && _models.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: ModernDesignSystem.spacingL,
              bottom: ModernDesignSystem.spacingS,
            ),
            child: Text(
              'No models. Use "Fetch Models" or add manually.',
              style: ModernDesignSystem.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
