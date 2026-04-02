import 'package:hive_flutter/hive_flutter.dart';

part 'worktree.g.dart';

@HiveType(typeId: 23)
class Worktree extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  String path;

  @HiveField(3)
  String branch;

  @HiveField(4)
  String? commit;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String remotePath;

  @HiveField(7)
  WorktreeStatus status;

  Worktree({
    required this.id,
    required this.sessionId,
    required this.path,
    required this.branch,
    this.commit,
    required this.createdAt,
    required this.remotePath,
    this.status = WorktreeStatus.idle,
  });

  Worktree copyWith({
    String? sessionId,
    String? commit,
    WorktreeStatus? status,
  }) {
    return Worktree(
      id: id,
      sessionId: sessionId ?? this.sessionId,
      path: path,
      branch: branch,
      commit: commit ?? this.commit,
      createdAt: createdAt,
      remotePath: remotePath,
      status: status ?? this.status,
    );
  }
}

@HiveType(typeId: 24)
enum WorktreeStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  idle,
  @HiveField(2)
  stale,
  @HiveField(3)
  deleted,
}
