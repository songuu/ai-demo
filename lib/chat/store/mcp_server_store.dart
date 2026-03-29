import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/mcp_server_config.dart';

class McpServerStore {
  McpServerStore._();

  static const _boxName = 'mcp_servers';
  static Box<McpServerConfig>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<McpServerConfig>(_boxName);
  }

  static List<McpServerConfig> all() {
    return _box?.values.toList() ?? <McpServerConfig>[];
  }

  static List<McpServerConfig> enabled() {
    return all().where((s) => s.enabled).toList();
  }

  static Future<void> put(McpServerConfig config) async {
    config.updatedAt = DateTime.now();
    await _box?.put(config.id, config);
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
  }

  static McpServerConfig? byId(String id) => _box?.get(id);

  static ValueListenable<Box<McpServerConfig>>? listenable() {
    return _box?.listenable();
  }
}
