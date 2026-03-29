import 'package:hive_flutter/hive_flutter.dart';

part 'chat_message.g.dart';

/// Message status constants
class ChatMessageStatus {
  static const int complete = 0;
  static const int streaming = 1;
  static const int error = 2;
  static const int cancelled = 3;
}

/// Block type constants
class ChatBlockType {
  static const String text = 'text';
  static const String code = 'code';
  static const String thinking = 'thinking';
  static const String image = 'image';
  static const String toolUse = 'tool_use';
  static const String toolResult = 'tool_result';
  static const String citation = 'citation';
  static const String error = 'error';
}

@HiveType(typeId: 18)
class ChatMessage extends HiveObject {
  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    this.content = '',
    this.blocks = const [],
    this.modelId,
    this.parentId,
    this.tokenCount = 0,
    DateTime? createdAt,
    this.status = 0,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId;

  /// user | assistant | system | tool
  @HiveField(2)
  String role;

  /// Plain text content (fast path for simple messages)
  @HiveField(3)
  String content;

  /// Structured content blocks as List<Map<String, dynamic>>
  @HiveField(4)
  List<Map<String, dynamic>> blocks;

  @HiveField(5)
  String? modelId;

  /// For edit/regenerate branching
  @HiveField(6)
  String? parentId;

  @HiveField(7)
  int tokenCount;

  @HiveField(8)
  DateTime createdAt;

  /// 0=complete, 1=streaming, 2=error, 3=cancelled
  @HiveField(9)
  int status;

  @HiveField(10)
  Map<String, dynamic>? metadata;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
  bool get isStreaming => status == ChatMessageStatus.streaming;
  bool get isError => status == ChatMessageStatus.error;

  /// Get display content — from blocks if available, else plain content
  String get displayContent {
    if (blocks.isNotEmpty) {
      return blocks
          .where((b) =>
              b['type'] == ChatBlockType.text ||
              b['type'] == ChatBlockType.code)
          .map((b) => b['content'] as String? ?? '')
          .join('\n');
    }
    return content;
  }

  ChatMessage copyWith({
    String? content,
    List<Map<String, dynamic>>? blocks,
    int? status,
    int? tokenCount,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      blocks: blocks ?? this.blocks,
      modelId: modelId,
      parentId: parentId,
      tokenCount: tokenCount ?? this.tokenCount,
      createdAt: createdAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}
