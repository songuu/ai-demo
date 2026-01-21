import 'package:hive/hive.dart';

part 'cod_provider_config.g.dart';

/// CLI 提供商配置
@HiveType(typeId: 11)
class CodProviderConfig extends HiveObject {
  /// 提供商名称 (claude, codex, gemini)
  @HiveField(0)
  String provider;

  /// 显示名称
  @HiveField(1)
  String displayName;

  /// 是否启用
  @HiveField(2)
  bool enabled;

  /// CLI 命令名称或路径
  @HiveField(3)
  String command;

  /// API 密钥
  @HiveField(4)
  String? apiKey;

  /// 环境变量
  @HiveField(5)
  Map<String, String> environmentVariables;

  /// 默认参数
  @HiveField(6)
  List<String> defaultArgs;

  /// 工作目录模板 (null = 使用当前目录)
  @HiveField(7)
  String? workingDirectoryTemplate;

  /// 历史文件路径模板
  @HiveField(8)
  String? historyPathTemplate;

  /// 自动导入历史
  @HiveField(9)
  bool autoImportHistory;

  /// 最大并发会话数
  @HiveField(10)
  int maxConcurrentSessions;

  /// 超时时间（秒）
  @HiveField(11)
  int timeoutSeconds;

  /// 是否使用 shell 运行
  @HiveField(12)
  bool runInShell;

  /// 额外配置（JSON）
  @HiveField(13)
  Map<String, dynamic> extraConfig;

  /// 创建时间
  @HiveField(14)
  DateTime createdAt;

  /// 更新时间
  @HiveField(15)
  DateTime updatedAt;

  CodProviderConfig({
    required this.provider,
    required this.displayName,
    this.enabled = true,
    required this.command,
    this.apiKey,
    Map<String, String>? environmentVariables,
    List<String>? defaultArgs,
    this.workingDirectoryTemplate,
    this.historyPathTemplate,
    this.autoImportHistory = true,
    this.maxConcurrentSessions = 5,
    this.timeoutSeconds = 3600,
    this.runInShell = true,
    Map<String, dynamic>? extraConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : environmentVariables = environmentVariables ?? {},
        defaultArgs = defaultArgs ?? [],
        extraConfig = extraConfig ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 获取完整的环境变量（包含 API 密钥）
  Map<String, String> getFullEnvironment() {
    final env = Map<String, String>.from(environmentVariables);
    
    if (apiKey != null && apiKey!.isNotEmpty) {
      switch (provider.toLowerCase()) {
        case 'claude':
          env['ANTHROPIC_API_KEY'] = apiKey!;
          break;
        case 'codex':
          env['OPENAI_API_KEY'] = apiKey!;
          break;
        case 'gemini':
          env['GOOGLE_API_KEY'] = apiKey!;
          break;
      }
    }
    
    return env;
  }

  /// 复制并更新
  CodProviderConfig copyWith({
    String? provider,
    String? displayName,
    bool? enabled,
    String? command,
    String? apiKey,
    Map<String, String>? environmentVariables,
    List<String>? defaultArgs,
    String? workingDirectoryTemplate,
    String? historyPathTemplate,
    bool? autoImportHistory,
    int? maxConcurrentSessions,
    int? timeoutSeconds,
    bool? runInShell,
    Map<String, dynamic>? extraConfig,
  }) {
    return CodProviderConfig(
      provider: provider ?? this.provider,
      displayName: displayName ?? this.displayName,
      enabled: enabled ?? this.enabled,
      command: command ?? this.command,
      apiKey: apiKey ?? this.apiKey,
      environmentVariables: environmentVariables ?? this.environmentVariables,
      defaultArgs: defaultArgs ?? this.defaultArgs,
      workingDirectoryTemplate: workingDirectoryTemplate ?? this.workingDirectoryTemplate,
      historyPathTemplate: historyPathTemplate ?? this.historyPathTemplate,
      autoImportHistory: autoImportHistory ?? this.autoImportHistory,
      maxConcurrentSessions: maxConcurrentSessions ?? this.maxConcurrentSessions,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      runInShell: runInShell ?? this.runInShell,
      extraConfig: extraConfig ?? this.extraConfig,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'displayName': displayName,
      'enabled': enabled,
      'command': command,
      'apiKey': apiKey,
      'environmentVariables': environmentVariables,
      'defaultArgs': defaultArgs,
      'workingDirectoryTemplate': workingDirectoryTemplate,
      'historyPathTemplate': historyPathTemplate,
      'autoImportHistory': autoImportHistory,
      'maxConcurrentSessions': maxConcurrentSessions,
      'timeoutSeconds': timeoutSeconds,
      'runInShell': runInShell,
      'extraConfig': extraConfig,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从 JSON 创建
  factory CodProviderConfig.fromJson(Map<String, dynamic> json) {
    return CodProviderConfig(
      provider: json['provider'] as String,
      displayName: json['displayName'] as String,
      enabled: json['enabled'] as bool? ?? true,
      command: json['command'] as String,
      apiKey: json['apiKey'] as String?,
      environmentVariables: Map<String, String>.from(json['environmentVariables'] ?? {}),
      defaultArgs: List<String>.from(json['defaultArgs'] ?? []),
      workingDirectoryTemplate: json['workingDirectoryTemplate'] as String?,
      historyPathTemplate: json['historyPathTemplate'] as String?,
      autoImportHistory: json['autoImportHistory'] as bool? ?? true,
      maxConcurrentSessions: json['maxConcurrentSessions'] as int? ?? 5,
      timeoutSeconds: json['timeoutSeconds'] as int? ?? 3600,
      runInShell: json['runInShell'] as bool? ?? true,
      extraConfig: Map<String, dynamic>.from(json['extraConfig'] ?? {}),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// 默认配置：Claude Code
  static CodProviderConfig defaultClaude() {
    return CodProviderConfig(
      provider: 'claude',
      displayName: 'Claude Code',
      command: 'claude',
      historyPathTemplate: r'${HOME}\.claude\projects',
      defaultArgs: [],
      environmentVariables: {},
      extraConfig: {
        'resumeCommand': '--continue',
        'chatCommand': '',
      },
    );
  }

  /// 默认配置：Codex CLI
  static CodProviderConfig defaultCodex() {
    return CodProviderConfig(
      provider: 'codex',
      displayName: 'Codex CLI',
      command: 'codex',
      historyPathTemplate: r'${HOME}\.codex\history.jsonl',
      defaultArgs: [],
      environmentVariables: {},
    );
  }

  /// 默认配置：Gemini CLI
  static CodProviderConfig defaultGemini() {
    return CodProviderConfig(
      provider: 'gemini',
      displayName: 'Gemini CLI',
      command: 'gemini',
      historyPathTemplate: r'${HOME}\.gemini\sessions',
      defaultArgs: [],
      environmentVariables: {},
    );
  }

  @override
  String toString() {
    return 'CodProviderConfig(provider: $provider, displayName: $displayName, '
        'enabled: $enabled, command: $command, hasApiKey: ${apiKey?.isNotEmpty ?? false})';
  }
}
