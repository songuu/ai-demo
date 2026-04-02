import 'package:hive_flutter/hive_flutter.dart';

part 'agent_task.g.dart';

@HiveType(typeId: 25)
enum AgentTaskStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  running,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
}

@HiveType(typeId: 22)
class AgentTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String repoPath;

  /// 'claude' | 'codex' | 'gemini'
  @HiveField(4)
  String agentType;

  @HiveField(5)
  AgentTaskStatus status;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  AgentTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.repoPath,
    required this.agentType,
    this.status = AgentTaskStatus.pending,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  AgentTask copyWith({
    String? title,
    String? description,
    AgentTaskStatus? status,
    DateTime? updatedAt,
  }) {
    return AgentTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      repoPath: repoPath,
      agentType: agentType,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
