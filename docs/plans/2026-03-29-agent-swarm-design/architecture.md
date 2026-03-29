# Agent Swarm 架构详细设计

## 一、技术选型

### 1.1 Git Worktree 操作

**方案**：Subprocess 调用 `git worktree` 命令

**理由**：
- 100% 功能覆盖（worktree add/remove/list/prune）
- 无额外依赖
- 跨平台（Windows/macOS/Linux）
- 行为确定，易于调试

**核心实现**：
```dart
class WorktreeService {
  Future<Worktree> createWorktree(String repoPath, String branch) async {
    final wtPath = _buildWorktreePath(repoPath, branch);
    final result = await Process.run(
      'git', ['worktree', 'add', wtPath, branch],
      workingDirectory: repoPath,
    );
    if (result.exitCode != 0) {
      throw WorktreeException('create failed: ${result.stderr}');
    }
    return Worktree(path: wtPath, branch: branch, ...);
  }

  Future<List<WorktreeInfo>> listWorktrees(String repoPath) async {
    final result = await Process.run(
      'git', ['worktree', 'list', '--porcelain'],
      workingDirectory: repoPath,
    );
    return _parseWorktreeList(result.stdout as String);
  }

  Future<void> removeWorktree(String repoPath, String path, {bool force = false}) async {
    final args = ['worktree', 'remove', path];
    if (force) args.add('--force');
    await Process.run('git', args, workingDirectory: repoPath);
  }

  Future<void> pruneWorktrees(String repoPath) async {
    await Process.run('git', ['worktree', 'prune'], workingDirectory: repoPath);
  }

  Future<String> createBranch(String repoPath, String name) async {
    final result = await Process.run(
      'git', ['branch', name],
      workingDirectory: repoPath,
    );
    if (result.exitCode != 0) {
      throw WorktreeException('branch create failed: ${result.stderr}');
    }
    return name;
  }
}
```

### 1.2 数据持久化

复用现有 Hive 模式：
- `SwarmSessionStore`（typeId: 21）：Swarm 会话持久化
- `WorktreeStore`（typeId: 23）：Worktree 元数据持久化
- `AgentTask` 不持久化进程实例，仅持久化任务配置

### 1.3 终端渲染

基于 `computer` 包（封装 xterm.dart）实现 `SwarmTerminalPanel`：

```dart
class SwarmTerminalPanel extends StatefulWidget {
  final AgentInstance? agent;
  final bool interactive;

  const SwarmTerminalPanel({super.key, this.agent, this.interactive = true});

  @override
  State<SwarmTerminalPanel> createState() => _SwarmTerminalPanelState();
}

class _SwarmTerminalPanelState extends State<SwarmTerminalPanel> {
  late final Terminal _terminal;
  Process? _process;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      options: TerminalOptions(
        fontFamily: 'JetBrains Mono, monospace',
        fontSize: 13,
        theme: TerminalTheme(/* ... */),
      ),
    );
    if (widget.agent != null) {
      _attachToAgent(widget.agent!);
    }
  }

  Future<void> _attachToAgent(AgentInstance agent) async {
    _process = agent.process;
    _process!.stdout.listen((data) {
      _terminal.write(utf8.decode(data, allowMalformed: true));
    });
    _process!.stderr.listen((data) {
      _terminal.write('\x1b[31m${utf8.decode(data)}\x1b[0m');
    });
    _terminal.onOutput = (data) {
      _process?.stdin.add(utf8.encode(data));
      _process?.stdin.flush();
    };
  }

  /// 向运行中的 agent 注入命令
  Future<void> injectCommand(String command) async {
    if (_process != null) {
      _process!.stdin.write('$command\n');
      await _process!.stdin.flush();
    }
  }
}
```

## 二、分层设计

### 2.1 Model 层

```
SwarmSession (typeId: 21)
  ├── id: String (时间戳 UUID)
  ├── title: String
  ├── rootPath: String (git 仓库路径)
  ├── defaultBranch: String (默认 main)
  ├── agentIds: List<String>
  ├── status: SwarmSessionStatus
  └── metadata: Map<String, dynamic>

AgentTask (typeId: 22)
  ├── id: String
  ├── swarmSessionId: String
  ├── title: String
  ├── provider: String (claude/codex/gemini)
  ├── instruction: String?
  ├── worktreePath: String?
  ├── worktreeBranch: String?
  ├── dependsOn: List<String>
  └── status: AgentTaskStatus

AgentInstance (内存态，非持久化)
  ├── task: AgentTask
  ├── process: Process
  ├── outputController: StreamController<String>
  └── startedAt: DateTime

Worktree (typeId: 23)
  ├── id: String
  ├── sessionId: String
  ├── path: String
  ├── branch: String
  ├── commit: String?
  └── status: WorktreeStatus
```

