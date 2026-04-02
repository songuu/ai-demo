import 'package:hive_flutter/hive_flutter.dart';

part 'swarm_session.g.dart';

@HiveType(typeId: 26)
enum SwarmSessionStatus {
  @HiveField(0)
  initializing,
  @HiveField(1)
  running,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  failed,
}

/// A swarm session ties together an AgentTask, a Worktree, and a CodSession.
@HiveType(typeId: 21)
class SwarmSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String worktreeId;

  /// Links to CodSession.id for terminal management.
  @HiveField(3)
  String? codSessionId;

  @HiveField(4)
  SwarmSessionStatus status;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  /// The agent type duplicated here for quick display without joins.
  @HiveField(7)
  String agentType;

  /// Short title duplicated from AgentTask for list display.
  @HiveField(8)
  String title;

  /// The worktree branch name.
  @HiveField(9)
  String branch;

  SwarmSession({
    required this.id,
    required this.taskId,
    required this.worktreeId,
    this.codSessionId,
    this.status = SwarmSessionStatus.initializing,
    required this.createdAt,
    DateTime? updatedAt,
    required this.agentType,
    required this.title,
    this.branch = '',
  }) : updatedAt = updatedAt ?? createdAt;

  SwarmSession copyWith({
    String? codSessionId,
    SwarmSessionStatus? status,
    DateTime? updatedAt,
    String? branch,
  }) {
    return SwarmSession(
      id: id,
      taskId: taskId,
      worktreeId: worktreeId,
      codSessionId: codSessionId ?? this.codSessionId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      agentType: agentType,
      title: title,
      branch: branch ?? this.branch,
    );
  }
}
