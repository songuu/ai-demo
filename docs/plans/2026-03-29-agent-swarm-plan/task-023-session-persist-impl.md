# Task 023: Session Auto-Save and Restore Flow

**depends-on**: task-022

## Description

实现 Swarm 会话自动保存和恢复功能——定时保存 + Hive 持久化。

## Execution Context

**Task Number**: 23 of 25
**Phase**: Phase 5 — Project Management
**Prerequisites**: Task 022 ProjectSelector 已完成

## BDD Scenario

```gherkin
Scenario: 系统自动保存 Swarm 会话状态
  Given 用户正在操作一个 Swarm 会话
  When 添加/移除 Agent 任务 或 任务状态变化 或 用户注入命令
  Then 系统将状态保存到 Hive 数据库
  And 保存操作在后台异步执行，不阻塞 UI
```

```gherkin
Scenario: 用户恢复之前的 Swarm 会话
  Given 用户重新打开应用
  And 用户打开 Agent Swarm Tab
  Then 系统从 Hive 加载所有历史会话
  And 在会话列表中显示历史会话
  When 用户点击该会话
  Then 系统恢复会话详情
```

**Spec Source**: `test/agent_swarm.feature` (E-3, E-4)

## Files to Modify/Create

- Modify: `lib/swarm/service/swarm_orchestrator.dart` — 添加自动保存逻辑
- Create: `lib/swarm/service/swarm_persistence_service.dart`

## Steps

### Step 1: Create SwarmPersistenceService
```dart
class SwarmPersistenceService {
  /// 初始化 Hive 存储
  static Future<void> init() async {
    await SwarmSessionStore.init();
    await AgentTaskStore.init();
    await WorktreeStore.init();
  }

  /// 定时保存（每 30 秒）
  static void startAutoSave(String sessionId);

  /// 停止自动保存
  static void stopAutoSave();

  /// 立即保存会话状态
  static Future<void> saveSession(SwarmSession session);

  /// 从 Hive 恢复会话
  static Future<SwarmSession?> restoreSession(String sessionId);

  /// 验证 worktree 状态
  static Future<void> validateWorktrees(String sessionId);
}
```

### Step 2: Integrate Auto-Save into SwarmOrchestrator
- 在 `SwarmOrchestrator` 的 `statusController` 上添加监听器
- 任何状态变化时触发保存（防抖：500ms）
- 使用 `Timer.periodic(Duration(seconds: 30))` 定时全量保存

### Step 3: Implement Restore Flow
- 应用启动时调用 `SwarmPersistenceService.init()`
- `SwarmTab.initState()` 时加载 `SwarmSessionStore.all()`
- 恢复时验证 worktree 目录是否存在，标记失效记录

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/service/swarm_persistence_service.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/service/swarm_persistence_service.dart
```

## Success Criteria

- 会话创建后自动保存到 Hive
- 状态变化后延迟 500ms 保存（防抖）
- 每 30 秒全量保存
- 应用重启后可从 Hive 恢复会话
- 失效 worktree 正确标记
