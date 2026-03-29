# Agent Swarm 多 Agent 并行管理系统 - 设计文档

## 上下文与动机

当前 flutter_server_box 应用已具备基本的 Claude/Codex/Gemini CLI 会话管理能力（codecore 模块）和 OpenClaw 集成（chat 模块）。用户需要实现类似 Superset.sh 的多 agent 并行编排能力：

- **Superset.sh**（参考项目）：Electron + React 桌面应用，通过 git worktree 隔离并行运行多个 AI 编码 agent，实时监控和命令注入，内置 diff viewer
- **本项目目标**：纯 Flutter 实现，将多 agent 编排能力集成到 flutter_server_box 中

## 需求概述

| 维度 | 需求 |
|------|------|
| UI 入口 | 新增独立 Agent Swarm Tab |
| 核心功能 | 实时多终端监控 + 命令注入 + 会话历史管理 + 无缝切换 |
| 隔离机制 | Git worktree 隔离（每个 agent 任务独立分支） |
| 启动方式 | 用户手动启动（UI 创建任务，后台运行） |
| 项目管理 | 跨项目支持（当前项目 + 切换根路径管理其他项目） |
| 变更管理 | 内置 diff viewer + git merge/rebase |
| 技术方案 | 纯 Flutter（复用 xterm.dart + Dart subprocess git） |

## 详细设计

### 整体架构

```
lib/swarm/
  model/                    # 数据模型层 (Hive-backed)
    swarm_session.dart        # Swarm 会话（顶层容器）
    agent_task.dart           # Agent 任务描述
    agent_instance.dart       # 运行中的 Agent 实例（进程+状态）
    worktree.dart            # Git Worktree 模型
    diff_file.dart           # Diff 文件
    merge_conflict.dart      # 合并冲突

  store/                    # 持久化层 (Hive)
    swarm_session_store.dart
    worktree_store.dart

  service/                  # 业务逻辑层
    worktree_service.dart     # Git worktree 管理（subprocess）
    swarm_orchestrator.dart   # Agent 编排引擎（核心）
    swarm_process_manager.dart # 进程生命周期管理
    merge_service.dart        # Diff + Merge 服务
    swarm_log_service.dart    # 日志聚合服务

  widget/                   # Swarm 专用 Widget
    swarm_terminal_panel.dart  # 终端面板（基于 xterm.dart，命令注入）
    swarm_multi_terminal.dart  # 多终端网格布局（split-h/v/grid/tabs）
    diff_viewer.dart           # Diff 查看器
    merge_resolver.dart       # Merge 冲突解决
    agent_status_card.dart    # Agent 状态卡片
    swarm_control_bar.dart    # 控制栏

  view/                     # 页面层
    swarm_tab.dart             # Tab 入口
    swarm_dashboard.dart       # 主仪表板（三栏布局）
    worktree_manager_page.dart # Worktree 管理页面
    new_swarm_dialog.dart     # 新建 Swarm 对话框
    new_agent_dialog.dart     # 添加 Agent 任务对话框

app.dart                     # 新增 AppTab.swarm 条目
```

### 核心模型

```dart
// Swarm 会话：顶层容器，管理多个 Agent
@HiveType(typeId: 21)
class SwarmSession extends HiveObject {
  @HiveField(0) String id;           // 时间戳 UUID
  @HiveField(1) String title;        // 会话标题
  @HiveField(2) String rootPath;     // 根项目路径
  @HiveField(3) String defaultBranch; // 默认分支
  @HiveField(4) List<String> agentIds; // Agent ID 列表
  @HiveField(5) DateTime createdAt;
  @HiveField(6) DateTime updatedAt;
  @HiveField(7) SwarmSessionStatus status; // idle/running/completed
}

// Agent 任务：在独立 worktree 中运行的工作单元
@HiveType(typeId: 22)
class AgentTask extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String swarmSessionId;
  @HiveField(2) String title;
  @HiveField(3) String provider;       // claude/codex/gemini
  @HiveField(4) String? instruction;   // 给 Agent 的指令
  @HiveField(5) String? worktreePath;  // worktree 路径
  @HiveField(6) String? worktreeBranch; // worktree 分支名
  @HiveField(7) List<String> dependsOn; // 依赖任务 ID
  @HiveField(8) AgentTaskStatus status;
  @HiveField(9) int? exitCode;
}

// 运行中的 Agent 实例（内存态，不持久化）
class AgentInstance {
  final AgentTask task;
  final Process process;
  final StreamController<String> outputController;
  AgentStatus status;
  DateTime startedAt;
}
```

### 核心服务

