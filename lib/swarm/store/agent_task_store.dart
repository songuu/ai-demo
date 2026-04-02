import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/swarm/model/agent_task.dart';

/// Store for persisting AgentTask objects.
class AgentTaskStore {
  AgentTaskStore._();

  static const _boxName = 'swarm_agent_tasks';
  static Box<AgentTask>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<AgentTask>(_boxName);
  }

  static Box<AgentTask> get box {
    if (_box == null) {
      throw StateError('AgentTaskStore not initialized. Call init() first.');
    }
    return _box!;
  }

  static List<AgentTask> all() {
    final tasks = box.values.toList();
    tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return tasks;
  }

  static AgentTask? byId(String id) => box.get(id);

  static Future<void> put(AgentTask task) async {
    await box.put(task.id, task);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static ValueListenable<Box<AgentTask>> listenable() => box.listenable();
}
