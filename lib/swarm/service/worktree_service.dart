import 'dart:io';

import 'package:server_box/swarm/model/worktree_info.dart';
import 'package:server_box/swarm/service/worktree_exception.dart';

/// Runs a subprocess; default uses [Process.run] for real git calls.
abstract class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  });
}

class _DefaultProcessRunner implements ProcessRunner {
  const _DefaultProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  }
}

/// Service for managing git worktrees via subprocess calls.
class WorktreeService {
  WorktreeService({ProcessRunner? processRunner})
      : _runner = processRunner ?? const _DefaultProcessRunner();

  final ProcessRunner _runner;

  /// Check if git is available on the system.
  Future<bool> isGitAvailable() async {
    try {
      final result = await _runner.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Check if a path is a valid git repository.
  Future<bool> isGitRepository(String path) async {
    try {
      final result = await _runner.run(
        'git',
        ['rev-parse', '--is-inside-work-tree'],
        workingDirectory: path,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Get the current branch name for a repository.
  Future<String> getCurrentBranch(String repoPath) async {
    try {
      final result = await _runner.run(
        'git',
        ['branch', '--show-current'],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// List all worktrees in a repository.
  Future<List<WorktreeInfo>> listWorktrees(String repoPath) async {
    final result = await _runner.run(
      'git',
      ['worktree', 'list', '--porcelain'],
      workingDirectory: repoPath,
    );

    if (result.exitCode != 0) {
      throw WorktreeException(
        command: 'git worktree list --porcelain',
        exitCode: result.exitCode,
        stderr: result.stderr as String,
      );
    }

    return _parseWorktreeList(result.stdout as String);
  }

  /// Create a new worktree with a new branch.
  Future<WorktreeInfo> createWorktree(
    String repoPath,
    String branch, {
    String? worktreePath,
    int maxRetries = 5,
  }) async {
    final resolvedBranch = await _createBranchWithRetry(
      repoPath,
      branch,
      maxRetries,
    );

    final wtPath = worktreePath ?? _buildWorktreePath(repoPath, resolvedBranch);

    final wtDir = Directory(wtPath);
    if (!await wtDir.exists()) {
      await wtDir.create(recursive: true);
    }

    var result = await _runner.run(
      'git',
      ['worktree', 'add', wtPath, resolvedBranch],
      workingDirectory: repoPath,
    );

    if (result.exitCode != 0) {
      final err = result.stderr as String;
      if (err.contains('already exists')) {
        await removeWorktree(repoPath, wtPath, force: true);
        result = await _runner.run(
          'git',
          ['worktree', 'add', wtPath, resolvedBranch],
          workingDirectory: repoPath,
        );
      }
      if (result.exitCode != 0) {
        throw WorktreeException(
          command: 'git worktree add $wtPath $resolvedBranch',
          exitCode: result.exitCode,
          stderr: err,
        );
      }
    }

    final commitResult = await _runner.run(
      'git',
      ['rev-parse', 'HEAD'],
      workingDirectory: wtPath,
    );
    final commit = (commitResult.stdout as String).trim();

    return WorktreeInfo(
      path: wtPath,
      branch: resolvedBranch,
      isMain: false,
      commit: commit,
    );
  }

  /// Remove a worktree.
  Future<void> removeWorktree(
    String repoPath,
    String path, {
    bool force = false,
  }) async {
    final args = <String>['worktree', 'remove'];
    if (force) args.add('--force');
    args.add(path);

    try {
      final result =
          await _runner.run('git', args, workingDirectory: repoPath);
      if (result.exitCode != 0) {
        final err = result.stderr as String;
        if (!err.contains('not found') &&
            !err.contains('No such file') &&
            !err.contains('not a working tree')) {
          throw WorktreeException(
            command: 'git ${args.join(' ')}',
            exitCode: result.exitCode,
            stderr: err,
          );
        }
      }
    } catch (e) {
      if (e is WorktreeException) rethrow;
    }
  }

  /// Prune stale worktree references.
  Future<void> pruneWorktrees(String repoPath) async {
    await _runner.run(
      'git',
      ['worktree', 'prune'],
      workingDirectory: repoPath,
    );
  }

  /// Create a branch, appending `-local` if the name already exists.
  Future<String> createBranch(String repoPath, String name) async {
    var result = await _runner.run(
      'git',
      ['branch', name],
      workingDirectory: repoPath,
    );
    if (result.exitCode == 0) return name;

    final err = result.stderr as String;
    if (err.contains('already exists')) {
      final local = '$name-local';
      result = await _runner.run(
        'git',
        ['branch', local],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) return local;
    }
    throw WorktreeException(
      command: 'git branch $name',
      exitCode: result.exitCode,
      stderr: result.stderr as String,
    );
  }

  Future<String> _createBranchWithRetry(
    String repoPath,
    String name,
    int maxRetries,
  ) async {
    for (var i = 0; i < maxRetries; i++) {
      final candidate = i == 0 ? name : '$name-${i + 1}';
      var result = await _runner.run(
        'git',
        ['branch', candidate],
        workingDirectory: repoPath,
      );
      if (result.exitCode == 0) return candidate;

      final err = result.stderr as String;

      if (i == 0 && err.contains('remote tracking branch')) {
        final local = '$name-local';
        result = await _runner.run(
          'git',
          ['branch', local],
          workingDirectory: repoPath,
        );
        if (result.exitCode == 0) return local;
        throw WorktreeException(
          command: 'git branch $local',
          exitCode: result.exitCode,
          stderr: result.stderr as String,
        );
      }

      if (!err.contains('already exists') && !err.contains('refusing')) {
        throw WorktreeException(
          command: 'git branch $candidate',
          exitCode: result.exitCode,
          stderr: err,
        );
      }
    }

    final local = '$name-local';
    final result = await _runner.run(
      'git',
      ['branch', local],
      workingDirectory: repoPath,
    );
    if (result.exitCode == 0) return local;

    throw WorktreeException(
      command: 'git branch $name',
      exitCode: 1,
      stderr: 'Failed to create branch after $maxRetries attempts',
    );
  }

  static String _buildWorktreePath(String repoPath, String branch) {
    final safeBranch = branch
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(' ', '_');
    return '$repoPath/.git/worktrees/$safeBranch';
  }

  static List<WorktreeInfo> _parseWorktreeList(String output) {
    final worktrees = <WorktreeInfo>[];
    final lines = output.split('\n');

    String? currentPath;
    String? currentBranch;
    var isMain = false;
    String? currentCommit;

    for (final line in lines) {
      if (line.isEmpty) {
        if (currentPath != null) {
          worktrees.add(WorktreeInfo(
            path: currentPath,
            branch: currentBranch,
            isMain: isMain,
            commit: currentCommit,
          ));
          currentPath = null;
          currentBranch = null;
          isMain = false;
          currentCommit = null;
        }
        continue;
      }

      if (line.startsWith('worktree ')) {
        currentPath = line.substring('worktree '.length).trim();
        isMain = !currentPath.contains('.git/worktrees/');
      } else if (line.startsWith('branch ')) {
        currentBranch = line.substring('branch '.length).trim();
      } else if (line.startsWith('commit ')) {
        currentCommit = line.substring('commit '.length).trim();
      } else if (line.startsWith('HEAD ')) {
        currentCommit = line.substring('HEAD '.length).trim();
      }
    }

    if (currentPath != null) {
      worktrees.add(WorktreeInfo(
        path: currentPath,
        branch: currentBranch,
        isMain: isMain,
        commit: currentCommit,
      ));
    }

    return worktrees;
  }
}
