/// Non-persistent DTO for git worktree list output.
class WorktreeInfo {
  final String path;
  final String? branch;
  final bool isMain;
  final String? commit;

  const WorktreeInfo({
    required this.path,
    required this.branch,
    required this.isMain,
    this.commit,
  });
}
