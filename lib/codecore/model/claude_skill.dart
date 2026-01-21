import 'dart:io';

/// Claude Code Skill 数据模型
/// 参考: https://code.claude.com/docs/en/skills
class ClaudeSkill {
  /// Skill 名称（目录名）
  final String name;
  
  /// Skill 描述（从 frontmatter 或内容提取）
  final String description;
  
  /// Skill 内容（SKILL.md 的主体部分）
  final String content;
  
  /// SKILL.md 的原始完整内容
  final String rawContent;
  
  /// Skill 目录路径
  final String path;
  
  /// 是否为系统 Skill（只读）
  final bool isSystem;
  
  /// 支持文件列表（目录中除 SKILL.md 外的其他文件）
  final List<String> supportingFiles;
  
  /// 文件修改时间
  final DateTime? modifiedAt;
  
  // ============ Frontmatter 配置 ============
  
  /// 上下文设置: inline(默认), fork, none
  final String? context;
  
  /// 是否禁用模型自动调用
  final bool disableModelInvocation;
  
  /// 允许的工具列表
  final List<String>? allowedTools;
  
  /// 禁止的工具列表
  final List<String>? disallowedTools;

  ClaudeSkill({
    required this.name,
    this.description = '',
    required this.content,
    required this.rawContent,
    required this.path,
    this.isSystem = false,
    this.supportingFiles = const [],
    this.modifiedAt,
    this.context,
    this.disableModelInvocation = false,
    this.allowedTools,
    this.disallowedTools,
  });

  /// 从文件系统读取 Skill
  factory ClaudeSkill.fromFile(File skillFile, {required bool isSystem}) {
    final content = skillFile.readAsStringSync();
    final dirPath = skillFile.parent.path;
    final dirName = dirPath.split(Platform.pathSeparator).last;
    
    // 解析 frontmatter 和内容
    final parsed = _parseFrontmatter(content);
    
    // 获取支持文件
    final supportingFiles = <String>[];
    try {
      final dir = skillFile.parent;
      for (final entity in dir.listSync()) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName != 'SKILL.md') {
            supportingFiles.add(fileName);
          }
        }
      }
    } catch (_) {}
    
    // 获取文件修改时间
    DateTime? modifiedAt;
    try {
      modifiedAt = skillFile.lastModifiedSync();
    } catch (_) {}
    
    return ClaudeSkill(
      name: dirName,
      description: parsed['description'] ?? '',
      content: parsed['content'] ?? '',
      rawContent: content,
      path: dirPath,
      isSystem: isSystem,
      supportingFiles: supportingFiles,
      modifiedAt: modifiedAt,
      context: parsed['context'],
      disableModelInvocation: parsed['disableModelInvocation'] == 'true',
      allowedTools: parsed['allowedTools'],
      disallowedTools: parsed['disallowedTools'],
    );
  }

  /// 解析 SKILL.md 的 frontmatter
  static Map<String, dynamic> _parseFrontmatter(String content) {
    final result = <String, dynamic>{};
    String mainContent = content;
    
    // 检查是否有 frontmatter (以 --- 开始)
    if (content.startsWith('---')) {
      final endIndex = content.indexOf('---', 3);
      if (endIndex > 0) {
        final frontmatter = content.substring(3, endIndex).trim();
        mainContent = content.substring(endIndex + 3).trim();
        
        // 解析 YAML 格式的 frontmatter
        for (final line in frontmatter.split('\n')) {
          final colonIndex = line.indexOf(':');
          if (colonIndex > 0) {
            final key = line.substring(0, colonIndex).trim();
            var value = line.substring(colonIndex + 1).trim();
            
            switch (key) {
              case 'description':
                result['description'] = value;
                break;
              case 'context':
                result['context'] = value;
                break;
              case 'disable-model-invocation':
                result['disableModelInvocation'] = value;
                break;
              case 'allowed-tools':
                result['allowedTools'] = _parseArrayValue(value);
                break;
              case 'disallowed-tools':
                result['disallowedTools'] = _parseArrayValue(value);
                break;
            }
          }
        }
      }
    }
    
    result['content'] = mainContent;
    
    // 如果没有描述，从内容的第一行提取
    if (result['description'] == null || (result['description'] as String).isEmpty) {
      final lines = mainContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
          result['description'] = trimmed.length > 100 
              ? '${trimmed.substring(0, 100)}...'
              : trimmed;
          break;
        }
      }
    }
    
    return result;
  }

  /// 解析 YAML 数组值
  static List<String> _parseArrayValue(String value) {
    // 处理 [item1, item2] 格式
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1);
      return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    // 处理单个值
    if (value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  /// 生成 SKILL.md 内容
  String toSkillMd() {
    final buffer = StringBuffer();
    
    // 生成 frontmatter
    final hasFrontmatter = description.isNotEmpty ||
        context != null ||
        disableModelInvocation ||
        (allowedTools != null && allowedTools!.isNotEmpty) ||
        (disallowedTools != null && disallowedTools!.isNotEmpty);
    
    if (hasFrontmatter) {
      buffer.writeln('---');
      if (description.isNotEmpty) {
        buffer.writeln('description: $description');
      }
      if (context != null && context!.isNotEmpty && context != 'inline') {
        buffer.writeln('context: $context');
      }
      if (disableModelInvocation) {
        buffer.writeln('disable-model-invocation: true');
      }
      if (allowedTools != null && allowedTools!.isNotEmpty) {
        buffer.writeln('allowed-tools: [${allowedTools!.join(', ')}]');
      }
      if (disallowedTools != null && disallowedTools!.isNotEmpty) {
        buffer.writeln('disallowed-tools: [${disallowedTools!.join(', ')}]');
      }
      buffer.writeln('---');
      buffer.writeln();
    }
    
    // 添加内容
    buffer.write(content);
    
    return buffer.toString();
  }

  /// 获取 slash 命令名称
  String get slashCommand => '/$name';

  /// 复制并修改
  ClaudeSkill copyWith({
    String? name,
    String? description,
    String? content,
    String? rawContent,
    String? path,
    bool? isSystem,
    List<String>? supportingFiles,
    DateTime? modifiedAt,
    String? context,
    bool? disableModelInvocation,
    List<String>? allowedTools,
    List<String>? disallowedTools,
  }) {
    return ClaudeSkill(
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      rawContent: rawContent ?? this.rawContent,
      path: path ?? this.path,
      isSystem: isSystem ?? this.isSystem,
      supportingFiles: supportingFiles ?? this.supportingFiles,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      context: context ?? this.context,
      disableModelInvocation: disableModelInvocation ?? this.disableModelInvocation,
      allowedTools: allowedTools ?? this.allowedTools,
      disallowedTools: disallowedTools ?? this.disallowedTools,
    );
  }

  @override
  String toString() => 'ClaudeSkill($name, isSystem: $isSystem)';
}