### 2.2 Store 层

```dart
class SwarmSessionStore {
  static const _boxName = 'swarm_sessions';
  static Box<SwarmSession>? _box;

  static Future<void> init() async { /* ... */ }
  static List<SwarmSession> all();
  static Future<SwarmSession> create({required String title, required String rootPath});
  static Future<void> put(SwarmSession session);
  static Future<void> remove(String id);
  static SwarmSession? byId(String id);
  static ValueListenable<Box<SwarmSession>> listenable();
}

class WorktreeStore {
  static const _boxName = 'swarm_worktrees';
  static Box<Worktree>? _box;

  static Future<void> init() async { /* ... */ }
  static List<Worktree> forSession(String sessionId);
  static Future<void> put(Worktree wt);
  static Future<void> remove(String id);
  static Future<void> removeForSession(String sessionId);
}
```

### 2.3 Service 层

```dart
// 核心编排引擎
class SwarmOrchestrator {
  static final _instance = SwarmOrchestrator._();
  static SwarmOrchestrator get instance => _instance;

  // 内存中的运行中 agent
  final Map<String, AgentInstance> _runningAgents = {};

  // 并发控制（默认 4）
  final _semaphore = _Semaphore(maxConcurrent: 4);

  // 状态变更通知
  final statusController = StreamController<SwarmStatusEvent>.broadcast();

  Future<SwarmSession> startSession({
    required String title,
    required String rootPath,
    List<AgentTask>? tasks,
  }) async { /* ... */ }

  /// 依赖 DAG 解析与拓扑排序
  ///
  /// 将任务列表按依赖关系拓扑排序，返回可执行的层级列表。
  /// 每层内的任务可以并行执行，层间必须串行（等待上一层完成）。
  List<List<AgentTask>> buildDependencyLayers(List<AgentTask> allTasks) {
    final taskMap = {for (final t in allTasks) t.id: t};
    final inDegree = {for (final t in allTasks) t.id: t.dependsOn.length};
    final layers = <List<AgentTask>>[];
    var remaining = Set<String>.from(inDegree.keys);

    while (remaining.isNotEmpty) {
      // 找出入度为 0 的任务（无依赖或依赖已全部完成）
      final ready = remaining.where((id) => inDegree[id] == 0).toList();
      if (ready.isEmpty) {
        // 循环依赖检测
        throw SwarmException('Circular dependency detected among tasks: $remaining');
      }
      layers.add(ready.map((id) => taskMap[id]!).toList());
      remaining.removeAll(ready);

      // 更新入度：移除已分配层的任务的出度影响
      for (final taskId in ready) {
        final task = taskMap[taskId]!;
        for (final dependent in allTasks.where((t) => t.dependsOn.contains(taskId))) {
          inDegree[dependent.id] = (inDegree[dependent.id] ?? 1) - 1;
        }
      }
    }
    return layers;
  }

  /// 启动所有任务（依赖感知调度）
  Future<void> launchAllAgents(List<AgentTask> tasks) async {
    final layers = buildDependencyLayers(tasks);
    for (final layer in layers) {
      // 当前层内的任务并行执行
      final futures = layer.map(launchAgent).toList();
      await Future.wait(futures);
      // 等待上一层全部完成后，再启动下一层
      // （已在每个 launchAgent 的退出处理器中更新 _runningAgents）
    }
  }

  /// 等待依赖任务完成后再启动（依赖感知的单任务启动）
  Future<void> launchAgent(AgentTask task) async {
    // 1. 检查依赖是否全部完成
    for (final depId in task.dependsOn) {
      final depAgent = _runningAgents[depId];
      if (depAgent != null && depAgent.status != AgentStatus.completed &&
          depAgent.status != AgentStatus.failed) {
        // 依赖未完成，等待
        await depAgent.outputController.stream.firstWhere(
          (_) => depAgent.status == AgentStatus.completed ||
                 depAgent.status == AgentStatus.failed,
        );
      }
    }

    await _semaphore.acquire();
    try {
      // 2. 创建 worktree
      final wt = await WorktreeService.createWorktree(
        rootPath, task.worktreeBranch ?? 'swarm/${task.id}',
      );
      // 3. 写入 instruction 到 worktree（.swarm_instruction 文件已被 .gitignore 忽略）
      if (task.instruction != null) {
        await File('${wt.path}/.swarm_instruction').writeAsString(task.instruction!);
      }
      // 4. 启动 agent 进程（复用 CodLauncher 的环境变量 patch）
      final process = await _startAgentProcess(task, wt.path);
      // 5. 注册实例
      final instance = AgentInstance(task: task, process: process, ...);
      _runningAgents[task.id] = instance;
      // 6. 监听输出
      _pipeOutput(instance);
      // 7. 监听退出
      _setupExitHandler(instance);
    } finally {
      _semaphore.release();
    }
  }

  Future<void> launchParallelAgents(List<AgentTask> tasks) async {
    // 只启动无依赖的任务
    final runnable = tasks.where((t) =>
      t.dependsOn.isEmpty ||
      t.dependsOn.every((depId) => _runningAgents[depId]?.status == AgentStatus.completed)
    ).toList();
    await Future.wait(runnable.map(launchAgent));
  }

  Future<void> injectCommand(String agentId, String command) async {
    final agent = _runningAgents[agentId];
    if (agent != null) {
      agent.process.stdin.write('$command\n');
      await agent.process.stdin.flush();
    }
  }

  Future<void> stopAgent(String agentId, {bool force = false}) async {
    final agent = _runningAgents[agentId];
    if (agent == null) return;
    if (force) {
      agent.process.kill(ProcessSignal.sigkill);
    } else {
      agent.process.kill(ProcessSignal.sigterm);
    }
  }

  Stream<String> getAgentOutput(String agentId) {
    return _runningAgents[agentId]?.outputController.stream ?? const Stream.empty();
  }

  void _pipeOutput(AgentInstance agent) {
    agent.process.stdout.listen((data) {
      final line = utf8.decode(data, allowMalformed: true);
      agent.outputController.add(line);
      // 写入日志文件
      agent.logFile.writeAsStringSync('$line\n', mode: FileMode.append);
    });
    agent.process.stderr.listen((data) {
      final line = utf8.decode(data, allowMalformed: true);
      agent.outputController.add('[stderr] $line');
    });
  }

  void _setupExitHandler(AgentInstance agent) {
    agent.process.exitCode.then((code) async {
      agent.status = code == 0 ? AgentStatus.completed : AgentStatus.failed;
      agent.outputController.add('[Process exited with code $code]');
      _runningAgents.remove(agent.task.id);
      statusController.add(SwarmStatusEvent(agent.task.id, agent.status));
    });
  }
}
```

