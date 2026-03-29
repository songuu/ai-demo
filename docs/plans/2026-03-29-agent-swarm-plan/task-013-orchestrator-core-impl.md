# Task 013: SwarmOrchestrator Core Engine Implementation

**depends-on**: task-012

## Description

实现 SwarmOrchestrator 核心引擎——管理 agent 进程生命周期、并发控制、依赖 DAG 拓扑排序、命令注入。

## Execution Context

**Task Number**: 13 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 012 测试已编写（RED 状态）

## Files to Modify/Create

- Create: `lib/swarm/service/swarm_orchestrator.dart`
- Create: `lib/swarm/model/agent_instance.dart` — 内存态 agent 实例

## Steps

### Step 1: Create AgentInstance Model
创建 `lib/swarm/model/agent_instance.dart`：

```dart
import 'dart:async';
import 'dart:io';

class AgentInstance {
  final AgentTask task;
  final Process process;
  final StreamController<String> outputController;
  final File logFile;
  AgentStatus status;
  DateTime startedAt;

  AgentInstance({
    required this.task,
    required this.process,
    required this.outputController,
    required this.logFile,
    this.status = AgentStatus.running,
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();
}

enum AgentStatus { idle, running, completed, failed, stopped, crashed }
```

### Step 2: Implement SwarmOrchestrator
创建 `lib/swarm/service/swarm_orchestrator.dart`：

核心方法（参考 architecture.md 的详细设计）：

1. **`static final instance`** — 单例访问点
2. **`final Map<String, AgentInstance> _runningAgents`** — 内存中的 agent 实例
3. **`final _semaphore`** — `_Semaphore(maxConcurrent: 4)`
4. **`final statusController`** — `StreamController<SwarmStatusEvent>.broadcast()`
5. **`buildDependencyLayers(List<AgentTask>)`** — 拓扑排序 DAG 解析
6. **`launchAgent(AgentTask)`** — 创建 worktree → 启动进程 → 注册实例 → 监听输出/退出
7. **`launchAllAgents(List<AgentTask>)`** — 按 DAG 层级执行
8. **`launchParallelAgents(List<AgentTask>)`** — 只启动无依赖的任务
9. **`stopAgent(String agentId, {bool force = false})`** — SIGTERM 或 SIGKILL
10. **`injectCommand(String agentId, String command)`** — stdin 注入
11. **`getAgentOutput(String agentId)`** — 返回 output stream
12. **`stopAll()`** — 停止所有 agent

### Step 3: Implement Semaphore
```dart
class _Semaphore {
  final int maxConcurrent;
  int _current = 0;
  final _waiting = <Completer<void>>[];

  Future<void> acquire() async { /* ... */ }
  void release() { /* ... */ }
}
```

### Step 4: Run Tests
- 运行 `flutter test test/swarm/swarm_orchestrator_test.dart`
- 确认所有测试通过（GREEN 状态）

## Verification Commands

```bash
flutter test test/swarm/swarm_orchestrator_test.dart
```

## Success Criteria

- `SwarmOrchestrator` 单例存在
- 所有 8 个核心方法实现
- DAG 拓扑排序正确处理循环依赖
- Semaphore 正确控制并发数
- 所有 9 个单元测试通过
