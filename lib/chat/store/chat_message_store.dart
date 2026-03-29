import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_message.dart';

class ChatMessageStore {
  ChatMessageStore._();

  static const _boxName = 'chat_messages';
  static Box<ChatMessage>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<ChatMessage>(_boxName);
  }

  static List<ChatMessage> forConversation(String conversationId) {
    final list = _box?.values
            .where((m) => m.conversationId == conversationId)
            .toList() ??
        <ChatMessage>[];
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  static Future<void> put(ChatMessage message) async {
    await _box?.put(message.id, message);
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
  }

  static Future<void> removeAllForConversation(String conversationId) async {
    final keys = _box?.keys.where((key) {
      final msg = _box?.get(key);
      return msg?.conversationId == conversationId;
    }).toList();
    if (keys != null && keys.isNotEmpty) {
      await _box?.deleteAll(keys);
    }
  }

  static ChatMessage? byId(String id) => _box?.get(id);

  static ChatMessage? lastMessage(String conversationId) {
    final messages = forConversation(conversationId);
    return messages.isNotEmpty ? messages.last : null;
  }

  static Future<void> updateContent(
    String id,
    String content,
    List<Map<String, dynamic>> blocks,
  ) async {
    final msg = _box?.get(id);
    if (msg != null) {
      msg.content = content;
      msg.blocks = blocks;
      await msg.save();
    }
  }

  static ValueListenable<Box<ChatMessage>>? listenable() {
    return _box?.listenable();
  }
}
