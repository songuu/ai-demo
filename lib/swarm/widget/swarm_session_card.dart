import 'package:flutter/material.dart';
import 'package:server_box/swarm/model/swarm_session.dart';

class SwarmSessionCard extends StatelessWidget {
  final SwarmSession session;
  final bool isSelected;
  final bool isRunning;
  final VoidCallback onTap;
  final VoidCallback onStop;
  final VoidCallback onRemove;

  const SwarmSessionCard({
    super.key,
    required this.session,
    required this.isSelected,
    required this.isRunning,
    required this.onTap,
    required this.onStop,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(session.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        elevation: isSelected ? 2 : 0,
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAgentAvatar(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: theme.textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            session.status.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              session.branch,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isRunning)
                  IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, size: 20),
                    tooltip: 'Stop agent',
                    onPressed: onStop,
                    visualDensity: VisualDensity.compact,
                  ),
                PopupMenuButton<String>(
                  itemBuilder: (_) => [
                    if (isRunning)
                      const PopupMenuItem(
                        value: 'stop',
                        child: ListTile(
                          leading: Icon(Icons.stop, color: Colors.orange),
                          title: Text('Stop'),
                          dense: true,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Remove'),
                        dense: true,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'stop':
                        onStop();
                      case 'remove':
                        onRemove();
                    }
                  },
                  icon: const Icon(Icons.more_vert, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgentAvatar(ThemeData theme) {
    final (icon, color) = switch (session.agentType) {
      'claude' => (Icons.smart_toy, Colors.orange),
      'codex' => (Icons.code, Colors.blue),
      'gemini' => (Icons.auto_awesome, Colors.green),
      _ => (Icons.terminal, theme.iconTheme.color ?? Colors.grey),
    };

    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Color _statusColor(SwarmSessionStatus status) {
    return switch (status) {
      SwarmSessionStatus.running => Colors.green,
      SwarmSessionStatus.failed => Colors.red,
      SwarmSessionStatus.completed => Colors.blue,
      SwarmSessionStatus.paused => Colors.orange,
      SwarmSessionStatus.initializing => Colors.grey,
    };
  }
}
