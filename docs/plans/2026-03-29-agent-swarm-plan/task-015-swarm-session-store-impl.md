# Task 015: SwarmSessionStore Implementation

**depends-on**: task-014

## Description

实现 SwarmSessionStore 持久化层，复用 CodSessionStore 的模式。

## Execution Context

**Task Number**: 15 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 014 模型已完成

## Files to Modify/Create

- Create: `lib/swarm/store/swarm_session_store.dart`

## Steps

### Step 1: Create SwarmSessionStore
创建 `lib/swarm/store/swarm_session_store.dart`（完全复用 CodSessionStore 模式）：

```dart
class SwarmSessionStore {
  static const _boxName = 'swarm_sessions';
  static Box<SwarmSession>? _box;

  static Future<void> init() async {
    _box = await Hive.openBox<SwarmSession>(_boxName);
  }

  static Box<SwarmSession> get box => _box!;

  static List<SwarmSession> all() {
    return box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  static Future<SwarmSession> create({
    required String title,
    required String rootPath,
    String defaultBranch = 'main',
  }) async {
    final now = DateTime.now();
    final id = '${now.millisecondsSinceEpoch}';
    final session = SwarmSession(
      id: id,
      title: title,
      rootPath: rootPath,
      defaultBranch: defaultBranch,
      agentIds: [],
      createdAt: now,
      updatedAt: now,
      status: SwarmSessionStatus.idle,
    );
    await box.put(id, session);
    return session;
  }

  static Future<void> put(SwarmSession session) async {
    session.updatedAt = DateTime.now();
    await box.put(session.id, session);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static SwarmSession? byId(String id) => box.get(id);

  static ValueListenable<Box<SwarmSession>> listenable() => box.listenable();
}
```

### Step 2: Add AgentTaskStore
创建 `lib/swarm/store/agent_task_store.dart`：

```dart
class AgentTaskStore {
  static const _boxName = 'swarm_tasks';
  static Box<AgentTask>? _box;

  static Future<void> init() async { /* ... */ }
  static Box<AgentTask> get box => _box!;

  static List<AgentTask> forSession(String sessionId) {
    return box.values
        .where((t) => t.swarmSessionId == sessionId)
        .toList();
  }

  static Future<void> put(AgentTask task) async {
    await box.put(task.id, task);
  }

  static Future<void> remove(String id) async {
    await box.delete(id);
  }

  static Future<void> removeForSession(String sessionId) async {
    final toRemove = forSession(sessionId).map((t) => t.id).toList();
    await box.deleteAll(toRemove);
  }

  static AgentTask? byId(String id) => box.get(id);

  static ValueListenable<Box<AgentTask>> listenable() => box.listenable();
}
```

### Step 3: Verify
- 运行 `flutter analyze lib/swarm/store/`

## Verification Commands

```bash
flutter analyze lib/swarm/store/swarm_session_store.dart lib/swarm/store/agent_task_store.dart
```

## Success Criteria

- SwarmSessionStore 和 AgentTaskStore 完整实现
- CRUD + 过滤 + listenable 方法正确
- 与 CodSessionStore 模式一致
