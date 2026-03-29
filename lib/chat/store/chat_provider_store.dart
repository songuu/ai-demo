import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/chat/model/chat_provider.dart';

class ChatProviderStore {
  ChatProviderStore._();

  static const _boxName = 'chat_providers';
  static Box<ChatProvider>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<ChatProvider>(_boxName);
    if (_box!.isEmpty) {
      await _seedDefaults();
    }
  }

  static Future<void> _seedDefaults() async {
    final defaults = [
      ChatProvider.defaultOpenAI(),
      ChatProvider.defaultAnthropic(),
      ChatProvider.defaultGoogle(),
      ChatProvider.defaultOpenRouter(),
    ];
    for (final p in defaults) {
      await _box?.put(p.id, p);
    }
  }

  static List<ChatProvider> all() {
    final list = _box?.values.toList() ?? <ChatProvider>[];
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static List<ChatProvider> enabled() {
    return all().where((p) => p.enabled).toList();
  }

  static ChatProvider? byId(String id) => _box?.get(id);

  static Future<void> put(ChatProvider provider) async {
    provider.updatedAt = DateTime.now();
    await _box?.put(provider.id, provider);
  }

  static Future<void> remove(String id) async {
    await _box?.delete(id);
  }

  static ValueListenable<Box<ChatProvider>>? listenable() {
    return _box?.listenable();
  }
}