## 三、日志文件结构

```
.codecore/
  sessions/                  # CodSession/CodPal 会话日志（现有）
  swarm/                     # Agent Swarm 日志（新增）
    sessions/
      <session_id>/
        swarm.log              # Swarm 编排日志
        agents/
          <agent_id>.log       # 各 Agent stdout/stderr
        worktrees/
          <wt_id>.log          # worktree 操作日志
        merges/
          <merge_id>.log       # merge 操作日志
```

> **目录隔离**：`.codecore/swarm/` 与 `.codecore/sessions/` 独立存放，互不干扰。Swarm 日志在会话删除时可一并清理。

## 四、与现有模块的集成

### 4.1 复用点

| 现有模块 | 复用内容 |
|---------|---------|
| `CodCliRunner` | `Process.start` 模式、日志文件写入 |
| `CodLauncher` | `CodSettingsStore.resolveCli()`、`getPatchedEnvironment(provider)` 环境变量 patch |
| `CodCliRunner.injectCommand()` | 在 `CodCliRunner` 中新增静态方法供 Swarm 直接调用 |
| `Hive` 模式 | 所有 Store 复用 `CodSessionStore` 的 `copyWith` + `ValueListenable` 模式 |
| `computer` 包 | `Terminal` / `TerminalController` 终端渲染 |
| `CodEmbeddedTerminal` | 基础概念和布局模式 |

### 4.2 需要扩展的点

| 现有类 | 扩展方式 |
|--------|---------|
| `AppTab` | 新增 `AppTab.swarm` 枚举值 |
| `main.dart` / `app.dart` | 注册 Hive typeAdapters（typeId 21-23） |
| `lib/route.dart` | 新增 `/swarm` 路由 |

## 五、性能设计

| 策略 | 实现 |
|------|------|
| 并发数限制 | `Semaphore` 控制，默认最多 4 个并发 agent |
| 进程僵死检测 | 设置 30 分钟超时，超时自动 kill |
| stdin 注入接口 | `SwarmOrchestrator.injectCommand()` 封装 `Process.stdin.write().flush()`，复用 `CodCliRunner` 的进程管理 |
| 日志轮转 | 单文件超过 50MB 自动轮转 |
| 输出流控制 | `StreamController` 有界缓冲，超出 10000 行自动截断旧数据 |
| 内存监控 | 定期检查进程内存使用，超过 2GB 警告 |
| Worktree 池 | 复用最近使用的 worktree（池大小 10），减少创建开销 |
