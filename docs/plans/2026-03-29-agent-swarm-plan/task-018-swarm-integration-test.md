# Task 018: Swarm Integration Tests

**depends-on**: task-017

## Description

编写端到端集成测试，覆盖 Swarm 会话创建、Agent 任务执行、worktree 生命周期的完整流程。

## Execution Context

**Task Number**: 18 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 017 对话框已完成

## BDD Scenario

```gherkin
Scenario: 用户创建新的 Agent Swarm 会话
  Given 用户已打开 Agent Swarm Tab
  When 用户点击"新建 Swarm"按钮
  And 用户填写 Swarm 名称为 "功能 X 开发"
  And 用户选择关联项目为 "flutter_server_box"
  And 用户点击"创建"按钮
  Then 系统在 Hive 中创建一个新的 SwarmSession 记录
  And 新会话自动出现在左侧会话列表顶部
```

**Spec Source**: `test/agent_swarm.feature` (A-1)

## Files to Modify/Create

- Create: `test/swarm/swarm_integration_test.dart`

## Steps

### Step 1: Create Integration Test
- 创建 `test/swarm/swarm_integration_test.dart`
- 使用 `integration_test` 包（而非 `flutter_test`）
- Mock 所有 dart:io 和 git 命令（使用 TestWidgetsFlutterBinding + 自定义 mock）

### Step 2: Write Integration Test Cases (Red)
1. **`createSwarmSession_persistsToHive`**: 创建 SwarmSession 后，Hive 中可查询到
2. **`addAgentTask_createsWorktree`**: 添加 Agent 任务后，`WorktreeService.createWorktree` 被调用
3. **`agentComplete_updatesStatus`**: Agent 退出后，Hive 中的 `AgentTask.status` 更新为 completed
4. **`stopAgent_removesFromRunning`**: 停止 Agent 后，`_runningAgents` 中移除该实例
5. **`removeSession_cleanupWorktrees`**: 删除会话后，关联的 worktree 被清理

### Step 3: Verify Tests Fail
- 运行 `flutter test test/swarm/swarm_integration_test.dart`
- 确认测试因实现缺失而失败（RED 状态）

## Verification Commands

```bash
# Run integration tests (should fail - RED state)
flutter test test/swarm/swarm_integration_test.dart
```

## Success Criteria

- 5 个集成测试用例已编写
- 测试因实现缺失而失败（RED）
- Mock 覆盖了 git 和进程调用
