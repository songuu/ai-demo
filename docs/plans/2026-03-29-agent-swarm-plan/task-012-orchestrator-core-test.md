# Task 012: SwarmOrchestrator Core Engine Tests

**depends-on**: task-011

## Description

为 SwarmOrchestrator 核心引擎编写 TDD 红色测试，验证并发控制、依赖 DAG、状态管理等核心逻辑。

## Execution Context

**Task Number**: 12 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 011 MultiTerminal 已完成

## BDD Scenario

```gherkin
Scenario: 用户启动一个新的 Agent 任务（完整流程）
  Given 用户已打开一个 Swarm 会话，关联项目 "flutter_server_box"
  And 该项目的 git 状态正常
  When 用户点击"+ 添加 Agent"
  And 用户选择 Agent 类型为 "Claude Code"
  And 用户点击"添加并启动"
  Then 系统执行: 创建 worktree → 启动进程 → 更新状态
```

```gherkin
Scenario: 用户优雅停止 Agent 任务
  Given 一个 Agent 任务正在运行中
  When 用户点击任务卡片的"停止"按钮
  Then 系统发送 SIGTERM 信号给 agent 进程
  And 任务状态更新为"已停止"
```

**Spec Source**: `test/agent_swarm.feature` (B-1, B-5, B-6)

## Files to Modify/Create

- Create: `test/swarm/swarm_orchestrator_test.dart`

## Steps

### Step 1: Create Test File
- 创建 `test/swarm/swarm_orchestrator_test.dart`
- Mock `WorktreeService`（不调用真实 git 命令）
- Mock `Process`（不启动真实进程）
- Mock `CodSettingsStore.resolveCli()`

### Step 2: Write Test Cases (Red - Must Fail)
1. **`buildDependencyLayers_noDependencies_allInOneLayer`**: 无依赖的任务全部分在同一层
2. **`buildDependencyLayers_linearDependency_correctTopologicalOrder`**: 线性依赖（A→B→C）拓扑排序正确
3. **`buildDependencyLayers_parallelIndependentTasks_sameLayer`**: 并行无依赖的任务在同一层
4. **`buildDependencyLayers_circularDependency_throwsSwarmException`**: 循环依赖抛出异常
5. **`launchAgent_acquiresSemaphore_slotReleasedOnExit`**: agent 退出后释放并发槽位
6. **`stopAgent_force_killsProcess`**: 强制停止调用 `Process.kill()`
7. **`stopAgent_graceful_sendsSigterm`**: 优雅停止调用 `Process.kill(ProcessSignal.sigterm)`
8. **`injectCommand_writesToStdin`**: 命令注入正确写入 stdin
9. **`statusController_broadcastsOnAgentStatusChange`**: agent 状态变更通过广播通知

### Step 3: Verify Tests Fail
- 运行 `flutter test test/swarm/swarm_orchestrator_test.dart`
- 确认测试因 `SwarmOrchestrator` 不存在而失败

## Verification Commands

```bash
# Run tests (should fail - RED state)
flutter test test/swarm/swarm_orchestrator_test.dart
```

## Success Criteria

- 所有 9 个测试用例已编写
- 测试因实现缺失而失败
- Mock 正确隔离了 WorktreeService、Process、CodSettingsStore
