import 'dart:io';

import 'package:flutter/material.dart';
import 'package:server_box/codecore/service/cod_launcher.dart';
import 'package:server_box/swarm/model/agent_task.dart';

/// Dialog for creating a new agent task in the swarm.
class NewSwarmTaskDialog extends StatefulWidget {
  final Map<String, AvailabilityCheck> agentAvailability;

  const NewSwarmTaskDialog({
    super.key,
    required this.agentAvailability,
  });

  @override
  State<NewSwarmTaskDialog> createState() => _NewSwarmTaskDialogState();
}

class _NewSwarmTaskDialogState extends State<NewSwarmTaskDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repoCtrl = TextEditingController(
    text: Directory.current.path.replaceAll(r'\', '/'),
  );
  String _selectedAgent = 'claude';

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onFieldChanged);
    _repoCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _titleCtrl.removeListener(_onFieldChanged);
    _repoCtrl.removeListener(_onFieldChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _repoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New Agent Task'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent type selector
              Text('Agent', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _buildAgentSelector(theme),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g., Fix login bug',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'What should the agent do?',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Repository path
              TextField(
                controller: _repoCtrl,
                decoration: InputDecoration(
                  labelText: 'Repository path',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: _pickDirectory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _canSubmit() ? _submit : null,
          icon: const Icon(Icons.rocket_launch, size: 18),
          label: const Text('Launch'),
        ),
      ],
    );
  }

  Widget _buildAgentSelector(ThemeData theme) {
    final agents = [
      ('claude', 'Claude Code', Icons.smart_toy, Colors.orange),
      ('codex', 'Codex', Icons.code, Colors.blue),
      ('gemini', 'Gemini', Icons.auto_awesome, Colors.green),
    ];

    return Wrap(
      spacing: 8,
      children: agents.map((agent) {
        final (id, label, icon, color) = agent;
        final isAvailable =
            widget.agentAvailability[id]?.available ?? false;
        final isSelected = _selectedAgent == id;

        return ChoiceChip(
          avatar: Icon(icon, size: 18, color: isSelected ? color : null),
          label: Text(label),
          selected: isSelected,
          onSelected: isAvailable
              ? (selected) {
                  if (selected) setState(() => _selectedAgent = id);
                }
              : null,
          tooltip: isAvailable
              ? widget.agentAvailability[id]?.status
              : 'Not installed',
        );
      }).toList(),
    );
  }

  bool _canSubmit() {
    return _titleCtrl.text.trim().isNotEmpty &&
        _repoCtrl.text.trim().isNotEmpty;
  }

  void _submit() {
    final now = DateTime.now();
    final task = AgentTask(
      id: 'task_${now.millisecondsSinceEpoch}',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      repoPath: _repoCtrl.text.trim(),
      agentType: _selectedAgent,
      createdAt: now,
    );
    Navigator.pop(context, task);
  }

  Future<void> _pickDirectory() async {
    // On desktop, we could use file_picker. For now, just let user type.
    // This is a placeholder for future enhancement.
  }
}
