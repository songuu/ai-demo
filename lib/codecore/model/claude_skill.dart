import 'dart:io';

/// Claude Code Skill 数据模型
/// 参考: https://code.claude.com/docs/en/skills
class ClaudeSkill {
  /// Skill 名称（目录名，也是 slash command 名称）
  final String name;
  
  /// Skill 描述（从 frontmatter 提取）
  final String description;
  
  /// Skill 内容（SKILL.md 的主体部分，不含 frontmatter）
  final String content;
  
  /// SKILL.md 的原始完整内容
  final String rawContent;
  
  /// Skill 目录路径
  final String path;
  
  /// 是否为系统 Skill（只读）
  final bool isSystem;
  
  /// 支持文件列表（包括子目录）
  final List<SkillFile> supportingFiles;
  
  /// 文件修改时间
  final DateTime? modifiedAt;
  
  // ============ Frontmatter 配置 ============
  
  /// 上下文设置: inline(默认), fork, none
  /// - inline: Skill 内容直接添加到当前会话上下文
  /// - fork: 在子代理中运行
  /// - none: 不添加上下文
  final String? context;
  
  /// 是否禁用模型自动调用
  /// true: 仅通过 /command 手动触发
  /// false: Claude 可根据描述自动调用
  final bool disableModelInvocation;
  
  /// 允许的工具列表
  final List<String>? allowedTools;
  
  /// 禁止的工具列表
  final List<String>? disallowedTools;
  
  /// 代理类型（用于 fork 上下文）
  final String? agent;
  
  /// 是否允许多轮对话
  final bool? allowMultipleTurns;

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
    this.agent,
    this.allowMultipleTurns,
  });

  /// 从文件系统读取 Skill
  factory ClaudeSkill.fromFile(File skillFile, {required bool isSystem}) {
    final content = skillFile.readAsStringSync();
    final dirPath = skillFile.parent.path;
    final dirName = dirPath.split(Platform.pathSeparator).last;
    
    // 解析 frontmatter 和内容
    final parsed = _parseFrontmatter(content);
    
    // 获取支持文件（包括子目录）
    final supportingFiles = _scanSupportingFiles(skillFile.parent);
    
    // 获取文件修改时间
    DateTime? modifiedAt;
    try {
      modifiedAt = skillFile.lastModifiedSync();
    } catch (_) {}
    
    return ClaudeSkill(
      name: parsed['name'] ?? dirName,
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
      agent: parsed['agent'],
      allowMultipleTurns: parsed['allowMultipleTurns'] == 'true' ? true : 
                         parsed['allowMultipleTurns'] == 'false' ? false : null,
    );
  }

  /// 扫描支持文件（包括子目录）
  static List<SkillFile> _scanSupportingFiles(Directory dir) {
    final files = <SkillFile>[];
    
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          final relativePath = entity.path.substring(dir.path.length + 1)
              .replaceAll(Platform.pathSeparator, '/');
          
          // 跳过 SKILL.md
          if (relativePath == 'SKILL.md') continue;
          
          // 确定文件类型
          SkillFileType fileType;
          if (relativePath.startsWith('scripts/')) {
            fileType = SkillFileType.script;
          } else if (relativePath.startsWith('examples/')) {
            fileType = SkillFileType.example;
          } else if (relativePath.endsWith('.md')) {
            fileType = SkillFileType.template;
          } else {
            fileType = SkillFileType.other;
          }
          
          files.add(SkillFile(
            name: relativePath.split('/').last,
            relativePath: relativePath,
            absolutePath: entity.path,
            type: fileType,
          ));
        }
      }
    } catch (_) {}
    
    // 按类型和名称排序
    files.sort((a, b) {
      if (a.type != b.type) {
        return a.type.index.compareTo(b.type.index);
      }
      return a.relativePath.compareTo(b.relativePath);
    });
    
    return files;
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
              case 'name':
                result['name'] = value;
                break;
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
              case 'agent':
                result['agent'] = value;
                break;
              case 'allow-multiple-turns':
                result['allowMultipleTurns'] = value;
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
        (disallowedTools != null && disallowedTools!.isNotEmpty) ||
        agent != null ||
        allowMultipleTurns != null;
    
    if (hasFrontmatter) {
      buffer.writeln('---');
      buffer.writeln('name: $name');
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
      if (agent != null && agent!.isNotEmpty) {
        buffer.writeln('agent: $agent');
      }
      if (allowMultipleTurns != null) {
        buffer.writeln('allow-multiple-turns: $allowMultipleTurns');
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
  
  /// 获取 scripts 文件列表
  List<SkillFile> get scripts => 
      supportingFiles.where((f) => f.type == SkillFileType.script).toList();
  
  /// 获取 examples 文件列表
  List<SkillFile> get examples => 
      supportingFiles.where((f) => f.type == SkillFileType.example).toList();
  
  /// 获取 template 文件列表
  List<SkillFile> get templates => 
      supportingFiles.where((f) => f.type == SkillFileType.template).toList();

  /// 复制并修改
  ClaudeSkill copyWith({
    String? name,
    String? description,
    String? content,
    String? rawContent,
    String? path,
    bool? isSystem,
    List<SkillFile>? supportingFiles,
    DateTime? modifiedAt,
    String? context,
    bool? disableModelInvocation,
    List<String>? allowedTools,
    List<String>? disallowedTools,
    String? agent,
    bool? allowMultipleTurns,
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
      agent: agent ?? this.agent,
      allowMultipleTurns: allowMultipleTurns ?? this.allowMultipleTurns,
    );
  }

  @override
  String toString() => 'ClaudeSkill($name, isSystem: $isSystem)';
}

/// Skill 支持文件类型
enum SkillFileType {
  /// 脚本文件（scripts/ 目录）
  script,
  /// 示例文件（examples/ 目录）
  example,
  /// 模板文件（*.md，如 template.md）
  template,
  /// 其他文件
  other,
}

/// Skill 支持文件
class SkillFile {
  /// 文件名
  final String name;
  
  /// 相对于 skill 目录的路径
  final String relativePath;
  
  /// 绝对路径
  final String absolutePath;
  
  /// 文件类型
  final SkillFileType type;

  SkillFile({
    required this.name,
    required this.relativePath,
    required this.absolutePath,
    required this.type,
  });
  
  /// 获取文件内容
  Future<String> readContent() async {
    final file = File(absolutePath);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('File not found: $absolutePath');
  }
  
  /// 获取文件图标
  String get icon {
    switch (type) {
      case SkillFileType.script:
        return '📜';
      case SkillFileType.example:
        return '📝';
      case SkillFileType.template:
        return '📄';
      case SkillFileType.other:
        return '📎';
    }
  }
  
  /// 获取文件类型描述
  String get typeDescription {
    switch (type) {
      case SkillFileType.script:
        return '脚本';
      case SkillFileType.example:
        return '示例';
      case SkillFileType.template:
        return '模板';
      case SkillFileType.other:
        return '其他';
    }
  }
}

/// 新建 Skill 时的文件项
class NewSkillFile {
  String relativePath;
  String content;
  SkillFileType type;
  
  NewSkillFile({
    required this.relativePath,
    required this.content,
    required this.type,
  });
  
  String get name => relativePath.split('/').last;
}
