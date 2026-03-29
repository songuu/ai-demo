# Task 014: AgentInstance + AgentTask + SwarmSession Models

**depends-on**: task-013

## Description

实现 AgentTask 和 SwarmSession Hive 模型（含手动编写的 .g.dart adapter），以及 AgentInstance 内存模型。

## Execution Context

**Task Number**: 14 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 013 SwarmOrchestrator 已完成

## Files to Modify/Create

- Modify: `lib/swarm/model/agent_instance.dart` — 补充完整（Task 013 部分创建）
- Create: `lib/swarm/model/agent_task.dart` (typeId: 22)
- Create: `lib/swarm/model/agent_task.g.dart`
- Create: `lib/swarm/model/swarm_session.dart` (typeId: 21)
- Create: `lib/swarm/model/swarm_session.g.dart`
- Create: `lib/swarm/model/swarm_status.dart` — SwarmSessionStatus 和 AgentTaskStatus 枚举

## Steps

### Step 1: Create Status Enums
```dart
// lib/swarm/model/swarm_status.dart
enum SwarmSessionStatus { idle, running, completed, failed }
enum AgentTaskStatus { pending, running, completed, failed, stopped, crashed }
```

### Step 2: Create AgentTask Model (typeId: 22)
```dart
// lib/swarm/model/agent_task.dart
part 'agent_task.g.dart';

@HiveType(typeId: 22)
class AgentTask extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String swarmSessionId;
  @HiveField(2) String title;
  @HiveField(3) String provider; // claude/codex/gemini
  @HiveField(4) String? instruction;
  @HiveField(5) String? worktreePath;
  @HiveField(6) String? worktreeBranch;
  @HiveField(7) List<String> dependsOn;
  @HiveField(8) AgentTaskStatus status;
  @HiveField(9) int? exitCode;
  @HiveField(10) DateTime createdAt;
  @HiveField(11) DateTime? completedAt;
}
```

### Step 3: Create SwarmSession Model (typeId: 21)
```dart
// lib/swarm/model/swarm_session.dart
part 'swarm_session.g.dart';

@HiveType(typeId: 21)
class SwarmSession extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String rootPath;
  @HiveField(3) String defaultBranch;
  @HiveField(4) List<String> agentIds;
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime updatedAt;
  @HiveField(7) SwarmSessionStatus status;
}
```

### Step 4: Manually Write .g.dart Files
- 参考项目中现有 `.g.dart` 文件（如 `lib/codecore/model/cod_session.g.dart`）手动编写 Hive TypeAdapter
- 确保 `typeId` 与模型定义一致（21、22）
- 不使用 `build_runner`

### Step 5: Update Task 002 Hive Registration
- 在 Task 002 的 Hive 初始化代码中填入 `AgentTaskAdapter`、`SwarmSessionAdapter` 及枚举 adapter 的注册

### Step 6: Verify
- 运行 `flutter analyze lib/swarm/model/`

## Verification Commands

```bash
flutter analyze lib/swarm/model/
```

## Success Criteria

- AgentTask 和 SwarmSession 模型包含所有字段
- 手动编写的 .g.dart adapter 可正常工作
- Hive 初始化注册了所有新 adapter
- flutter analyze 无错误
