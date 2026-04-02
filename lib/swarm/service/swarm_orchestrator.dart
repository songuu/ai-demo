import 'dart:io';
import 'dart:math';

import 'package:server_box/codecore/service/cod_launcher.dart';
import 'package:server_box/swarm/model/agent_task.dart';
import 'package:server_box/swarm/model/swarm_session.dart';
import 'package:server_box/swarm/model/worktree.dart';
import 'package:server_box/swarm/service/worktree_service.dart';
import 'package:server_box/swarm/store/agent_task_store.dart';
import 'package:server_box/swarm/store/swarm_session_store.dart';
import 'package:server_box/swarm/store/worktree_store.dart';

/// Orchestrates agent sessions: creates worktrees, launches agents, and
/// manages the full lifecycle (similar to Superset's parallel agent model).
class SwarmOrchestrator {
  SwarmOrchestrator({WorktreeService? worktreeService})
      : _worktreeService = worktreeService ?? WorktreeService() {
    _recoverStaleSessions();
  }

  final WorktreeService _worktreeService;

  /// Active processes keyed by SwarmSession.id.
  final Map<String, Process> _processes = {};

  static final _random = Random();

  /// On startup, mark any previously-running sessions as failed since we
  /// cannot re-attach to their processes after an app restart.
  void _recoverStaleSessions() {
    for (final session in SwarmSessionStore.running()) {
      final updated = session.copyWith(status: SwarmSessionStatus.failed);
      SwarmSessionStore.put(updated);
    }
  }

  /// Create a task, create an isolated worktree, launch the agent inside it.
  Future<SwarmSession> createAndLaunch(AgentTask task) async {
    // Validate the repo path is a real git repository.
    final repoDir = Directory(task.repoPath);
    if (!await repoDir.exists()) {
      throw SwarmLaunchException(
        'Repository path does not exist: ${task.repoPath}',
      );
    }
    if (!await _worktreeService.isGitRepository(task.repoPath)) {
      throw SwarmLaunchException(
        'Not a git repository: ${task.repoPath}',
      );
    }

    // Persist the task.
    task = task.copyWith(status: AgentTaskStatus.running);
    await AgentTaskStore.put(task);

    // Create an isolated worktree (path is a sibling of the repo).
    final branchName = 'swarm/${task.id}';
    final worktreeInfo = await _worktreeService.createWorktree(
      task.repoPath,
      branchName,
      worktreePath: _buildWorktreePath(task.repoPath, task.id),
    );

    final now = DateTime.now();
    final worktree = Worktree(
      id: 'wt_${task.id}',
      sessionId: '', // Will be updated after session creation.
      path: worktreeInfo.path,
      branch: worktreeInfo.branch ?? branchName,
      commit: worktreeInfo.commit,
      createdAt: now,
      remotePath: task.repoPath,
      status: WorktreeStatus.active,
    );
    await WorktreeStore.put(worktree);

    // Create the swarm session.
    final sessionId = 'ss_${now.millisecondsSinceEpoch}_${_random.nextInt(9999)}';
    final session = SwarmSession(
      id: sessionId,
      taskId: task.id,
      worktreeId: worktree.id,
      agentType: task.agentType,
      title: task.title,
      branch: worktree.branch,
      createdAt: now,
      status: SwarmSessionStatus.initializing,
    );

    // Update worktree with session id (immutable copyWith).
    final linkedWorktree = worktree.copyWith(sessionId: session.id);
    await WorktreeStore.put(linkedWorktree);

    // Launch the agent CLI inside the worktree directory.
    final launchResult = await _launchAgent(
      agentType: task.agentType,
      title: task.title,
      workingDirectory: worktreeInfo.path,
    );

    if (launchResult.success && launchResult.process != null) {
      _processes[session.id] = launchResult.process!;

      final updated = session.copyWith(
        codSessionId: launchResult.session?.id,
        status: SwarmSessionStatus.running,
      );
      await SwarmSessionStore.put(updated);
      return updated;
    }

    // Launch failed.
    final failed = session.copyWith(status: SwarmSessionStatus.failed);
    await SwarmSessionStore.put(failed);

    task = task.copyWith(status: AgentTaskStatus.failed);
    await AgentTaskStore.put(task);

    throw SwarmLaunchException(
      launchResult.error ?? 'Unknown launch error',
    );
  }

  /// Stop a running session and clean up.
  Future<void> stopSession(String sessionId) async {
    final process = _processes.remove(sessionId);
    process?.kill();

    final session = SwarmSessionStore.byId(sessionId);
    if (session != null) {
      final updated = session.copyWith(status: SwarmSessionStatus.completed);
      await SwarmSessionStore.put(updated);
    }
  }

  /// Remove a session and its worktree.
  Future<void> removeSession(String sessionId) async {
    await stopSession(sessionId);

    final session = SwarmSessionStore.byId(sessionId);
    if (session == null) return;

    // Clean up worktree.
    final worktree = WorktreeStore.byId(session.worktreeId);
    if (worktree != null) {
      try {
        await _worktreeService.removeWorktree(
          worktree.remotePath,
          worktree.path,
          force: true,
        );
      } catch (_) {
        // Best-effort cleanup.
      }
      await WorktreeStore.remove(worktree.id);
    }

    await SwarmSessionStore.remove(sessionId);
  }

  /// Kill all active processes (call from dispose).
  void killAll() {
    for (final process in _processes.values) {
      process.kill();
    }
    _processes.clear();
  }

  /// Check which agent CLIs are available on this machine.
  Future<Map<String, AvailabilityCheck>> checkAvailableAgents() {
    return CodLauncher.checkAllCliAvailability();
  }

  bool isRunning(String sessionId) => _processes.containsKey(sessionId);

  /// Build worktree path as a sibling directory of the repo, not inside .git/.
  static String _buildWorktreePath(String repoPath, String taskId) {
    final repoDir = Directory(repoPath);
    final parentPath = repoDir.parent.path;
    final repoName = repoDir.path.split(Platform.pathSeparator).last;
    final safeName = taskId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return '$parentPath/$repoName-swarm-$safeName';
  }

  Future<LaunchResult> _launchAgent({
    required String agentType,
    required String title,
    required String workingDirectory,
  }) {
    switch (agentType) {
      case 'claude':
        return CodLauncher.launchClaude(
          title: title,
          workingDirectory: workingDirectory,
        );
      case 'codex':
        return CodLauncher.launchCodex(
          title: title,
          workingDirectory: workingDirectory,
        );
      case 'gemini':
        return CodLauncher.launchGemini(
          title: title,
          workingDirectory: workingDirectory,
        );
      default:
        return CodLauncher.launchNewSession(
          provider: agentType,
          title: title,
          workingDirectory: workingDirectory,
        );
    }
  }
}

class SwarmLaunchException implements Exception {
  final String message;
  const SwarmLaunchException(this.message);

  @override
  String toString() => 'SwarmLaunchException: $message';
}
