import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/codecore/service/cod_launcher.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';
import 'package:server_box/codecore/widget/cod_embedded_terminal.dart';
import 'package:server_box/swarm/model/agent_task.dart';
import 'package:server_box/swarm/model/swarm_session.dart';
import 'package:server_box/swarm/service/swarm_orchestrator.dart';
import 'package:server_box/swarm/store/swarm_session_store.dart';
import 'package:server_box/swarm/widget/new_swarm_task_dialog.dart';
import 'package:server_box/swarm/widget/swarm_session_card.dart';

class SwarmTab extends StatefulWidget {
  const SwarmTab({super.key});

  @override
  State<SwarmTab> createState() => _SwarmTabState();
}

class _SwarmTabState extends State<SwarmTab> {
  final _orchestrator = SwarmOrchestrator();

  String? _selectedSessionId;
  Map<String, AvailabilityCheck> _agentAvailability = {};
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _checkAgentAvailability();
  }

  @override
  void dispose() {
    _orchestrator.killAll();
    super.dispose();
  }

  Future<void> _checkAgentAvailability() async {
    try {
      final result = await _orchestrator.checkAvailableAgents();
      if (mounted) setState(() => _agentAvailability = result);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: isWide ? _buildWideLayout(theme) : _buildNarrowLayout(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLaunching ? null : _showNewTaskDialog,
        child: _isLaunching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  /// Desktop / tablet: two-column layout.
  Widget _buildWideLayout(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _buildSessionList(theme),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _buildDetailPanel(theme)),
      ],
    );
  }

  /// Mobile: single-column with navigation.
  Widget _buildNarrowLayout(ThemeData theme) {
    if (_selectedSessionId != null) {
      return Column(
        children: [
          _buildBackBar(theme),
          Expanded(child: _buildDetailPanel(theme)),
        ],
      );
    }
    return _buildSessionList(theme);
  }

  Widget _buildBackBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedSessionId = null),
          ),
          const Text('Sessions'),
        ],
      ),
    );
  }

  Widget _buildSessionList(ThemeData theme) {
    return Column(
      children: [
        _buildHeader(theme),
        _buildAgentStatusBar(theme),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: SwarmSessionStore.listenable(),
            builder: (context, Box<SwarmSession> box, _) {
              final sessions = SwarmSessionStore.all();
              if (sessions.isEmpty) {
                return _buildEmptyState(theme);
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return SwarmSessionCard(
                    session: session,
                    isSelected: session.id == _selectedSessionId,
                    isRunning: _orchestrator.isRunning(session.id),
                    onTap: () =>
                        setState(() => _selectedSessionId = session.id),
                    onStop: () => _stopSession(session.id),
                    onRemove: () => _removeSession(session.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(Icons.hub, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Agent Swarm', style: theme.textTheme.titleLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh agent status',
            onPressed: _checkAgentAvailability,
          ),
        ],
      ),
    );
  }

  Widget _buildAgentStatusBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        children: ['claude', 'codex', 'gemini'].map((agent) {
          final check = _agentAvailability[agent];
          final available = check?.available ?? false;
          return Chip(
            avatar: Icon(
              available ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: available ? Colors.green : Colors.red,
            ),
            label: Text(
              agent,
              style: theme.textTheme.bodySmall,
            ),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_outlined, size: 64, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No active sessions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create a new agent task',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(ThemeData theme) {
    if (_selectedSessionId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: theme.disabledColor),
            const SizedBox(height: 12),
            Text(
              'Select a session to view terminal',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    final session = SwarmSessionStore.byId(_selectedSessionId!);
    if (session == null) {
      return const Center(child: Text('Session not found'));
    }

    // Look up the linked CodSession for terminal display.
    final codSession = session.codSessionId != null
        ? CodSessionStore.byId(session.codSessionId!)
        : null;

    return Column(
      children: [
        _buildSessionInfoBar(theme, session),
        Expanded(
          child: codSession != null
              ? CodEmbeddedTerminal(
                  key: ValueKey(codSession.id),
                  session: codSession,
                  workingDirectory: codSession.cwd,
                )
              : Center(
                  child: Text(
                    session.status == SwarmSessionStatus.failed
                        ? 'Agent launch failed'
                        : 'Initializing...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSessionInfoBar(ThemeData theme, SwarmSession session) {
    final statusColor = switch (session.status) {
      SwarmSessionStatus.running => Colors.green,
      SwarmSessionStatus.failed => Colors.red,
      SwarmSessionStatus.completed => Colors.blue,
      SwarmSessionStatus.paused => Colors.orange,
      SwarmSessionStatus.initializing => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          _agentIcon(session.agentType),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.title, style: theme.textTheme.titleSmall),
                Text(
                  '${session.agentType} \u2022 ${session.branch}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.status.name,
              style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentIcon(String agentType) {
    return switch (agentType) {
      'claude' => const Icon(Icons.smart_toy, color: Colors.orange, size: 20),
      'codex' => const Icon(Icons.code, color: Colors.blue, size: 20),
      'gemini' =>
        const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
      _ => const Icon(Icons.terminal, size: 20),
    };
  }

  // --- Actions ---

  Future<void> _showNewTaskDialog() async {
    final task = await showDialog<AgentTask>(
      context: context,
      builder: (ctx) => NewSwarmTaskDialog(
        agentAvailability: _agentAvailability,
      ),
    );
    if (task == null) return;

    setState(() => _isLaunching = true);
    try {
      final session = await _orchestrator.createAndLaunch(task);
      if (mounted) {
        setState(() {
          _selectedSessionId = session.id;
          _isLaunching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLaunching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Launch failed: $e')),
        );
      }
    }
  }

  Future<void> _stopSession(String sessionId) async {
    await _orchestrator.stopSession(sessionId);
    if (mounted) setState(() {});
  }

  Future<void> _removeSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove session?'),
        content: const Text(
          'This will stop the agent and delete the worktree. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    if (_selectedSessionId == sessionId) {
      _selectedSessionId = null;
    }
    await _orchestrator.removeSession(sessionId);
    if (mounted) setState(() {});
  }
}
