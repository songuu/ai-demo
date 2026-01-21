import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fl_lib/fl_lib.dart';

import '../model/cod_skill.dart';

/// Skill 存储管理
class CodSkillStore {
  static const String _boxName = 'cod_skills';
  static Box<CodSkill>? _box;

  CodSkillStore._();

  /// 初始化
  static Future<void> init() async {
    try {
      _box = await Hive.openBox<CodSkill>(_boxName);

      // 首次运行时添加预设 Skills
      if (_box!.isEmpty) {
        await _initializePresets();
      }

      Loggers.app.info('CodSkillStore initialized with ${_box!.length} skills');
    } catch (e) {
      Loggers.app.warning('Failed to open CodSkillStore: $e');
      rethrow;
    }
  }

  /// 初始化预设 Skills
  static Future<void> _initializePresets() async {
    final presets = CodSkill.getPresetSkills();
    for (final skill in presets) {
      await _box!.put(skill.id, skill);
    }
    Loggers.app.info('Initialized ${presets.length} preset skills');
  }

  /// 获取 Box
  static Box<CodSkill>? get box => _box;

  /// 监听变化
  static ValueListenable<Box<CodSkill>>? listenable() {
    return _box?.listenable();
  }

  /// 获取所有 Skills
  static List<CodSkill> all() {
    return _box?.values.toList() ?? [];
  }

  /// 按类型获取
  static List<CodSkill> byType(CodSkillType type) {
    return all().where((s) => s.type == type).toList();
  }

  /// 按提供商获取
  static List<CodSkill> byProvider(CodSkillProvider provider) {
    if (provider == CodSkillProvider.all) {
      return all();
    }
    return all()
        .where((s) => s.provider == provider || s.provider == CodSkillProvider.all)
        .toList();
  }

  /// 按标签获取
  static List<CodSkill> byTag(String tag) {
    return all().where((s) => s.tags.contains(tag)).toList();
  }

  /// 获取收藏
  static List<CodSkill> favorites() {
    return all().where((s) => s.isFavorite).toList();
  }

  /// 获取已启用
  static List<CodSkill> enabled() {
    return all().where((s) => s.isEnabled).toList();
  }

  /// 按 ID 获取
  static CodSkill? byId(String id) {
    return _box?.get(id);
  }

  /// 搜索
  static List<CodSkill> search(String query) {
    if (query.isEmpty) return all();
    final lowerQuery = query.toLowerCase();
    return all().where((s) {
      return s.name.toLowerCase().contains(lowerQuery) ||
          s.description.toLowerCase().contains(lowerQuery) ||
          s.content.toLowerCase().contains(lowerQuery) ||
          s.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// 添加
  static Future<void> add(CodSkill skill) async {
    await _box?.put(skill.id, skill);
    Loggers.app.info('Added skill: ${skill.name}');
  }

  /// 更新
  static Future<void> update(CodSkill skill) async {
    skill.updatedAt = DateTime.now();
    skill.syncStatus = 2; // 待同步
    await _box?.put(skill.id, skill);
    Loggers.app.info('Updated skill: ${skill.name}');
  }

  /// 删除
  static Future<void> remove(String id) async {
    await _box?.delete(id);
    Loggers.app.info('Removed skill: $id');
  }

  /// 批量删除
  static Future<void> removeAll(List<String> ids) async {
    await _box?.deleteAll(ids);
    Loggers.app.info('Removed ${ids.length} skills');
  }

  /// 清空
  static Future<void> clear() async {
    await _box?.clear();
    Loggers.app.info('Cleared all skills');
  }

  /// 切换收藏
  static Future<void> toggleFavorite(String id) async {
    final skill = byId(id);
    if (skill != null) {
      skill.isFavorite = !skill.isFavorite;
      skill.updatedAt = DateTime.now();
      skill.syncStatus = 2;
      await _box?.put(id, skill);
    }
  }

  /// 切换启用
  static Future<void> toggleEnabled(String id) async {
    final skill = byId(id);
    if (skill != null) {
      skill.isEnabled = !skill.isEnabled;
      skill.updatedAt = DateTime.now();
      skill.syncStatus = 2;
      await _box?.put(id, skill);
    }
  }

  /// 标记使用
  static Future<void> markUsed(String id) async {
    final skill = byId(id);
    if (skill != null) {
      skill.markUsed();
      await _box?.put(id, skill);
    }
  }

  /// 获取所有标签
  static List<String> getAllTags() {
    final tags = <String>{};
    for (final skill in all()) {
      tags.addAll(skill.tags);
    }
    return tags.toList()..sort();
  }

  /// 获取统计信息
  static Map<String, dynamic> getStats() {
    final skills = all();
    final byType = <CodSkillType, int>{};
    final byProvider = <CodSkillProvider, int>{};

    for (final skill in skills) {
      byType[skill.type] = (byType[skill.type] ?? 0) + 1;
      byProvider[skill.provider] = (byProvider[skill.provider] ?? 0) + 1;
    }

    return {
      'total': skills.length,
      'enabled': skills.where((s) => s.isEnabled).length,
      'favorites': skills.where((s) => s.isFavorite).length,
      'byType': byType,
      'byProvider': byProvider,
      'totalUseCount': skills.fold<int>(0, (sum, s) => sum + s.useCount),
    };
  }

  /// 导出为 JSON
  static Map<String, dynamic> exportToJson() {
    final skills = all().map((s) => s.toJson()).toList();
    return {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': skills.length,
      'skills': skills,
    };
  }

  /// 从 JSON 导入
  static Future<int> importFromJson(Map<String, dynamic> data) async {
    final skillsData = data['skills'] as List<dynamic>?;
    if (skillsData == null) return 0;

    int imported = 0;
    for (final skillJson in skillsData) {
      try {
        final skill = CodSkill.fromJson(skillJson as Map<String, dynamic>);
        // 生成新 ID 避免冲突
        final existingSkill = byId(skill.id);
        if (existingSkill != null) {
          skill.id = CodSkill.generateId();
        }
        skill.syncStatus = 2; // 待同步
        await add(skill);
        imported++;
      } catch (e) {
        Loggers.app.warning('Failed to import skill: $e');
      }
    }

    Loggers.app.info('Imported $imported skills');
    return imported;
  }

  /// 重置为预设
  static Future<void> resetToPresets() async {
    await clear();
    await _initializePresets();
  }

  /// 获取待同步的 Skills
  static List<CodSkill> getPendingSync() {
    return all().where((s) => s.syncStatus == 2).toList();
  }

  /// 标记已同步
  static Future<void> markSynced(String id, String? syncId) async {
    final skill = byId(id);
    if (skill != null) {
      skill.syncId = syncId;
      skill.syncStatus = 1;
      await _box?.put(id, skill);
    }
  }

  /// 批量标记已同步
  static Future<void> markAllSynced(Map<String, String?> idMap) async {
    for (final entry in idMap.entries) {
      await markSynced(entry.key, entry.value);
    }
  }

  /// 关闭
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