#### WorktreeService
通过 `dart:io` subprocess 调用 git worktree 命令：
- `createWorktree(repoPath, branchName)` → `git worktree add <path> <branch>`
- `listWorktrees(repoPath)` → `git worktree list --porcelain`
- `removeWorktree(repoPath, worktreePath)` → `git worktree remove --force <path>`
- `pruneWorktrees(repoPath)` → `git worktree prune`
- `createBranch(repoPath, branchName)` → `git branch <branch>`
- `getCurrentBranch(repoPath)` → `git branch --show-current`

#### SwarmOrchestrator
- `startSwarmSession(...)` → 创建会话 + 初始化 worktree 目录
- `launchAgent(task)` → 在 worktree 中启动 agent 进程
- `launchParallelAgents(tasks)` → 并行启动无依赖的 agent（Semaphore 限制并发数）
- `stopAgent(agentId)` → 终止进程
- `stopSwarmSession(sessionId)` → 停止所有 agent
- `injectCommand(agentId, command)` → 向进程 stdin 注入命令
- `getAgentOutput(agentId)` → 获取 agent 输出流

#### MergeService
- `getDiff(repoPath, branch?)` → `git diff [--name-only]` 或 `git diff <branch>`
- `getMergeStatus(repoPath)` → `git merge --stat`
- `getConflicts(repoPath)` → `git ls-files -u`
- `resolveConflict(...)` → `git checkout --ours/--theirs <file>`

### UI 布局

```
┌────────────┬──────────────────┬─────────────────────────┐
│ Swarm     │   Agent 任务列表  │   多终端面板 / Diff 查看器 │
│ 会话列表   │                  │                          │
│            │  ┌────────────┐ │  ┌────────────────────┐ │
│ • 会话 A   │  │ Agent 1   │ │  │ Agent 1 Terminal   │ │
│ • 会话 B   │  │ ● Running  │ │  ├────────────────────┤ │
│            │  └────────────┘ │  │ Agent 2 Terminal   │ │
│ [+] 新建   │  ┌────────────┐ │  ├────────────────────┤ │
│            │  │ Agent 2   │ │  │ Agent 3 Terminal   │ │
│ 项目切换    │  │ ✓ Done    │ │  └────────────────────┘ │
│ [flutter]  │  └────────────┘ │                          │
└────────────┴──────────────────┴─────────────────────────┘
```

- **左栏**（会话列表 + 项目切换）：280px
- **中栏**（Agent 任务卡片）：自适应
- **右栏**（多终端/Diff）：自适应，支持 split-h/split-v/grid/tabs 切换

### 实现阶段

```
Phase 1: Worktree 管理基础设施
  - WorktreeService（subprocess git worktree）
  - Worktree 模型 + Store
  - Worktree 管理页面（列表/创建/删除）

Phase 2: 单 Agent 增强终端
  - SwarmTerminalPanel（基于 xterm.dart，命令注入）
  - SwarmMultiTerminal（多终端网格布局）
  - 命令注入（stdin pipe）
  - Agent 状态卡片

Phase 3: Swarm 编排引擎
  - SwarmOrchestrator
  - SwarmSession / AgentTask 模型 + Store
  - Swarm Dashboard + Tab 入口
  - 状态监控 UI
  - 与 CodLauncher 集成（复用 CLI 启动逻辑）

Phase 4: Diff + Merge 集成
  - MergeService
  - DiffViewer widget（复用 highlight 包做语法高亮）
  - MergeResolver widget
  - 冲突解决流程

Phase 5: 项目管理增强
  - 跨项目切换
  - Swarm 会话历史保存和恢复
  - 快捷键支持
```

### 技术决策

| 决策 | 方案 | 理由 |
|------|------|------|
| Git worktree | Subprocess (`Process.run git worktree`) | 100% 功能覆盖，最稳定可靠 |
| 数据持久化 | Hive（复用现有模式） | 与现有 CodSessionStore 一致 |
| 终端渲染 | xterm.dart (`computer` 包) | 项目已有集成，命令注入通过 stdin |
| Agent 隔离 | 无共享架构（worktree + 独立进程 + 独立日志） | 完全隔离，故障隔离 |
| 并发控制 | Semaphore（默认 4 个并发） | 避免资源耗尽 |
| Diff 算法 | 行到行 diff + highlight 包语法高亮 | 满足需求，实现简单 |

## Design Documents

- [BDD Specifications](./bdd-specs.md) - Behavior scenarios and testing strategy
- [Architecture](./architecture.md) - System architecture and component details
- [Best Practices](./best-practices.md) - Security, performance, and code quality guidelines
