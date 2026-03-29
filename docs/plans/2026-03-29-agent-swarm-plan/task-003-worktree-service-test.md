# Task 003: WorktreeService Unit Tests

**depends-on**: task-002

## Description

为 WorktreeService 编写 TDD 红色测试，验证 git worktree 操作的核心行为。

## Execution Context

**Task Number**: 3 of 25
**Phase**: Phase 1 — Worktree Management
**Prerequisites**: Task 002 目录结构和 Hive 注册已完成

## BDD Scenario

```gherkin
Scenario: 系统自动为每个 Agent 创建独立的 worktree 分支
  Given 用户已打开一个 Swarm 会话，关联项目位于 "E:/project/flutter_server_box"
  And 当前 main 分支没有同名 worktree
  When 用户添加第一个 Claude Code 任务
  Then 系统自动执行:
    """
    git worktree list  # 检查现有 worktree
    git branch swarm/s1/claude-1  # 在当前分支创建新分支
    git worktree add .git/worktrees/swarm-s1-claude-1 swarm/s1/claude-1
    """
```

```gherkin
Scenario: worktree 分支命名冲突时自动重试
  Given 用户已添加一个 worktree 分支名为 `swarm/s1/claude-1`
  When 用户再次添加一个 Claude Code 任务
  Then 系统检测到分支名已存在
  And 自动将新分支名递增为 `swarm/s1/claude-2`
  And 如果 5 次尝试后仍失败，显示错误
```

```gherkin
Scenario: Git worktree 创建失败 - 分支已存在
  Given 用户尝试添加一个新的 Agent 任务
  And 系统尝试创建分支 `swarm/s1/claude-1`
  But 该分支在远程仓库已存在（且不在本地）
  When 系统执行 `git branch swarm/s1/claude-1`
  Then 系统自动重命名本地分支为 `swarm/s1/claude-1-local`
```

**Spec Source**: `test/agent_swarm.feature` (C-1, C-2, F-1)

## Files to Modify/Create

- Create: `test/swarm/worktree_service_test.dart`

## Steps

### Step 1: Create Test File
- 创建 `test/swarm/worktree_service_test.dart`
- 使用 `package:test` 框架
- Mock `dart:io` Process 类（使用自定义 mock 或 `process_run` 包）
- Mock 应覆盖：
  - `git worktree list --porcelain` — 返回空列表/有 worktree 列表
  - `git branch <name>` — 成功/分支已存在
  - `git worktree add <path> <branch>` — 成功/worktree 已存在
  - `git worktree remove --force <path>` — 成功
  - `git worktree prune` — 成功
  - `git branch --show-current` — 返回当前分支名
  - `git rev-parse --is-inside-work-tree` — 验证是 git 仓库

### Step 2: Write Test Cases (Red - Must Fail)
编写以下测试用例，验证 WorktreeService 应有的行为：

1. **`isGitRepository_returnsTrue_forValidRepo`**: 给定包含 .git 目录的路径，`isGitRepository()` 返回 true
2. **`isGitRepository_returnsFalse_forNonRepo`**: 给定非 git 仓库路径，返回 false
3. **`createWorktree_success_createsWorktreeAndBranch`**: 给定有效仓库路径和分支名，调用 git branch 和 git worktree add，返回 Worktree 对象
4. **`createWorktree_conflict_retriesWithIncrementedName`**: 分支名冲突时，自动尝试 `claude-2`、`claude-3`，最多 5 次
5. **`createWorktree_conflictAllFailed_throwsWorktreeException`**: 5 次尝试全部失败后抛出异常
6. **`listWorktrees_parsesPorcelainOutput`**: 解析 `git worktree list --porcelain` 输出，返回 List<WorktreeInfo>
7. **`removeWorktree_force_succeeds`**: `git worktree remove --force` 成功执行
8. **`pruneWorktrees_succeeds`**: `git worktree prune` 成功执行
9. **`getCurrentBranch_returnsBranchName`**: `git branch --show-current` 返回当前分支

### Step 3: Verify Tests Fail
- 运行 `flutter test test/swarm/worktree_service_test.dart`
- 确认所有测试因「WorktreeService 不存在」或「方法不存在」而失败（RED 状态）

## Verification Commands

```bash
# Run tests (should fail - RED state)
flutter test test/swarm/worktree_service_test.dart
```

## Success Criteria

- 所有 9 个测试用例已编写
- 测试因实现缺失而失败（RED）
- Mock 正确隔离了 dart:io Process 依赖
