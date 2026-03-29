# Task 010: AgentStatusCard Widget Implementation

**depends-on**: task-009

## Description

实现 AgentStatusCard widget——显示单个 agent 任务的状态卡片，包含名称、类型、状态指示器、运行时长、分支名和输出预览。

## Execution Context

**Task Number**: 10 of 25
**Phase**: Phase 2 — Enhanced Terminal
**Prerequisites**: Task 009 SwarmTerminalPanel 已完成

## BDD Scenario

```gherkin
Scenario: 用户在 Swarm 面板中查看所有 Agent 任务状态
  Given 用户已打开一个包含 3 个 agent 任务的 Swarm 会话
  And 各任务状态分别为: 运行中、已完成、失败
  When 用户查看 Swarm 工作区
  Then 系统以卡片网格或列表形式展示所有任务，每个卡片显示:
    | 信息项 | 显示内容示例 |
    | 任务名称 | 实现用户认证模块 |
    | Agent 类型 | Claude Code (橙色图标) |
    | 状态 | [运行中] [已完成] [失败] [已停止] [待启动] |
    | 运行时间 | 01:23:45 |
    | 分支名 | swarm/s1/claude-1 |
    And 页面顶部显示汇总信息
```

**Spec Source**: `test/agent_swarm.feature` (A-3, A-4, A-5)

## Files to Modify/Create

- Create: `lib/swarm/widget/agent_status_card.dart`

## Steps

### Step 1: Create AgentStatusCard Widget
创建 `lib/swarm/widget/agent_status_card.dart`：

```dart
class AgentStatusCard extends StatelessWidget {
  final AgentTask task;
  final VoidCallback? onTap;
  final VoidCallback? onStop;
  final VoidCallback? onRemove;
  final VoidCallback? onViewDiff;

  const AgentStatusCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStop,
    this.onRemove,
    this.onViewDiff,
  });
}
```

### Step 2: Implement Status Display
- **Agent 类型颜色**: Claude Code = 橙色, Codex = 蓝色, Gemini = 紫色, 自定义 = 灰色
- **状态颜色**: 运行中 = 绿色脉冲动画, 已完成 = 蓝色, 失败 = 红色, 已停止 = 灰色, 待启动 = 灰色虚线
- **运行时间**: 格式化为 HH:MM:SS，实时更新（使用 `Timer.periodic` 每秒刷新）
- **输出预览**: 显示最近 3 行终端输出（从 `AgentInstance.outputController` 读取）
- **溢出处理**: 分支名和工作目录使用 `TextOverflow.ellipsis`

### Step 3: Implement Action Menu
- 点击卡片 → 展开详情（调用 `onTap`）
- 运行中任务显示「停止」按钮
- 已完成任务显示「查看 Diff」按钮
- 「...」菜单包含：移除、查看日志、在外部终端打开

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/widget/agent_status_card.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/agent_status_card.dart
```

## Success Criteria

- 卡片显示任务名、类型图标（颜色区分）、状态、运行时长、分支名、输出预览
- 状态颜色映射正确
- 操作按钮功能正确
- 运行时长实时更新
