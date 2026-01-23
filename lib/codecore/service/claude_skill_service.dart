import 'dart:io';

import 'package:fl_lib/fl_lib.dart';
import 'package:server_box/codecore/model/claude_skill.dart';

/// Claude Code Skill 本地文件服务
/// 管理 ~/.claude/skills/ 目录下的 skills
/// 参考: https://code.claude.com/docs/en/skills
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
  /// 
  /// [name] skill 名称（也是目录名和 slash command）
  /// [description] skill 描述
  /// [content] SKILL.md 主体内容
  /// [context] 上下文设置: inline, fork, none
  /// [disableModelInvocation] 是否禁用模型自动调用
  /// [allowedTools] 允许的工具列表
  /// [disallowedTools] 禁止的工具列表
  /// [agent] 代理类型
  /// [allowMultipleTurns] 是否允许多轮对话
  /// [supportingFiles] 支持文件列表
  static Future<ClaudeSkill> createSkill({
    required String name,
    required String description,
    required String content,
    String? context,
    bool disableModelInvocation = false,
    List<String>? allowedTools,
    List<String>? disallowedTools,
    String? agent,
    bool? allowMultipleTurns,
    List<NewSkillFile>? supportingFiles,
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
      agent: agent,
      allowMultipleTurns: allowMultipleTurns,
    );
    
    final skillFile = File('$skillDirPath${Platform.pathSeparator}SKILL.md');
    await skillFile.writeAsString(skill.toSkillMd());
    
    // 创建支持文件
    if (supportingFiles != null && supportingFiles.isNotEmpty) {
      for (final sf in supportingFiles) {
        await addSupportingFile(
          skillDirPath,
          sf.relativePath,
          sf.content,
        );
      }
    }
    
    Loggers.app.info('Created skill: $name at $skillDirPath');
    
    // 重新读取以获取完整信息
    return ClaudeSkill.fromFile(skillFile, isSystem: false);
  }

  /// 更新 skill（仅支持用户自定义 skill）
  static Future<ClaudeSkill> updateSkill(
    ClaudeSkill skill, {
    List<NewSkillFile>? newFiles,
    List<String>? deleteFiles,
  }) async {
    if (skill.isSystem) {
      throw Exception('Cannot modify system skill');
    }
    
    final skillFile = File('${skill.path}${Platform.pathSeparator}SKILL.md');
    if (!await skillFile.exists()) {
      throw Exception('Skill file not found');
    }
    
    // 更新 SKILL.md
    await skillFile.writeAsString(skill.toSkillMd());
    
    // 删除指定的文件
    if (deleteFiles != null && deleteFiles.isNotEmpty) {
      for (final relativePath in deleteFiles) {
        await deleteSupportingFile(skill.path, relativePath);
      }
    }
    
    // 添加/更新新文件
    if (newFiles != null && newFiles.isNotEmpty) {
      for (final sf in newFiles) {
        await addSupportingFile(skill.path, sf.relativePath, sf.content);
      }
    }
    
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
  static Future<String> readSupportingFile(String skillPath, String relativePath) async {
    final normalizedPath = relativePath.replaceAll('/', Platform.pathSeparator);
    final filePath = '$skillPath${Platform.pathSeparator}$normalizedPath';
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw Exception('File not found: $relativePath');
    }
    
    return await file.readAsString();
  }

  /// 添加/更新支持文件
  /// 
  /// [skillPath] skill 目录路径
  /// [relativePath] 相对路径，如 "scripts/validate.sh" 或 "template.md"
  /// [content] 文件内容
  static Future<void> addSupportingFile(
    String skillPath,
    String relativePath,
    String content,
  ) async {
    final normalizedPath = relativePath.replaceAll('/', Platform.pathSeparator);
    final filePath = '$skillPath${Platform.pathSeparator}$normalizedPath';
    final file = File(filePath);
    
    // 确保父目录存在
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
    
    Loggers.app.info('Added supporting file: $relativePath');
  }

  /// 删除支持文件
  static Future<void> deleteSupportingFile(String skillPath, String relativePath) async {
    final normalizedPath = relativePath.replaceAll('/', Platform.pathSeparator);
    final filePath = '$skillPath${Platform.pathSeparator}$normalizedPath';
    final file = File(filePath);
    
    if (await file.exists()) {
      await file.delete();
      Loggers.app.info('Deleted supporting file: $relativePath');
      
      // 如果目录为空，删除目录
      final parent = file.parent;
      if (await parent.exists() && parent.path != skillPath) {
        final children = await parent.list().toList();
        if (children.isEmpty) {
          await parent.delete();
        }
      }
    }
  }

  /// 创建 scripts 子目录
  static Future<void> ensureScriptsDir(String skillPath) async {
    final dir = Directory('$skillPath${Platform.pathSeparator}scripts');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// 创建 examples 子目录
  static Future<void> ensureExamplesDir(String skillPath) async {
    final dir = Directory('$skillPath${Platform.pathSeparator}examples');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
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
  /// 只允许字母、数字、连字符和下划线，且以字母开头
  static bool isValidSkillName(String name) {
    final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$');
    return regex.hasMatch(name) && name.length <= 50;
  }

  /// 检查 skill 是否存在
  static Future<bool> skillExists(String name) async {
    final skillDir = Directory('$userSkillsPath${Platform.pathSeparator}$name');
    return await skillDir.exists();
  }
  
  /// 获取默认的脚本模板
  static String getDefaultScriptTemplate(String scriptName) {
    final ext = scriptName.split('.').last.toLowerCase();
    
    switch (ext) {
      case 'sh':
      case 'bash':
        return '''#!/bin/bash
# $scriptName
# 这个脚本由 Claude 执行

set -e

# 在这里添加你的脚本逻辑
echo "Running $scriptName..."

# 示例：接收参数
if [ \$# -gt 0 ]; then
    echo "Arguments: \$@"
fi
''';
      case 'py':
        return '''#!/usr/bin/env python3
"""
$scriptName
这个脚本由 Claude 执行
"""

import sys

def main():
    print(f"Running $scriptName...")
    
    # 在这里添加你的脚本逻辑
    if len(sys.argv) > 1:
        print(f"Arguments: {sys.argv[1:]}")

if __name__ == "__main__":
    main()
''';
      case 'js':
        return '''#!/usr/bin/env node
/**
 * $scriptName
 * 这个脚本由 Claude 执行
 */

console.log("Running $scriptName...");

// 在这里添加你的脚本逻辑
if (process.argv.length > 2) {
    console.log("Arguments:", process.argv.slice(2));
}
''';
      case 'ps1':
        return '''# $scriptName
# 这个脚本由 Claude 执行 (PowerShell)

Write-Host "Running $scriptName..."

# 在这里添加你的脚本逻辑
if (\$args.Count -gt 0) {
    Write-Host "Arguments: \$args"
}
''';
      default:
        return '# $scriptName\n# 在这里添加你的脚本内容\n';
    }
  }
  
  /// 获取默认的示例文件模板
  static String getDefaultExampleTemplate(String fileName) {
    return '''# Example: $fileName

这是一个示例文件，展示了预期的输出格式。

## 使用说明

在 SKILL.md 中引用此示例：
\`\`\`
参考 examples/$fileName 查看预期输出格式。
\`\`\`

## 示例内容

在这里添加示例内容...
''';
  }
  
  /// 获取默认的模板文件
  static String getDefaultTemplateContent(String fileName) {
    return '''# Template: $fileName

这是一个模板文件，Claude 会根据需要填充此模板。

## 模板变量

使用 \${{variable_name}} 语法定义变量：

- \${{title}} - 标题
- \${{description}} - 描述
- \${{content}} - 主要内容

## 模板内容

\${{content}}
''';
  }
}
