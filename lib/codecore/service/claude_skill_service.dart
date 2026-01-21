import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:server_box/codecore/model/claude_skill.dart';

/// Claude Code Skill 本地文件服务
/// 管理 ~/.claude/skills/ 目录下的 skills
class ClaudeSkillService {
  ClaudeSkillService._();

  /// 用户 skills 目录路径
  static String get userSkillsPath {
    final home = Platform.environment['USERPROFILE'] ?? 
                 Platform.environment['HOME'] ?? '';
    return '$home${Platform.pathSeparator}.claude${Platform.pathSeparator}skills';
  }

  /// 系统/内置 skills 路径（Claude Code 安装目录）
  static List<String> get systemSkillsPaths {
    final paths = <String>[];
    
    // Windows: 通常在 AppData 或程序安装目录
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ?? '';
      if (appData.isNotEmpty) {
        paths.add('$appData${Platform.pathSeparator}Claude${Platform.pathSeparator}skills');
        paths.add('$appData${Platform.pathSeparator}Programs${Platform.pathSeparator}claude${Platform.pathSeparator}skills');
      }
      // npm 全局安装路径
      final appDataRoaming = Platform.environment['APPDATA'] ?? '';
      if (appDataRoaming.isNotEmpty) {
        paths.add('$appDataRoaming${Platform.pathSeparator}npm${Platform.pathSeparator}node_modules${Platform.pathSeparator}@anthropic-ai${Platform.pathSeparator}claude-code${Platform.pathSeparator}skills');
      }
    } else if (Platform.isMacOS) {
      paths.add('/usr/local/lib/node_modules/@anthropic-ai/claude-code/skills');
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        paths.add('$home/.nvm/versions/node/*/lib/node_modules/@anthropic-ai/claude-code/skills');
      }
    } else if (Platform.isLinux) {
      paths.add('/usr/lib/node_modules/@anthropic-ai/claude-code/skills');
      final home = Platform.environment['HOME'] ?? '';
      if (home.isNotEmpty) {
        paths.add('$home/.nvm/versions/node/*/lib/node_modules/@anthropic-ai/claude-code/skills');
      }
    }
    
    return paths;
  }

  /// 获取所有 skills（用户自定义 + 系统）
  static Future<List<ClaudeSkill>> getAllSkills() async {
    final skills = <ClaudeSkill>[];
    
    // 加载用户自定义 skills
    skills.addAll(await getUserSkills());
    
    // 加载系统 skills
    skills.addAll(await getSystemSkills());
    
    return skills;
  }

  /// 获取用户自定义 skills
  static Future<List<ClaudeSkill>> getUserSkills() async {
    return _loadSkillsFromDirectory(userSkillsPath, isSystem: false);
  }

  /// 获取系统 skills
  static Future<List<ClaudeSkill>> getSystemSkills() async {
    final skills = <ClaudeSkill>[];
    
    for (final path in systemSkillsPaths) {
      skills.addAll(await _loadSkillsFromDirectory(path, isSystem: true));
    }
    
    return skills;
  }

  /// 从目录加载 skills
  static Future<List<ClaudeSkill>> _loadSkillsFromDirectory(
    String dirPath, {
    required bool isSystem,
  }) async {
    final skills = <ClaudeSkill>[];
    final dir = Directory(dirPath);
    
    if (!await dir.exists()) {
      return skills;
    }
    
    try {
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final skillFile = File('${entity.path}${Platform.pathSeparator}SKILL.md');
          if (await skillFile.exists()) {
            try {
              final skill = ClaudeSkill.fromFile(skillFile, isSystem: isSystem);
              skills.add(skill);
            } catch (e) {
              Loggers.app.warning('Failed to load skill from ${entity.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      Loggers.app.warning('Failed to list skills in $dirPath: $e');
    }
    
    return skills;
  }

  /// 创建新的 skill
  static Future<ClaudeSkill> createSkill({
    required String name,
    required String description,
    required String content,
    String? context,
    bool disableModelInvocation = false,
    List<String>? allowedTools,
    List<String>? disallowedTools,
  }) async {
    // 确保用户 skills 目录存在
    final userDir = Directory(userSkillsPath);
    if (!await userDir.exists()) {
      await userDir.create(recursive: true);
    }
    
    // 创建 skill 目录
    final skillDirPath = '$userSkillsPath${Platform.pathSeparator}$name';
    final skillDir = Directory(skillDirPath);
    
    if (await skillDir.exists()) {
      throw Exception('Skill "$name" already exists');
    }
    
    await skillDir.create(recursive: true);
    
    // 创建 SKILL.md 文件
    final skill = ClaudeSkill(
      name: name,
      description: description,
      content: content,
      rawContent: '',
      path: skillDirPath,
      isSystem: false,
      context: context,
      disableModelInvocation: disableModelInvocation,
      allowedTools: allowedTools,
      disallowedTools: disallowedTools,
    );
    
    final skillFile = File('$skillDirPath${Platform.pathSeparator}SKILL.md');
    await skillFile.writeAsString(skill.toSkillMd());
    
    Loggers.app.info('Created skill: $name at $skillDirPath');
    
    // 重新读取以获取完整信息
    return ClaudeSkill.fromFile(skillFile, isSystem: false);
  }

  /// 更新 skill（仅支持用户自定义 skill）
  static Future<ClaudeSkill> updateSkill(ClaudeSkill skill) async {
    if (skill.isSystem) {
      throw Exception('Cannot modify system skill');
    }
    
    final skillFile = File('${skill.path}${Platform.pathSeparator}SKILL.md');
    if (!await skillFile.exists()) {
      throw Exception('Skill file not found');
    }
    
    await skillFile.writeAsString(skill.toSkillMd());
    
    Loggers.app.info('Updated skill: ${skill.name}');
    
    return ClaudeSkill.fromFile(skillFile, isSystem: false);
  }

  /// 删除 skill（仅支持用户自定义 skill）
  static Future<void> deleteSkill(ClaudeSkill skill) async {
    if (skill.isSystem) {
      throw Exception('Cannot delete system skill');
    }
    
    final skillDir = Directory(skill.path);
    if (await skillDir.exists()) {
      await skillDir.delete(recursive: true);
      Loggers.app.info('Deleted skill: ${skill.name}');
    }
  }

  /// 重命名 skill（仅支持用户自定义 skill）
  static Future<ClaudeSkill> renameSkill(ClaudeSkill skill, String newName) async {
    if (skill.isSystem) {
      throw Exception('Cannot rename system skill');
    }
    
    final oldDir = Directory(skill.path);
    final newDirPath = '$userSkillsPath${Platform.pathSeparator}$newName';
    final newDir = Directory(newDirPath);
    
    if (await newDir.exists()) {
      throw Exception('Skill "$newName" already exists');
    }
    
    await oldDir.rename(newDirPath);
    
    // 更新 SKILL.md 中的 name
    final updatedSkill = skill.copyWith(name: newName, path: newDirPath);
    final skillFile = File('$newDirPath${Platform.pathSeparator}SKILL.md');
    await skillFile.writeAsString(updatedSkill.toSkillMd());
    
    Loggers.app.info('Renamed skill: ${skill.name} -> $newName');
    
    return ClaudeSkill.fromFile(skillFile, isSystem: false);
  }

  /// 复制 skill
  static Future<ClaudeSkill> duplicateSkill(ClaudeSkill skill, String newName) async {
    final newDirPath = '$userSkillsPath${Platform.pathSeparator}$newName';
    final newDir = Directory(newDirPath);
    
    if (await newDir.exists()) {
      throw Exception('Skill "$newName" already exists');
    }
    
    await newDir.create(recursive: true);
    
    // 复制所有文件
    final sourceDir = Directory(skill.path);
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourceDir.path.length);
        final newFilePath = '$newDirPath$relativePath';
        final newFile = File(newFilePath);
        await newFile.parent.create(recursive: true);
        await entity.copy(newFilePath);
      }
    }
    
    // 更新 SKILL.md 中的 name
    final skillFile = File('$newDirPath${Platform.pathSeparator}SKILL.md');
    final newSkill = ClaudeSkill.fromFile(skillFile, isSystem: false);
    final updatedSkill = newSkill.copyWith(name: newName);
    await skillFile.writeAsString(updatedSkill.toSkillMd());
    
    Loggers.app.info('Duplicated skill: ${skill.name} -> $newName');
    
    return ClaudeSkill.fromFile(skillFile, isSystem: false);
  }

  /// 读取支持文件内容
  static Future<String> readSupportingFile(ClaudeSkill skill, String fileName) async {
    final filePath = '${skill.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('File not found: $fileName');
    }
    
    return await file.readAsString();
  }

  /// 添加支持文件
  static Future<void> addSupportingFile(
    ClaudeSkill skill,
    String fileName,
    String content,
  ) async {
    if (skill.isSystem) {
      throw Exception('Cannot modify system skill');
    }
    
    final filePath = '${skill.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    
    Loggers.app.info('Added supporting file: $fileName to ${skill.name}');
  }

  /// 删除支持文件
  static Future<void> deleteSupportingFile(ClaudeSkill skill, String fileName) async {
    if (skill.isSystem) {
      throw Exception('Cannot modify system skill');
    }
    
    final filePath = '${skill.path}${Platform.pathSeparator}$fileName';
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      Loggers.app.info('Deleted supporting file: $fileName from ${skill.name}');
    }
  }

  /// 打开 skill 目录
  static Future<void> openSkillDirectory(ClaudeSkill skill) async {
    final dir = Directory(skill.path);
    if (!await dir.exists()) {
      throw Exception('Skill directory not found');
    }
    
    if (Platform.isWindows) {
      await Process.run('explorer', [skill.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [skill.path]);
    } else {
      await Process.run('xdg-open', [skill.path]);
    }
  }

  /// 打开用户 skills 目录
  static Future<void> openUserSkillsDirectory() async {
    final dir = Directory(userSkillsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    if (Platform.isWindows) {
      await Process.run('explorer', [userSkillsPath]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [userSkillsPath]);
    } else {
      await Process.run('xdg-open', [userSkillsPath]);
    }
  }

  /// 检查 skill 名称是否有效
  static bool isValidSkillName(String name) {
    // 只允许字母、数字、连字符和下划线
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  /// 检查 skill 是否存在
  static Future<bool> skillExists(String name) async {
    final skillDir = Directory('$userSkillsPath${Platform.pathSeparator}$name');
    return await skillDir.exists();
  }
}
