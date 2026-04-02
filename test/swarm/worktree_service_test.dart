import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:server_box/swarm/model/worktree_info.dart';
import 'package:server_box/swarm/service/worktree_exception.dart';
import 'package:server_box/swarm/service/worktree_service.dart';

class MockProcessRunner implements ProcessRunner {
  final List<String> callLog = [];
  final Map<String, ProcessResult> responses = {};
  final Map<String, List<ProcessResult>> sequences = {};

  void when(String pattern, ProcessResult result) {
    responses[pattern] = result;
    sequences.remove(pattern);
  }

  /// Later entries override [when] for the same [pattern].
  void whenSequence(String pattern, List<ProcessResult> results) {
    sequences[pattern] = results;
    responses.remove(pattern);
  }

  void clear() {
    callLog.clear();
    responses.clear();
    sequences.clear();
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  }) async {
    final key = '$executable ${arguments.join(' ')}';
    callLog.add(key);
    final seq = sequences[key];
    if (seq != null && seq.isNotEmpty) {
      return seq.removeAt(0);
    }
    final result = responses[key];
    if (result != null) return result;
    return ProcessResult(-1, 0, '', '');
  }
}

void main() {
  group('WorktreeService', () {
    late MockProcessRunner mockRunner;
    late WorktreeService service;

    setUp(() {
      mockRunner = MockProcessRunner();
      service = WorktreeService(processRunner: mockRunner);
    });

    group('isGitRepository', () {
      test('returns true for valid git repository', () async {
        mockRunner.when(
          'git rev-parse --is-inside-work-tree',
          ProcessResult(-1,0, 'true', ''),
        );

        final result = await service.isGitRepository('/some/repo');
        expect(result, isTrue);
        expect(
          mockRunner.callLog,
          contains('git rev-parse --is-inside-work-tree'),
        );
      });

      test('returns false for non-git directory', () async {
        mockRunner.when(
          'git rev-parse --is-inside-work-tree',
          ProcessResult(-1,128, '', 'fatal: not a git repository'),
        );

        final result = await service.isGitRepository('/not/a/repo');
        expect(result, isFalse);
      });
    });

    group('isGitAvailable', () {
      test('returns true when git is installed', () async {
        mockRunner.when(
          'git --version',
          ProcessResult(-1,0, 'git version 2.40.0', ''),
        );

        final result = await service.isGitAvailable();
        expect(result, isTrue);
      });

      test('returns false when git is not available', () async {
        mockRunner.when(
          'git --version',
          ProcessResult(-1,1, '', 'git: command not found'),
        );

        final result = await service.isGitAvailable();
        expect(result, isFalse);
      });
    });

    group('getCurrentBranch', () {
      test('returns branch name from git branch --show-current', () async {
        mockRunner.when(
          'git branch --show-current',
          ProcessResult(-1,0, 'main\n', ''),
        );

        final result = await service.getCurrentBranch('/repo');
        expect(result, 'main');
      });

      test('returns empty string in detached HEAD state', () async {
        mockRunner.when(
          'git branch --show-current',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.getCurrentBranch('/repo');
        expect(result, '');
      });
    });

    group('listWorktrees', () {
      test('parses porcelain output with branch info', () async {
        mockRunner.when(
          'git worktree list --porcelain',
          ProcessResult(-1,0, '''
worktree /repo
HEAD abc123
branch refs/heads/main

worktree /repo/.git/worktrees/feature-1
HEAD def456
branch refs/heads/feature-1

worktree /repo/.git/worktrees/pr-123
HEAD ghi789
bare
''', ''),
        );

        final result = await service.listWorktrees('/repo');
        expect(result.length, 3);

        expect(result[0].path, '/repo');
        expect(result[0].branch, 'refs/heads/main');
        expect(result[0].isMain, isTrue);
        expect(result[0].commit, 'abc123');

        expect(result[1].path, '/repo/.git/worktrees/feature-1');
        expect(result[1].branch, 'refs/heads/feature-1');
        expect(result[1].isMain, isFalse);
        expect(result[1].commit, 'def456');

        expect(result[2].path, '/repo/.git/worktrees/pr-123');
        expect(result[2].branch, isNull);
        expect(result[2].isMain, isFalse);
        expect(result[2].commit, 'ghi789');
      });

      test('returns empty list when no worktrees', () async {
        mockRunner.when(
          'git worktree list --porcelain',
          ProcessResult(-1,0, 'worktree /repo\nHEAD abc\nbranch refs/heads/main\n', ''),
        );

        final result = await service.listWorktrees('/repo');
        expect(result.length, 1);
      });
    });

    group('createWorktree', () {
      test('creates worktree and branch successfully', () async {
        mockRunner.when(
          'git branch swarm/test',
          ProcessResult(-1,0, '', ''),
        );
        mockRunner.when(
          'git worktree add /repo/.git/worktrees/swarm-test swarm/test',
          ProcessResult(-1,0, 'Preparing /repo/.git/worktrees/swarm-test\nHEAD is now at abc123', ''),
        );

        final result = await service.createWorktree('/repo', 'swarm/test');
        expect(result.branch, 'swarm/test');
        expect(result.isMain, isFalse);
        expect(mockRunner.callLog.length, 3);
        expect(mockRunner.callLog[0], 'git branch swarm/test');
        expect(mockRunner.callLog[1], 'git worktree add /repo/.git/worktrees/swarm-test swarm/test');
        expect(mockRunner.callLog[2], 'git rev-parse HEAD');
      });

      test('retries with incremented name on branch conflict', () async {
        mockRunner.when(
          'git branch swarm/test',
          ProcessResult(-1,1, '', 'fatal: A branch named \'swarm/test\' already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-2',
          ProcessResult(-1,0, '', ''),
        );
        mockRunner.when(
          'git worktree add /repo/.git/worktrees/swarm-test-2 swarm/test-2',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.createWorktree('/repo', 'swarm/test');
        expect(result.branch, 'swarm/test-2');
        expect(mockRunner.callLog.length, 4);
        expect(mockRunner.callLog[0], 'git branch swarm/test');
        expect(mockRunner.callLog[1], 'git branch swarm/test-2');
        expect(mockRunner.callLog[2], 'git worktree add /repo/.git/worktrees/swarm-test-2 swarm/test-2');
        expect(mockRunner.callLog[3], 'git rev-parse HEAD');
      });

      test('retries up to 5 times then throws exception', () async {
        // attempt 0 = original name, attempt 1 = name-2, ..., attempt 4 = name-5
        // All 5 attempts fail; -local fallback also fails → exception thrown.
        mockRunner.when(
          'git branch swarm/test',
          ProcessResult(-1,1, '', 'fatal: A branch named already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-2',
          ProcessResult(-1,1, '', 'fatal: A branch named already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-3',
          ProcessResult(-1,1, '', 'fatal: A branch named already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-4',
          ProcessResult(-1,1, '', 'fatal: A branch named already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-5',
          ProcessResult(-1,1, '', 'fatal: A branch named already exists.'),
        );
        mockRunner.when(
          'git branch swarm/test-local',
          ProcessResult(-1,1, '', 'fatal: A branch name already exists.'),
        );

        await expectLater(
          service.createWorktree('/repo', 'swarm/test'),
          throwsA(isA<WorktreeException>()),
        );
        // 5 conflict attempts + 1 -local fallback = 6 branch calls total
        expect(
          mockRunner.callLog.where((c) => c.startsWith('git branch swarm/test')).length,
          6,
        );
      });

      test('removes existing worktree on conflict then retries', () async {
        mockRunner.when(
          'git branch swarm/test',
          ProcessResult(-1,0, '', ''),
        );
        // First worktree add fails because directory already exists, then succeeds.
        mockRunner.whenSequence('git worktree add /repo/.git/worktrees/swarm-test swarm/test', [
          ProcessResult(-1,
            1, '',
            'fatal: \'/repo/.git/worktrees/swarm-test\' already exists',
          ),
          ProcessResult(-1, 0, '', ''),
        ]);
        // remove --force is called when add fails with "already exists"
        mockRunner.when(
          'git worktree remove --force /repo/.git/worktrees/swarm-test',
          ProcessResult(-1, 0, '', ''),
        );

        final result = await service.createWorktree('/repo', 'swarm/test');
        expect(result.branch, 'swarm/test');
        expect(
          mockRunner.callLog,
          contains('git worktree remove --force /repo/.git/worktrees/swarm-test'),
        );
      });

      test('handles remote branch conflict by appending -local', () async {
        mockRunner.when(
          'git branch swarm/test',
          ProcessResult(-1,
            128, '',
            'fatal: A branch named \'swarm/test\' already exists.\n'
            'The branch name may have been created by a remote tracking branch.',
          ),
        );
        mockRunner.when(
          'git branch swarm/test-local',
          ProcessResult(-1,0, '', ''),
        );
        mockRunner.when(
          'git worktree add /repo/.git/worktrees/swarm-test swarm/test-local',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.createWorktree('/repo', 'swarm/test');
        expect(result.branch, 'swarm/test-local');
        expect(mockRunner.callLog.length, 4);
        expect(mockRunner.callLog[1], 'git branch swarm/test-local');
        expect(mockRunner.callLog[3], 'git rev-parse HEAD');
      });

      test('respects custom worktreePath parameter', () async {
        mockRunner.when(
          'git branch feature',
          ProcessResult(-1,0, '', ''),
        );
        mockRunner.when(
          'git worktree add /custom/path feature',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.createWorktree('/repo', 'feature',
            worktreePath: '/custom/path');
        expect(result.path, '/custom/path');
        expect(
          mockRunner.callLog,
          contains('git worktree add /custom/path feature'),
        );
      });
    });

    group('removeWorktree', () {
      test('removes worktree without force', () async {
        mockRunner.when(
          'git worktree remove /path/to/worktree',
          ProcessResult(-1,0, '', ''),
        );

        await service.removeWorktree('/repo', '/path/to/worktree');
        expect(
          mockRunner.callLog,
          contains('git worktree remove /path/to/worktree'),
        );
      });

      test('removes worktree with force flag', () async {
        mockRunner.when(
          'git worktree remove --force /path/to/worktree',
          ProcessResult(-1,0, '', ''),
        );

        await service.removeWorktree('/repo', '/path/to/worktree', force: true);
        expect(
          mockRunner.callLog,
          contains('git worktree remove --force /path/to/worktree'),
        );
      });

      test('ignores directory not found error', () async {
        mockRunner.when(
          'git worktree remove /path/to/worktree',
          ProcessResult(-1,
            1, '',
            'fatal: \'/path/to/worktree\' is not a working tree',
          ),
        );

        // Should not throw
        await service.removeWorktree('/repo', '/path/to/worktree');
      });
    });

    group('pruneWorktrees', () {
      test('executes git worktree prune', () async {
        mockRunner.when(
          'git worktree prune',
          ProcessResult(-1,0, '', ''),
        );

        await service.pruneWorktrees('/repo');
        expect(mockRunner.callLog, contains('git worktree prune'));
      });
    });

    group('createBranch', () {
      test('creates branch successfully', () async {
        mockRunner.when(
          'git branch new-branch',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.createBranch('/repo', 'new-branch');
        expect(result, 'new-branch');
        expect(mockRunner.callLog, contains('git branch new-branch'));
      });

      test('appends -local on branch name conflict', () async {
        mockRunner.when(
          'git branch new-branch',
          ProcessResult(-1,1, '', 'fatal: A branch named \'new-branch\' already exists.'),
        );
        mockRunner.when(
          'git branch new-branch-local',
          ProcessResult(-1,0, '', ''),
        );

        final result = await service.createBranch('/repo', 'new-branch');
        expect(result, 'new-branch-local');
        expect(mockRunner.callLog.length, 2);
        expect(mockRunner.callLog[0], 'git branch new-branch');
        expect(mockRunner.callLog[1], 'git branch new-branch-local');
      });
    });
  });

  group('WorktreeInfo', () {
    test('creates instance with all fields', () {
      final info = WorktreeInfo(
        path: '/repo/worktrees/feature',
        branch: 'refs/heads/feature',
        isMain: false,
        commit: 'abc123',
      );
      expect(info.path, '/repo/worktrees/feature');
      expect(info.branch, 'refs/heads/feature');
      expect(info.isMain, false);
      expect(info.commit, 'abc123');
    });

    test('supports null commit', () {
      final info = WorktreeInfo(
        path: '/repo',
        branch: 'refs/heads/main',
        isMain: true,
        commit: null,
      );
      expect(info.commit, isNull);
    });
  });

  group('WorktreeException', () {
    test('formats error message correctly', () {
      final ex = WorktreeException(
        command: 'git worktree add',
        exitCode: 1,
        stderr: 'fatal: worktree already exists',
      );
      expect(
        ex.toString(),
        'WorktreeException: git worktree add failed (exit 1): fatal: worktree already exists',
      );
    });

    test('implements Exception interface', () {
      final ex = WorktreeException(command: 'test', exitCode: 1, stderr: 'err');
      expect(ex, isA<Exception>());
    });
  });
}
