import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:server_box/swarm/model/worktree.dart';

/// Store for persisting Worktree objects.
class WorktreeStore {
  WorktreeStore._();

  static const _boxName = 'swarm_worktrees';
  static Box<Worktree>? _box;

  static Future<void> init() async {
    _box ??= await Hive.openBox<Worktree>(_boxName);
  }

  static Box<Worktree> get box {
    if (_box == null) {
      throw StateError('WorktreeStore not initialized. Call init() first.');
    }
    return _box!;
  }

  static List<Worktree> forSession(String sessionId) {
    return box.values.where((wt) => wt.sessionId == sessionId).toList();
  }

  static Future<void> put(Worktree wt) async {
    await box.put(wt.id, wt);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static Future<void> removeForSession(String sessionId) async {
    final toRemove = forSession(sessionId).map((wt) => wt.id).toList();
    await box.deleteAll(toRemove);
  }

  static Worktree? byId(String id) => box.get(id);

  static ValueListenable<Box<Worktree> > listenable() => box.listenable();
}
