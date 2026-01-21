import 'package:hive/hive.dart';

part 'cod_skill.g.dart';

/// Skill 类型
@HiveType(typeId: 12)
enum CodSkillType {
  /// 系统提示词
  @HiveField(0)
  systemPrompt,

  /// 代码模板
  @HiveField(1)
  codeTemplate,

  /// 工作流
  @HiveField(2)
  workflow,

  /// 自定义命令
  @HiveField(3)
  customCommand,

  /// 提示词片段
  @HiveField(4)
  promptSnippet,
}

/// Skill 适用的提供商
@HiveType(typeId: 13)
enum CodSkillProvider {
  @HiveField(0)
  all,

  @HiveField(1)
  claude,

  @HiveField(2)
  codex,

  @HiveField(3)
  gemini,
}

/// AI Code Skill 模型
/// 用于管理 Claude Code, Codex, Gemini 的技能/提示词模板
@HiveType(typeId: 14)
class CodSkill extends HiveObject {
  /// 唯一标识符
  @HiveField(0)
  String id;

  /// 技能名称
  @HiveField(1)
  String name;

  /// 技能描述
  @HiveField(2)
  String description;

  /// 技能内容（提示词/命令/模板）
  @HiveField(3)
  String content;

  /// 技能类型
  @HiveField(4)
  CodSkillType type;

  /// 适用的提供商
  @HiveField(5)
  CodSkillProvider provider;

  /// 标签列表
  @HiveField(6)
  List<String> tags;

  /// 是否收藏
  @HiveField(7)
  bool isFavorite;

  /// 是否启用
  @HiveField(8)
  bool isEnabled;

  /// 使用次数
  @HiveField(9)
  int useCount;

  /// 创建时间
  @HiveField(10)
  DateTime createdAt;

  /// 更新时间
  @HiveField(11)
  DateTime updatedAt;

  /// 最后使用时间
  @HiveField(12)
  DateTime? lastUsedAt;

  /// 同步 ID（用于云同步）
  @HiveField(13)
  String? syncId;

  /// 同步状态: 0-未同步, 1-已同步, 2-待同步, 3-冲突
  @HiveField(14)
  int syncStatus;

  /// 额外元数据
  @HiveField(15)
  Map<String, dynamic> metadata;

  /// 快捷键
  @HiveField(16)
  String? shortcut;

  /// 变量列表（用于模板替换）
  @HiveField(17)
  List<String> variables;

