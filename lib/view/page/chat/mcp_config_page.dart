import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/mcp_server_config.dart';
import 'package:server_box/chat/store/mcp_server_store.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

class McpConfigPage extends StatelessWidget {
  const McpConfigPage({super.key});

  static const _serverTypes = ['stdio', 'sse'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listenable = McpServerStore.listenable();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Servers'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServerDialog(context),
        child: const Icon(Icons.add),
      ),
      body: listenable == null
          ? const Center(child: Text('Store not initialized'))
          : ValueListenableBuilder<Box<McpServerConfig>>(
              valueListenable: listenable,
              builder: (context, box, _) {
                final servers = McpServerStore.all();
                if (servers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dns_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingM),
                        Text(
                          'No MCP servers configured',
                          style: ModernDesignSystem.bodyMedium.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: ModernDesignSystem.spacingL),
                        GradientButton(
                          text: 'Add Server',
                          icon: const Icon(Icons.add,
                              color: Colors.white, size: 18),
                          onPressed: () => _showServerDialog(context),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(ModernDesignSystem.spacingM),
                  itemCount: servers.length,
                  itemBuilder: (context, index) {
                    final server = servers[index];
                    return _McpServerCard(
                      server: server,
                      onEdit: () =>
                          _showServerDialog(context, existing: server),
                      onDelete: () =>
                          _showDeleteConfirmation(context, server),
                      onToggleEnabled: (enabled) async {
                        await McpServerStore.put(
                          server.copyWith(enabled: enabled),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  void _showServerDialog(
    BuildContext context, {
    McpServerConfig? existing,
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
      builder: (ctx) => _McpServerEditSheet(
        existing: existing,
        serverTypes: _serverTypes,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, McpServerConfig server) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete MCP Server'),
        content: Text(
          'Are you sure you want to delete "${server.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await McpServerStore.remove(server.id);
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
// MCP server card widget
// ---------------------------------------------------------------------------

class _McpServerCard extends StatelessWidget {
  final McpServerConfig server;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  const _McpServerCard({
    required this.server,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = server.type == 'stdio'
        ? '${server.command} ${server.args.join(' ')}'.trim()
        : server.url ?? '';

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
                    Row(
                      children: [
                        StatusIndicator(
                          isOnline: server.enabled,
                          size: 10,
                          showPulse: server.enabled,
                        ),
                        const SizedBox(width: ModernDesignSystem.spacingS),
                        Flexible(
                          child: Text(
                            server.name,
                            style:
                                ModernDesignSystem.headingSmall.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ModernDesignSystem.spacingXS),
                    Row(
                      children: [
                        _ServerTypeBadge(type: server.type),
                        const SizedBox(width: ModernDesignSystem.spacingS),
                        Flexible(
                          child: Text(
                            subtitle,
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
                value: server.enabled,
                onChanged: onToggleEnabled,
              ),
            ],
          ),
          const SizedBox(height: ModernDesignSystem.spacingS),
          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (server.cachedTools != null && server.cachedTools!.isNotEmpty)
                Expanded(
                  child: Text(
                    '${server.cachedTools!.length} tool(s)',
                    style: ModernDesignSystem.caption.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5),
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
// Server type badge
// ---------------------------------------------------------------------------

class _ServerTypeBadge extends StatelessWidget {
  final String type;

  const _ServerTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isStdio = type == 'stdio';
    final color = isStdio ? const Color(0xFF6366F1) : const Color(0xFF10B981);
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
        type.toUpperCase(),
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

class _McpServerEditSheet extends StatefulWidget {
  final McpServerConfig? existing;
  final List<String> serverTypes;

  const _McpServerEditSheet({
    this.existing,
    required this.serverTypes,
  });

  @override
  State<_McpServerEditSheet> createState() => _McpServerEditSheetState();
}

class _McpServerEditSheetState extends State<_McpServerEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _commandCtrl;
  late final TextEditingController _argsCtrl;
  late final TextEditingController _urlCtrl;
  late String _selectedType;
  bool _envExpanded = false;

  /// Key-value pairs for environment variables.
  late final List<_EnvEntry> _envEntries;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _commandCtrl = TextEditingController(text: e?.command ?? '');
    _argsCtrl = TextEditingController(text: e?.args.join(', ') ?? '');
    _urlCtrl = TextEditingController(text: e?.url ?? '');
    _selectedType = e?.type ?? 'stdio';
    _envEntries = (e?.env.entries ?? <MapEntry<String, String>>[])
        .map((entry) => _EnvEntry(
              key: TextEditingController(text: entry.key),
              value: TextEditingController(text: entry.value),
            ))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _commandCtrl.dispose();
    _argsCtrl.dispose();
    _urlCtrl.dispose();
    for (final entry in _envEntries) {
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  void _addEnvEntry() {
    setState(() {
      _envEntries.add(_EnvEntry(
        key: TextEditingController(),
        value: TextEditingController(),
      ));
      _envExpanded = true;
    });
  }

  void _removeEnvEntry(int index) {
    setState(() {
      _envEntries[index].key.dispose();
      _envEntries[index].value.dispose();
      _envEntries.removeAt(index);
    });
  }

  Map<String, String> _collectEnv() {
    final map = <String, String>{};
    for (final entry in _envEntries) {
      final k = entry.key.text.trim();
      final v = entry.value.text.trim();
      if (k.isNotEmpty) {
        map[k] = v;
      }
    }
    return map;
  }

  List<String> _parseArgs() {
    final raw = _argsCtrl.text.trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    if (_selectedType == 'stdio' && _commandCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command is required for stdio type')),
      );
      return;
    }

    if (_selectedType == 'sse' && _urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL is required for SSE type')),
      );
      return;
    }

    final server = widget.existing?.copyWith(
          name: name,
          type: _selectedType,
          command: _commandCtrl.text.trim(),
          args: _parseArgs(),
          url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          env: _collectEnv(),
        ) ??
        McpServerConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          type: _selectedType,
          command: _commandCtrl.text.trim(),
          args: _parseArgs(),
          url: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
          env: _collectEnv(),
        );

    await McpServerStore.put(server);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStdio = _selectedType == 'stdio';

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
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),
            Text(
              _isEditing ? 'Edit MCP Server' : 'Add MCP Server',
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
                hintText: 'e.g. File System',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),

            // Type
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: widget.serverTypes
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(t.toUpperCase())))
                  .toList(),
              onChanged: (type) {
                if (type != null) setState(() => _selectedType = type);
              },
            ),
            const SizedBox(height: ModernDesignSystem.spacingM),

            // stdio fields
            if (isStdio) ...[
              TextField(
                controller: _commandCtrl,
                decoration: const InputDecoration(
                  labelText: 'Command',
                  hintText: 'e.g. npx, python',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: ModernDesignSystem.spacingM),
              TextField(
                controller: _argsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Arguments (comma-separated)',
                  hintText: 'e.g. -y, @modelcontextprotocol/server-fs',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: ModernDesignSystem.spacingM),
            ],

            // SSE fields
            if (!isStdio) ...[
              TextField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://mcp-server.example.com/sse',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: ModernDesignSystem.spacingM),
            ],

            // Environment variables
            _buildEnvSection(theme),
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

  Widget _buildEnvSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _envExpanded = !_envExpanded),
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Row(
              children: [
                Icon(
                  _envExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                ),
                const SizedBox(width: ModernDesignSystem.spacingS),
                Text(
                  'Environment Variables (${_envEntries.length})',
                  style: ModernDesignSystem.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add variable',
                  onPressed: _addEnvEntry,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        if (_envExpanded)
          ...List.generate(_envEntries.length, (i) {
            final entry = _envEntries[i];
            return Padding(
              padding: const EdgeInsets.only(
                  bottom: ModernDesignSystem.spacingS),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: entry.key,
                      decoration: const InputDecoration(
                        labelText: 'Key',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: ModernDesignSystem.spacingS),
                  Expanded(
                    child: TextField(
                      controller: entry.value,
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => _removeEnvEntry(i),
                    visualDensity: VisualDensity.compact,
                    color: Colors.red.shade400,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _EnvEntry {
  final TextEditingController key;
  final TextEditingController value;

  _EnvEntry({required this.key, required this.value});
}
