import 'package:hive_flutter/hive_flutter.dart';

part 'chat_provider.g.dart';

@HiveType(typeId: 15)
class ChatProvider extends HiveObject {
  ChatProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.apiHost,
    this.apiKey = '',
    this.enabled = true,
    this.models = const [],
    this.extraHeaders = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sortOrder = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// openai | anthropic | google | openrouter | openclaw | custom
  @HiveField(2)
  String type;

  /// Base URL, e.g. "https://api.openai.com/v1"
  @HiveField(3)
  String apiHost;

  @HiveField(4)
  String apiKey;

  @HiveField(5)
  bool enabled;

  /// Cached model ID list
  @HiveField(6)
  List<String> models;

  @HiveField(7)
  Map<String, String> extraHeaders;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  int sortOrder;

  ChatProvider copyWith({
    String? name,
    String? type,
    String? apiHost,
    String? apiKey,
    bool? enabled,
    List<String>? models,
    Map<String, String>? extraHeaders,
    int? sortOrder,
  }) {
    return ChatProvider(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      apiHost: apiHost ?? this.apiHost,
      apiKey: apiKey ?? this.apiKey,
      enabled: enabled ?? this.enabled,
      models: models ?? this.models,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  static ChatProvider defaultOpenAI() => ChatProvider(
        id: 'openai',
        name: 'OpenAI',
        type: 'openai',
        apiHost: 'https://api.openai.com/v1',
        models: ['gpt-4o', 'gpt-4o-mini', 'o3-mini'],
      );

  static ChatProvider defaultAnthropic() => ChatProvider(
        id: 'anthropic',
        name: 'Anthropic',
        type: 'anthropic',
        apiHost: 'https://api.anthropic.com',
        models: [
          'claude-sonnet-4-5-20250929',
          'claude-sonnet-4-6',
          'claude-3-5-haiku-20241022',
        ],
      );

  static ChatProvider defaultGoogle() => ChatProvider(
        id: 'google',
        name: 'Google',
        type: 'google',
        apiHost: 'https://generativelanguage.googleapis.com',
        models: ['gemini-2.0-flash', 'gemini-2.5-pro'],
      );

  static ChatProvider defaultOpenRouter() => ChatProvider(
        id: 'openrouter',
        name: 'OpenRouter',
        type: 'openai',
        apiHost: 'https://openrouter.ai/api/v1',
        models: [],
      );
}
