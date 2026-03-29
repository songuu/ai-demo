# Task 002: Add AppTab.swarm Enum and Hive Registration

**depends-on**: task-001

## Description

在现有 AppTab 枚举中添加 `swarm` 条目，并注册 SwarmSession、AgentTask、Worktree 三个模型的 Hive type adapter。

## Execution Context

**Task Number**: 2 of 25
**Phase**: Foundation
**Prerequisites**: Task 001 目录结构已创建

## Files to Modify/Create

- Modify: `lib/data/model/app/tab.dart` — 在 `AppTab` 枚举中添加 `swarm` 条目
- Modify: `lib/main.dart` 或 Hive 初始化文件 — 注册 typeId 21、22、23 的 Hive adapters

## Steps

### Step 1: Add AppTab.swarm
- 读取 `lib/data/model/app/tab.dart`
- 在 `AppTab` 枚举中添加 `swarm` 条目（参考现有 `codePal`、`chat` 等条目的命名方式）
- 保持枚举值顺序（可选）

### Step 2: Register Hive Type Adapters
- 找到 Hive 初始化代码（可能在 `lib/main.dart` 或专门的初始化文件）
- 注册以下三个 adapters：
  - `SwarmSessionAdapter` (typeId: 21) — 待 Task 014 创建后注册
  - `AgentTaskAdapter` (typeId: 22) — 待 Task 014 创建后注册
  - `WorktreeAdapter` (typeId: 23) — 待 Task 005 创建后注册
- **注意**: 目前先用占位符或注释标记注册位置，Task 005 和 014 会填入实际代码

## Verification Commands

```bash
# Verify tab.dart compiles
flutter analyze lib/data/model/app/tab.dart

# Verify Hive registration compiles (after models exist)
flutter analyze
```

## Success Criteria

- `AppTab.swarm` 存在于枚举中
- Hive 初始化代码中有 typeId 21、22、23 的注册位置
- 代码能通过 `flutter analyze`
