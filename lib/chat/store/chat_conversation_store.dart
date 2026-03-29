import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_conversation.dart';
import 'package:server_box/chat/store/chat_message_store.dart';

class ChatConversationStore {
  ChatConversationStore._();

  static const _boxName = 'chat_conversations';
  static Box<ChatConversation>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<ChatConversation>(_boxName);
  }

  static List<ChatConversation> all() {
    final list = _box?.values.toList() ?? <ChatConversation>[];
    // Pinned first, then sorted by updatedAt desc
    list.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  static ChatConversation create({
    String? title,
    String? modelId,
    String? providerId,
    String? systemPrompt,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final conversation = ChatConversation(
      id: id,
      title: title ?? 'New Chat',
      modelId: modelId,
      providerId: providerId,
      systemPrompt: systemPrompt,
    );
    _box?.put(conversation.id, conversation);
    return conversation;
  }

  static Future<void> put(ChatConversation conversation) async {
    conversation.updatedAt = DateTime.now();
    await _box?.put(conversation.id, conversation);
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
    await ChatMessageStore.removeAllForConversation(id);
  }

  static ChatConversation? byId(String id) => _box?.get(id);

  static List<ChatConversation> search(String query) {
    final q = query.toLowerCase();
    return all()
        .where((c) =>
            c.title.toLowerCase().contains(q) ||
            (c.lastMessagePreview?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  static List<ChatConversation> pinned() {
    return all().where((c) => c.isPinned).toList();
  }

  static ValueListenable<Box<ChatConversation>>? listenable() {
    return _box?.listenable();
  }
}
