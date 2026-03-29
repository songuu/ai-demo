import 'package:hive_flutter/hive_flutter.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 16)
class ChatModel extends HiveObject {
  ChatModel({
    required this.id,
    required this.providerId,
    required this.name,
    this.maxTokens = 4096,
    this.supportsVision = false,
    this.supportsTools = false,
    this.supportsStreaming = true,
    this.sortOrder = 0,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String providerId;

  @HiveField(2)
  String name;

  @HiveField(3)
  int maxTokens;

  @HiveField(4)
  bool supportsVision;

  @HiveField(5)
  bool supportsTools;

  @HiveField(6)
  bool supportsStreaming;

  @HiveField(7)
  int sortOrder;
}