  CodSkill({
    required this.id,
    required this.name,
    this.description = '',
    required this.content,
    this.type = CodSkillType.systemPrompt,
    this.provider = CodSkillProvider.all,
    List<String>? tags,
    this.isFavorite = false,
    this.isEnabled = true,
    this.useCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastUsedAt,
    this.syncId,
    this.syncStatus = 0,
    Map<String, dynamic>? metadata,
    this.shortcut,
    List<String>? variables,
  })  : tags = tags ?? [],
        metadata = metadata ?? {},
        variables = variables ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 生成新 ID
  static String generateId() {
    return 'skill_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// 复制
  CodSkill copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    CodSkillType? type,
    CodSkillProvider? provider,
    List<String>? tags,
    bool? isFavorite,
    bool? isEnabled,
    int? useCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    String? syncId,
    int? syncStatus,
    Map<String, dynamic>? metadata,
    String? shortcut,
    List<String>? variables,
  }) {
    return CodSkill(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      content: content ?? this.content,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      tags: tags ?? List.from(this.tags),
      isFavorite: isFavorite ?? this.isFavorite,
      isEnabled: isEnabled ?? this.isEnabled,
      useCount: useCount ?? this.useCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      syncId: syncId ?? this.syncId,
      syncStatus: syncStatus ?? this.syncStatus,
      metadata: metadata ?? Map.from(this.metadata),
      shortcut: shortcut ?? this.shortcut,
      variables: variables ?? List.from(this.variables),
    );
  }

  /// 标记使用
  void markUsed() {
    useCount++;
    lastUsedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'content': content,
      'type': type.index,
      'provider': provider.index,
      'tags': tags,
      'isFavorite': isFavorite,
      'isEnabled': isEnabled,
      'useCount': useCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'syncId': syncId,
      'syncStatus': syncStatus,
      'metadata': metadata,
      'shortcut': shortcut,
      'variables': variables,
    };
  }

  /// 从 JSON 创建
  factory CodSkill.fromJson(Map<String, dynamic> json) {
    return CodSkill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      content: json['content'] as String,
      type: CodSkillType.values[json['type'] as int? ?? 0],
      provider: CodSkillProvider.values[json['provider'] as int? ?? 0],
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      useCount: json['useCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      syncId: json['syncId'] as String?,
      syncStatus: json['syncStatus'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      shortcut: json['shortcut'] as String?,
      variables: List<String>.from(json['variables'] ?? []),
    );
  }

  /// 获取类型显示名称
  String get typeDisplayName {
    switch (type) {
      case CodSkillType.systemPrompt:
        return '系统提示词';
      case CodSkillType.codeTemplate:
        return '代码模板';
      case CodSkillType.workflow:
        return '工作流';
      case CodSkillType.customCommand:
        return '自定义命令';
      case CodSkillType.promptSnippet:
        return '提示词片段';
    }
  }

  /// 获取提供商显示名称
  String get providerDisplayName {
    switch (provider) {
      case CodSkillProvider.all:
        return '全部';
      case CodSkillProvider.claude:
        return 'Claude';
      case CodSkillProvider.codex:
        return 'Codex';
      case CodSkillProvider.gemini:
        return 'Gemini';
    }
  }

  /// 获取同步状态显示名称
  String get syncStatusDisplayName {
    switch (syncStatus) {
      case 0:
        return '未同步';
      case 1:
        return '已同步';
      case 2:
        return '待同步';
      case 3:
        return '有冲突';
      default:
        return '未知';
    }
  }

  @override
  String toString() {
    return 'CodSkill(id: $id, name: $name, type: $typeDisplayName, provider: $providerDisplayName)';
  }

  /// 预设 Skills
  static List<CodSkill> getPresetSkills() {
    return [
      CodSkill(
        id: 'preset_code_review',
        name: '代码审查',
        description: '审查代码质量、安全性和最佳实践',
        content: '''请审查以下代码，关注：
1. 代码质量和可读性
2. 潜在的bug和安全问题
3. 性能优化建议
4. 是否遵循最佳实践
5. 测试覆盖建议

请提供具体的改进建议和代码示例。''',
        type: CodSkillType.systemPrompt,
        provider: CodSkillProvider.all,
        tags: ['代码审查', '质量', '安全'],
      ),
      CodSkill(
        id: 'preset_refactor',
        name: '代码重构',
        description: '帮助重构代码以提高可维护性',
        content: '''请帮助重构以下代码：
1. 提取可复用的函数和组件
2. 减少代码重复
3. 改善命名和结构
4. 添加适当的注释
5. 遵循 SOLID 原则

请解释每个重构步骤的原因。''',
        type: CodSkillType.systemPrompt,
        provider: CodSkillProvider.all,
        tags: ['重构', '优化', '架构'],
      ),
      CodSkill(
        id: 'preset_test_gen',
        name: '测试生成',
        description: '为代码生成单元测试',
        content: '''请为以下代码生成全面的单元测试：
1. 覆盖正常情况
2. 边界条件测试
3. 异常情况处理
4. Mock 外部依赖
5. 使用 AAA 模式（Arrange-Act-Assert）

使用项目现有的测试框架。''',
        type: CodSkillType.systemPrompt,
        provider: CodSkillProvider.all,
        tags: ['测试', '单元测试', 'TDD'],
      ),
      CodSkill(
        id: 'preset_doc_gen',
        name: '文档生成',
        description: '为代码生成文档和注释',
        content: '''请为以下代码生成文档：
1. 函数/方法的 JSDoc/Dartdoc 注释
2. 参数和返回值说明
3. 使用示例
4. 注意事项和限制
5. README 文档更新建议''',
        type: CodSkillType.systemPrompt,
        provider: CodSkillProvider.all,
        tags: ['文档', '注释', 'README'],
      ),
      CodSkill(
        id: 'preset_debug',
        name: '调试助手',
        description: '帮助分析和解决代码问题',
        content: '''请帮助分析以下问题：
1. 仔细阅读错误信息和堆栈
2. 分析可能的原因
3. 提供诊断步骤
4. 给出解决方案
5. 预防类似问题的建议

请一步步分析问题。''',
        type: CodSkillType.systemPrompt,
        provider: CodSkillProvider.all,
        tags: ['调试', '错误分析', '问题解决'],
      ),
      CodSkill(
        id: 'preset_flutter_widget',
        name: 'Flutter Widget',
        description: 'Flutter Widget 开发模板',
        content: '''请帮助创建一个 Flutter Widget：
- 使用 StatelessWidget 或 StatefulWidget
- 支持主题适配
- 响应式设计
- 良好的性能
- 完整的参数注释

Widget 需求：{{WIDGET_DESCRIPTION}}''',
        type: CodSkillType.codeTemplate,
        provider: CodSkillProvider.all,
        tags: ['Flutter', 'Widget', 'UI'],
        variables: ['WIDGET_DESCRIPTION'],
      ),
    ];
  }
}
