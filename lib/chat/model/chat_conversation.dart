import 'package:hive_flutter/hive_flutter.dart';

part 'chat_conversation.g.dart';

@HiveType(typeId: 17)
class ChatConversation extends HiveObject {
  ChatConversation({
    required this.id,
    this.title = 'New Chat',
    this.modelId,
    this.providerId,
    this.systemPrompt,
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.isPinned = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.webSearchEnabled = false,
    this.mcpServerIds = const [],
    this.messageCount = 0,
    this.lastMessagePreview,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? modelId;

  @HiveField(3)
  String? providerId;

  @HiveField(4)
  String? systemPrompt;

  @HiveField(5)
  double temperature;

  @HiveField(6)
  int maxTokens;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  bool isArchived;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  bool webSearchEnabled;

  @HiveField(12)
  List<String> mcpServerIds;

  @HiveField(13)
  int messageCount;

  @HiveField(14)
  String? lastMessagePreview;

  ChatConversation copyWith({
    String? title,
    String? modelId,
    String? providerId,
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    bool? isPinned,
    bool? isArchived,
    bool? webSearchEnabled,
    List<String>? mcpServerIds,
    int? messageCount,
    String? lastMessagePreview,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      modelId: modelId ?? this.modelId,
      providerId: providerId ?? this.providerId,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      webSearchEnabled: webSearchEnabled ?? this.webSearchEnabled,
      mcpServerIds: mcpServerIds ?? this.mcpServerIds,
      messageCount: messageCount ?? this.messageCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }
}
