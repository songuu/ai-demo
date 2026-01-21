import 'package:hive_flutter/hive_flutter.dart';

part 'cod_session.g.dart';

@HiveType(typeId: 9)
enum CodSessionStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  running,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
}

@HiveType(typeId: 10)
class CodSession extends HiveObject {
  CodSession({
    required this.id,
    required this.provider,
    required this.title,
    required this.cwd,
    required this.command,
    required this.args,
    required this.logPath,
    required this.createdAt,
    required this.updatedAt,
    this.exitCode,
    this.status = CodSessionStatus.pending,
  });

  @HiveField(0)
  String id;

  /// codex / claude / gemini / custom
  @HiveField(1)
  String provider;

  @HiveField(2)
  String title;

  @HiveField(3)
  String cwd;

  /// Executable to launch (e.g. codex / claude / gemini).
  @HiveField(4)
  String command;

  /// Command arguments.
  @HiveField(5)
  List<String> args;

  /// Log file path on disk.
  @HiveField(6)
  String logPath;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  @HiveField(9)
  CodSessionStatus status;

  @HiveField(10)
  int? exitCode;

  CodSession copyWith({
    String? title,
    String? cwd,
    String? command,
    List<String>? args,
    String? logPath,
    CodSessionStatus? status,
    int? exitCode,
    DateTime? updatedAt,
  }) {
    return CodSession(
      id: id,
      provider: provider,
      title: title ?? this.title,
      cwd: cwd ?? this.cwd,
      command: command ?? this.command,
      args: args ?? this.args,
      logPath: logPath ?? this.logPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      exitCode: exitCode ?? this.exitCode,
    );
  }
}
