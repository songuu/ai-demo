import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/openclaw_config.dart';

class OpenClawStore {
  OpenClawStore._();

  static const _boxName = 'openclaw_config';
  static Box<OpenClawConfig>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<OpenClawConfig>(_boxName);
  }

  static OpenClawConfig? getConfig() {
    final values = _box?.values;
    return (values != null && values.isNotEmpty) ? values.first : null;
  }

  static Future<void> saveConfig(OpenClawConfig config) async {
    config.updatedAt = DateTime.now();
    await _box?.put(config.id, config);
  }

  static bool isConfigured() {
    final config = getConfig();
    return config != null && config.enabled;
  }
}
