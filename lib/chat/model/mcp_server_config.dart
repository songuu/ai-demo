import 'package:hive_flutter/hive_flutter.dart';

part 'mcp_server_config.g.dart';

@HiveType(typeId: 19)
class McpServerConfig extends HiveObject {
  McpServerConfig({
    required this.id,
    required this.name,
    required this.type,
    this.command = '',
    this.args = const [],
    this.url,
    this.env = const {},
    this.enabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cachedTools,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// stdio | sse
  @HiveField(2)
  String type;

  /// For stdio: executable path
  @HiveField(3)
  String command;

  /// For stdio: command arguments
  @HiveField(4)
  List<String> args;

  /// For SSE: endpoint URL
  @HiveField(5)
  String? url;

  @HiveField(6)
  Map<String, String> env;

  @HiveField(7)
  bool enabled;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  /// Cached tool definitions from the server
  @HiveField(10)
  List<Map<String, dynamic>>? cachedTools;

  McpServerConfig copyWith({
    String? name,
    String? type,
    String? command,
    List<String>? args,
    String? url,
    Map<String, String>? env,
    bool? enabled,
    List<Map<String, dynamic>>? cachedTools,
  }) {
    return McpServerConfig(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      command: command ?? this.command,
      args: args ?? this.args,
      url: url ?? this.url,
      env: env ?? this.env,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      cachedTools: cachedTools ?? this.cachedTools,
    );
  }
}
