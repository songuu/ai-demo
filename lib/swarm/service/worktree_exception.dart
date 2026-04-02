/// Exception thrown when a git worktree operation fails.
class WorktreeException implements Exception {
  final String command;
  final int exitCode;
  final String stderr;

  const WorktreeException({
    required this.command,
    required this.exitCode,
    required this.stderr,
  });

  @override
  String toString() =>
      'WorktreeException: $command failed (exit $exitCode): $stderr';
}
