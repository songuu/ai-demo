# Task 006: Worktree Manager Page UI

**depends-on**: task-005

## Description

实现 Worktree 管理页面 UI——显示所有 worktree 列表，提供创建、删除、查看状态等操作入口。

## Execution Context

**Task Number**: 6 of 25
**Phase**: Phase 1 — Worktree Management
**Prerequisites**: Task 005 WorktreeStore 已完成

## BDD Scenario

```gherkin
Scenario: 用户在 Swarm 面板中查看所有 worktree 列表
  Given 用户已打开一个包含 3 个任务的 Swarm 会话
  When 用户点击侧边栏中的"Worktrees"标签
  Then 系统显示 worktree 管理面板，列出所有 worktree
  And 每个 worktree 卡片提供操作按钮: 打开目录、查看状态、合并、删除
```

```gherkin
Scenario: 显示已失效的 worktree 记录
  Given 一个 worktree 目录已被手动删除
  But 数据库中仍保留该 worktree 的记录
  When 用户打开 Swarm 会话
  Then 系统检测到 worktree 目录不存在
  And 在 worktree 列表中显示为"失效"状态（红色标记）
```

**Spec Source**: `test/agent_swarm.feature` (C-5, C-5 edge-case)

## Files to Modify/Create

- Create: `lib/swarm/view/worktree_manager_page.dart`
- Create: `lib/swarm/widget/worktree_list_tile.dart`

## Steps

### Step 1: Create WorktreeListTile Widget
创建 `lib/swarm/widget/worktree_list_tile.dart`：

- 接收 `Worktree` 对象和回调函数作为参数
- 显示字段：分支名、路径、状态（活跃/空闲/失效）、创建时间
- 状态颜色映射：活跃=绿色、空闲=灰色、失效=红色
- 操作按钮（IconButton）：
  - 打开目录 → 调用 `open` 或文件管理器
  - 查看状态 → 显示 git status 摘要
  - 合并 → 打开合并面板（Phase 4）
  - 删除 → 显示确认对话框

### Step 2: Create WorktreeManagerPage Widget
创建 `lib/swarm/view/worktree_manager_page.dart`：

- 继承 `StatelessWidget` 或 `StatefulWidget`
- 使用 `WorktreeStore.listenable()` 监听数据变化
- 布局：
  - 顶部：「Worktrees」标题 + 刷新按钮 + 添加按钮
  - 主体：`ListView.builder` 渲染 `WorktreeListTile`
  - 空状态：显示「暂无 worktree」提示
  - 失效检测：在 `initState` 中调用 `WorktreeService.listWorktrees()` 对比，标记失效的 worktree

### Step 3: Integrate with Existing UI
- 确保 WorktreeManagerPage 可被主应用访问（路由或直接嵌入）
- 响应式布局：支持窄屏和宽屏

## Verification Commands

```bash
flutter analyze lib/swarm/view/worktree_manager_page.dart lib/swarm/widget/worktree_list_tile.dart
```

## Success Criteria

- WorktreeManagerPage 显示所有 worktree 列表
- 每个 tile 显示分支名、路径、状态、可用操作
- 失效 worktree 显示红色标记
- 空状态有友好提示
