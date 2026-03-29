# Task 025: Error Handling and Edge Case UI

**depends-on**: task-024

## Description

实现错误处理和边界情况 UI——覆盖 F 类场景的所有错误提示和恢复操作。

## Execution Context

**Task Number**: 25 of 25
**Phase**: Phase 5 — Project Management
**Prerequisites**: Task 024 导出功能已完成

## BDD Scenario

```gherkin
Scenario: Git worktree 创建失败 - 分支已存在
  Given 用户尝试添加一个新的 Agent 任务
  And 系统尝试创建分支 `swarm/s1/claude-1`
  But 该分支在远程仓库已存在
  When 系统执行 `git branch`
  Then 系统自动重命名为 `swarm/s1/claude-1-local`
  And 显示通知
```

```gherkin
Scenario: Agent 进程僵死（无响应但进程存活）
  Given 一个 Agent 任务状态为"运行中"
  And 进程在 5 分钟内没有产生任何输出
  When 系统检测到输出停滞
  Then 终端区域显示警告
  And 提供"发送 ping" / "终止并重启" / "忽略" 选项
```

```gherkin
Scenario: 磁盘空间不足
  Given 用户启动 Agent 任务
  And 系统检测到磁盘空间低于阈值
  Then 系统显示警告
  And 阻止创建新的 worktree
```

**Spec Source**: `test/agent_swarm.feature` (F-1, F-2, F-3, F-4, F-5, F-6, F-7)

## Files to Modify/Create

- Create: `lib/swarm/service/swarm_error_handler.dart`
- Modify: 各 widget 添加错误处理 UI

## Steps

### Step 1: Create SwarmErrorHandler
```dart
enum SwarmError {
  worktreeConflict,
  branchExists,
  diskSpaceLow,
  commandNotFound,
  worktreeLimitReached,
  agentCrashed,
  agentStalled,
  directoryNotFound,
  gitRepoCorrupted,
}

class SwarmErrorHandler {
  static String getMessage(SwarmError error, {Map<String, dynamic>? details});
  static List<ErrorAction> getActions(SwarmError error);
  static bool shouldBlockOperation(SwarmError error);
}
```

### Step 2: Integrate Error Handling into Orchestrator
- 在 `WorktreeService.createWorktree()` 捕获 git 错误，转换为 `SwarmError`
- 在 `SwarmOrchestrator.launchAgent()` 捕获进程启动失败，转换为 `SwarmError`
- 通过 `StreamController<SwarmError>` 广播错误，UI 层监听

### Step 3: Implement Error Display UI
- `SnackBar` 显示操作失败通知
- 对话框显示详细错误信息和恢复选项
- 任务卡片显示错误状态（红色边框 + 错误图标）
- 磁盘/内存警告使用 `Banner` 或顶部通知条

### Step 4: Implement Specific Error Scenarios
1. **worktree conflict (F-1)**: 自动重命名 + Toast 通知
2. **disk space low (F-5)**: 阻止创建 worktree，显示警告条
3. **memory high (F-6)**: 显示警告条，不自动终止
4. **directory not found (F-4)**: 对话框询问重新定位或删除
5. **git repo corrupted (F-7)**: 阻止操作，显示诊断提示
6. **command not found (F-3)**: 对话框引导用户配置路径

### Step 5: Verify
- 运行 `flutter analyze lib/swarm/service/swarm_error_handler.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/
```

## Success Criteria

- 所有 SwarmError 类型有对应的用户友好错误消息
- 错误处理正确集成到 Orchestrator 和 Service 层
- UI 正确显示错误通知和恢复选项
- 不会静默吞掉错误
