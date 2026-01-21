import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_lib/fl_lib.dart';

import '../model/cod_provider_config.dart';

/// CLI 配置存储
class CodConfigStore {
  static const String _boxName = 'cod_provider_configs';
  late Box<CodProviderConfig> _box;

  static final CodConfigStore _instance = CodConfigStore._internal();
  factory CodConfigStore() => _instance;
  CodConfigStore._internal();

  /// 初始化
  Future<void> init() async {
    try {
      _box = await Hive.openBox<CodProviderConfig>(_boxName);
      
      // 如果是首次运行，初始化默认配置
      if (_box.isEmpty) {
        await _initializeDefaults();
      }
      
      Loggers.app.info('CodConfigStore initialized with ${_box.length} configs');
    } catch (e) {
      Loggers.app.warning('Failed to open CodConfigStore: $e');
      rethrow;
    }
  }

  /// 初始化默认配置
  Future<void> _initializeDefaults() async {
    final configs = [
      CodProviderConfig.defaultClaude(),
      CodProviderConfig.defaultCodex(),
      CodProviderConfig.defaultGemini(),
    ];

    for (final config in configs) {
      await _box.put(config.provider, config);
    }
    
    Loggers.app.info('Initialized ${configs.length} default provider configs');
  }

  /// 获取所有配置
  List<CodProviderConfig> getAll() {
    return _box.values.toList();
  }

  /// 获取已启用的配置
  List<CodProviderConfig> getEnabled() {
    return _box.values.where((c) => c.enabled).toList();
  }

  /// 根据提供商获取配置
  CodProviderConfig? get(String provider) {
    return _box.get(provider.toLowerCase());
  }

  /// 保存或更新配置
  Future<void> save(CodProviderConfig config) async {
    config.updatedAt = DateTime.now();
    await _box.put(config.provider.toLowerCase(), config);
    Loggers.app.info('Saved config for provider: ${config.provider}');
  }

  /// 删除配置
  Future<void> delete(String provider) async {
    await _box.delete(provider.toLowerCase());
    Loggers.app.info('Deleted config for provider: $provider');
  }

  /// 切换启用状态
  Future<void> toggleEnabled(String provider) async {
    final config = get(provider);
    if (config != null) {
      config.enabled = !config.enabled;
      await save(config);
    }
  }

  /// 重置为默认配置
  Future<void> resetToDefaults() async {
    await _box.clear();
    await _initializeDefaults();
    Loggers.app.info('Reset all configs to defaults');
  }

  /// 导出配置
  Map<String, dynamic> exportConfigs() {
    final configs = <String, dynamic>{};
    for (final entry in _box.toMap().entries) {
      configs[entry.key] = entry.value.toJson();
    }
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'configs': configs,
    };
  }

  /// 导入配置
  Future<void> importConfigs(Map<String, dynamic> data) async {
    final configs = data['configs'] as Map<String, dynamic>?;
    if (configs == null) return;

    for (final entry in configs.entries) {
      try {
        final config = CodProviderConfig.fromJson(entry.value as Map<String, dynamic>);
        await save(config);
      } catch (e) {
        Loggers.app.warning('Failed to import config ${entry.key}: $e');
      }
    }
    
    Loggers.app.info('Imported ${configs.length} configs');
  }

  /// 监听变化
  Stream<BoxEvent> watch() {
    return _box.watch();
  }

  /// 关闭
  Future<void> close() async {
    await _box.close();
  }
}
