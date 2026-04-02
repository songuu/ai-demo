import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/swarm/model/swarm_session.dart';

/// Store for persisting SwarmSession objects.
class SwarmSessionStore {
  SwarmSessionStore._();

  static const _boxName = 'swarm_sessions';
  static Box<SwarmSession>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<SwarmSession>(_boxName);
  }

  static Box<SwarmSession> get box {
    if (_box == null) {
      throw StateError(
        'SwarmSessionStore not initialized. Call init() first.',
      );
    }
    return _box!;
  }

  static List<SwarmSession> all() {
    final sessions = box.values.toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  static SwarmSession? byId(String id) => box.get(id);

  static List<SwarmSession> byTaskId(String taskId) {
    return box.values.where((s) => s.taskId == taskId).toList();
  }

  static List<SwarmSession> running() {
    return box.values
        .where((s) => s.status == SwarmSessionStatus.running)
        .toList();
  }

  static Future<void> put(SwarmSession session) async {
    await box.put(session.id, session);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static ValueListenable<Box<SwarmSession>> listenable() => box.listenable();
}
