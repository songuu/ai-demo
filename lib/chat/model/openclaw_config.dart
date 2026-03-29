import 'package:hive_flutter/hive_flutter.dart';

part 'openclaw_config.g.dart';

@HiveType(typeId: 20)
class OpenClawConfig extends HiveObject {
  OpenClawConfig({
    required this.id,
    this.gatewayUrl = 'ws://127.0.0.1:18789',
    this.enabled = false,
    this.acpxPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.cachedStatus,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  String id;

  /// WebSocket Gateway URL
  @HiveField(1)
  String gatewayUrl;

  @HiveField(2)
  bool enabled;

  /// Path to acpx CLI executable
  @HiveField(3)
  String? acpxPath;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  /// Last known status from the gateway
  @HiveField(6)
  Map<String, dynamic>? cachedStatus;

  OpenClawConfig copyWith({
    String? gatewayUrl,
    bool? enabled,
    String? acpxPath,
    Map<String, dynamic>? cachedStatus,
  }) {
    return OpenClawConfig(
      id: id,
      gatewayUrl: gatewayUrl ?? this.gatewayUrl,
      enabled: enabled ?? this.enabled,
      acpxPath: acpxPath ?? this.acpxPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      cachedStatus: cachedStatus ?? this.cachedStatus,
    );
  }
}
