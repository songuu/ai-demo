# Task 005: Worktree Model + Store Implementation

**depends-on**: task-004

## Description

创建 Worktree Hive 模型和 WorktreeStore 持久化层。

## Execution Context

**Task Number**: 5 of 25
**Phase**: Phase 1 — Worktree Management
**Prerequisites**: Task 004 WorktreeService 已实现

## Files to Modify/Create

- Create: `lib/swarm/model/worktree.dart` — Hive model (typeId: 23)
- Create: `lib/swarm/model/worktree.g.dart` — Hive adapter (手动编写，不依赖 build_runner)
- Create: `lib/swarm/store/worktree_store.dart`

## Steps

### Step 1: Create Worktree Model
创建 `lib/swarm/model/worktree.dart`：

```dart
part 'worktree.g.dart';

@HiveType(typeId: 23)
class Worktree extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String sessionId;

  @HiveField(2)
  String path;

  @HiveField(3)
  String branch;

  @HiveField(4)
  String? commit;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String remotePath;

  @HiveField(7)
  WorktreeStatus status;
}

@HiveType(typeId: 24)
enum WorktreeStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  idle,
  @HiveField(2)
  stale,
  @HiveField(3)
  deleted,
}
```

### Step 2: Create WorktreeAdapter (Manual)
创建 `lib/swarm/model/worktree.g.dart`，手动编写 Hive TypeAdapter（不依赖 `build_runner`），参考项目中现有 `.g.dart` 文件的写法。

### Step 3: Create WorktreeStore
创建 `lib/swarm/store/worktree_store.dart`（参考 `lib/codecore/store/cod_session_store.dart` 的模式）：

```dart
class WorktreeStore {
  static const _boxName = 'swarm_worktrees';
  static Box<Worktree>? _box;

  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(WorktreeAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(WorktreeStatusAdapter());
    }
    _box = await Hive.openBox<Worktree>(_boxName);
  }

  static Box<Worktree> get box => _box!;

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

  static ValueListenable<Box<Worktree>> listenable() => box.listenable();
}
```

### Step 4: Update Task 002 Hive Registration
- 在 Task 002 的 Hive 初始化代码中，填入 `WorktreeAdapter` 和 `WorktreeStatusAdapter` 的实际注册代码

### Step 5: Verify
- 运行 `flutter analyze` 确保无错误

## Verification Commands

```bash
flutter analyze lib/swarm/model/worktree.dart lib/swarm/store/worktree_store.dart
```

## Success Criteria

- Worktree 模型包含所有字段（id, sessionId, path, branch, commit, createdAt, remotePath, status）
- WorktreeStore 提供 CRUD + forSession + listenable 方法
- Hive adapter 可正常工作
- flutter analyze 无错误
