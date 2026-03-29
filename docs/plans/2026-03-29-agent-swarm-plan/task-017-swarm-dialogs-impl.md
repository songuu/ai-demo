# Task 017: NewSwarmDialog and NewAgentDialog

**depends-on**: task-016

## Description

实现新建 Swarm 会话对话框和添加 Agent 任务对话框。

## Execution Context

**Task Number**: 17 of 25
**Phase**: Phase 3 — Swarm Orchestration
**Prerequisites**: Task 016 SwarmDashboard 已完成

## BDD Scenario

```gherkin
Scenario: 用户创建新的 Agent Swarm 会话
  Given 用户已打开 Agent Swarm Tab
  When 用户点击"新建 Swarm"按钮
  Then 系统显示新建 Swarm 会话对话框
  And 对话框包含: Swarm 名称、关联项目下拉选择、描述
```

```gherkin
Scenario: 用户向 Swarm 中添加一个新的 Agent 任务
  Given 用户已打开一个已存在的 Swarm 会话
  When 用户点击工作区中的"+ 添加 Agent"按钮
  Then 系统显示 Agent 任务配置面板
  And 用户选择 Agent 类型为 "Claude Code"
  And 用户点击"添加并启动"
  Then 系统自动为该任务创建一个 git worktree 分支
```

**Spec Source**: `test/agent_swarm.feature` (A-1, A-2, B-1)

## Files to Modify/Create

- Create: `lib/swarm/widget/new_swarm_dialog.dart`
- Create: `lib/swarm/widget/new_agent_dialog.dart`

## Steps

### Step 1: Create NewSwarmDialog
- 继承 `StatelessWidget`，使用 `showDialog()` 调用
- 表单字段：
  - `SwarmSession.title` — TextField，必填
  - `SwarmSession.rootPath` — 项目路径选择（TextField + 文件夹选择按钮）
  - 显示项目 git 状态（当前分支、worktree 数量、最近提交）
- 底部按钮：「取消」和「创建」（调用 `SwarmSessionStore.create()`）

### Step 2: Create NewAgentDialog
- 继承 `StatefulWidget`，使用 `showDialog()` 调用
- 表单字段：
  - Agent 类型 — DropdownButton（Claude Code / Codex / Gemini CLI / 自定义）
  - 任务描述 — TextField
  - 启动参数 — TextField（可选）
  - 依赖任务 — Chips/多选（从现有任务列表选择，用于 `dependsOn`）
  - 自定义分支名 — Switch + TextField（可选）
- 点击「添加并启动」：
  1. 调用 `SwarmOrchestrator.launchAgent()`
  2. 创建 `AgentTask` 记录
  3. 写入 Hive
  4. 关闭对话框

### Step 3: Integrate with SwarmDashboard
- 在 `SwarmDashboard` 的中栏顶部添加「+ 添加 Agent」浮动按钮
- 点击触发 `NewAgentDialog`

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/widget/new_swarm_dialog.dart lib/swarm/widget/new_agent_dialog.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/new_swarm_dialog.dart lib/swarm/widget/new_agent_dialog.dart
```

## Success Criteria

- NewSwarmDialog 表单完整，验证必填字段
- NewAgentDialog 表单完整，Agent 类型下拉正确
- 点击创建/添加后数据正确写入 Hive
- 对话框关闭后 UI 自动刷新
