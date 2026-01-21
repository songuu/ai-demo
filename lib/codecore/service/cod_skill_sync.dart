import 'dart:convert';
import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:server_box/codecore/model/cod_skill.dart';
import 'package:server_box/codecore/store/cod_skill_store.dart';

/// Skill 同步服务
/// 支持本地文件同步和云端同步
class CodSkillSyncService {
  CodSkillSyncService._();

  /// 同步目录
  static String? _syncDir;

  /// 获取同步目录
  static Future<String> getSyncDir() async {
    if (_syncDir != null) return _syncDir!;
    
    final docDir = Paths.doc;
    final syncDir = '$docDir${Platform.pathSeparator}cod_skills_sync';
    
    final dir = Directory(syncDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    _syncDir = syncDir;
    return syncDir;
  }

  /// 同步 Skills
  static Future<String> sync() async {
    try {
      // 1. 获取本地待同步的 Skills
      final pendingSkills = CodSkillStore.getPendingSync();
      
      // 2. 保存到本地同步目录
      int uploaded = 0;
      int downloaded = 0;
      
      if (pendingSkills.isNotEmpty) {
        uploaded = await _uploadSkills(pendingSkills);
      }
      
      // 3. 从同步目录加载新 Skills
      downloaded = await _downloadSkills();
      
      // 4. 返回结果
      if (uploaded == 0 && downloaded == 0) {
        return '已是最新，无需同步';
      }
      
      return '同步完成：上传 $uploaded 个，下载 $downloaded 个';
    } catch (e) {
      Loggers.app.warning('Skill sync failed: $e');
      rethrow;
    }
  }

  /// 上传 Skills 到同步目录
  static Future<int> _uploadSkills(List<CodSkill> skills) async {
    final syncDir = await getSyncDir();
    int count = 0;
    
    for (final skill in skills) {
      try {
        final fileName = '${skill.id}.json';
        final file = File('$syncDir${Platform.pathSeparator}$fileName');
        
        final json = skill.toJson();
        final content = const JsonEncoder.withIndent('  ').convert(json);
        await file.writeAsString(content);
        
        // 标记已同步
        await CodSkillStore.markSynced(skill.id, skill.id);
        count++;
      } catch (e) {
        Loggers.app.warning('Failed to upload skill ${skill.id}: $e');
      }
    }
    
    return count;
  }

  /// 从同步目录下载 Skills
  static Future<int> _downloadSkills() async {
    final syncDir = await getSyncDir();
    final dir = Directory(syncDir);
    
    if (!await dir.exists()) return 0;
    
    int count = 0;
    final localSkills = CodSkillStore.all();
    final localIds = localSkills.map((s) => s.id).toSet();
    
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final skill = CodSkill.fromJson(json);
          
          // 检查是否已存在
          if (!localIds.contains(skill.id)) {
            skill.syncStatus = 1; // 已同步
            await CodSkillStore.add(skill);
            count++;
          } else {
            // 检查是否需要更新（远程更新时间更新）
            final localSkill = CodSkillStore.byId(skill.id);
            if (localSkill != null && 
                skill.updatedAt.isAfter(localSkill.updatedAt) &&
                localSkill.syncStatus != 2) {
              // 远程更新，且本地没有待同步的修改
              await CodSkillStore.update(skill);
              await CodSkillStore.markSynced(skill.id, skill.id);
              count++;
            }
          }
        } catch (e) {
          Loggers.app.warning('Failed to load skill from ${entity.path}: $e');
        }
      }
    }
    
    return count;
  }

  /// 导出所有 Skills 到指定目录
  static Future<String> exportTo(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final skills = CodSkillStore.all();
    int count = 0;
    
    for (final skill in skills) {
      try {
        final fileName = '${skill.id}.json';
        final file = File('$dirPath${Platform.pathSeparator}$fileName');
        
        final json = skill.toJson();
        final content = const JsonEncoder.withIndent('  ').convert(json);
        await file.writeAsString(content);
        count++;
      } catch (e) {
        Loggers.app.warning('Failed to export skill ${skill.id}: $e');
      }
    }
    
    // 同时导出索引文件
    final indexFile = File('$dirPath${Platform.pathSeparator}index.json');
    final indexData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'count': skills.length,
      'skills': skills.map((s) => {
        'id': s.id,
        'name': s.name,
        'type': s.type.index,
        'provider': s.provider.index,
        'updatedAt': s.updatedAt.toIso8601String(),
      }).toList(),
    };
    await indexFile.writeAsString(const JsonEncoder.withIndent('  ').convert(indexData));
    
    Loggers.app.info('Exported $count skills to $dirPath');
    return '成功导出 $count 个 Skills';
  }

  /// 从指定目录导入 Skills
  static Future<String> importFrom(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return '目录不存在';
    }
    
    int imported = 0;
    int skipped = 0;
    int failed = 0;
    
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('index.json')) {
        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final skill = CodSkill.fromJson(json);
          
          // 检查是否已存在
          final existing = CodSkillStore.byId(skill.id);
          if (existing != null) {
            // 比较更新时间决定是否更新
            if (skill.updatedAt.isAfter(existing.updatedAt)) {
              await CodSkillStore.update(skill);
              imported++;
            } else {
              skipped++;
            }
          } else {
            await CodSkillStore.add(skill);
            imported++;
          }
        } catch (e) {
          Loggers.app.warning('Failed to import skill from ${entity.path}: $e');
          failed++;
        }
      }
    }
    
    Loggers.app.info('Import complete: $imported imported, $skipped skipped, $failed failed');
    return '导入完成：$imported 个新增/更新，$skipped 个跳过，$failed 个失败';
  }

  /// 清理同步目录中已删除的 Skills
  static Future<int> cleanupSyncDir() async {
    final syncDir = await getSyncDir();
    final dir = Directory(syncDir);
    
    if (!await dir.exists()) return 0;
    
    final localIds = CodSkillStore.all().map((s) => s.id).toSet();
    int deleted = 0;
    
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        final id = fileName.replaceAll('.json', '');
        
        if (!localIds.contains(id)) {
          try {
            await entity.delete();
            deleted++;
          } catch (e) {
            Loggers.app.warning('Failed to delete sync file: ${entity.path}');
          }
        }
      }
    }
    
    Loggers.app.info('Cleaned up $deleted sync files');
    return deleted;
  }

  /// 获取同步状态
  static Future<Map<String, dynamic>> getSyncStatus() async {
    final syncDir = await getSyncDir();
    final dir = Directory(syncDir);
    
    int localCount = CodSkillStore.all().length;
    int pendingCount = CodSkillStore.getPendingSync().length;
    int syncedCount = CodSkillStore.all().where((s) => s.syncStatus == 1).length;
    int remoteCount = 0;
    
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json') && !entity.path.endsWith('index.json')) {
          remoteCount++;
        }
      }
    }
    
    return {
      'localCount': localCount,
      'remoteCount': remoteCount,
      'pendingCount': pendingCount,
      'syncedCount': syncedCount,
      'syncDir': syncDir,
      'lastSync': null, // TODO: 实现最后同步时间记录
    };
  }

  /// 强制全量同步
  static Future<String> forceSync() async {
    // 标记所有本地 Skills 为待同步
    final skills = CodSkillStore.all();
    for (final skill in skills) {
      skill.syncStatus = 2;
      await CodSkillStore.update(skill);
    }
    
    // 执行同步
    return await sync();
  }

  /// 解决冲突
  static Future<void> resolveConflict(String skillId, bool useLocal) async {
    final skill = CodSkillStore.byId(skillId);
    if (skill == null) return;
    
    if (useLocal) {
      // 使用本地版本，标记为待同步
      skill.syncStatus = 2;
      await CodSkillStore.update(skill);
    } else {
      // 使用远程版本
      final syncDir = await getSyncDir();
      final file = File('$syncDir${Platform.pathSeparator}$skillId.json');
      
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final remoteSkill = CodSkill.fromJson(json);
          remoteSkill.syncStatus = 1;
          await CodSkillStore.update(remoteSkill);
        } catch (e) {
          Loggers.app.warning('Failed to resolve conflict for $skillId: $e');
        }
      }
    }
  }
}
