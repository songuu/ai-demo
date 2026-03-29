# Task 004: WorktreeService Implementation

**depends-on**: task-003

## Description

实现 WorktreeService——通过 subprocess 调用 git worktree 命令，管理 git worktree 的创建、列表、删除、清理操作。

## Execution Context

**Task Number**: 4 of 25
**Phase**: Phase 1 — Worktree Management
**Prerequisites**: Task 003 测试已编写（RED 状态）

## Files to Modify/Create

- Create: `lib/swarm/service/worktree_service.dart`
- Create: `lib/swarm/model/worktree_info.dart` — 临时 DTO（非 Hive 持久化）

## Steps

### Step 1: Create WorktreeInfo DTO
- 创建 `WorktreeInfo` 类（普通 Dart 类，非 HiveObject）用于存储 git worktree list 解析结果：
  - `path: String`
  - `branch: String`
  - `isMain: bool`
  - `commit: String?`

### Step 2: Implement WorktreeService
创建 `WorktreeService` 类，包含以下方法：

1. **`isGitRepository(String path) → Future<bool>`**
   - 执行 `git rev-parse --is-inside-work-tree`
   - 返回 exitCode == 0

2. **`isGitAvailable() → Future<bool>`**
   - 执行 `git --version`
   - 返回 exitCode == 0

3. **`getCurrentBranch(String repoPath) → Future<String?>`**
   - 执行 `git branch --show-current`
   - 返回 stdout 去掉换行后的字符串

4. **`listWorktrees(String repoPath) → Future<List<WorktreeInfo>>`**
   - 执行 `git worktree list --porcelain`
   - 解析输出格式（worktree 路径后紧跟 `branch <name>` 或 `bare`）
   - 返回 WorktreeInfo 列表

5. **`createWorktree(String repoPath, String branch, {String? worktreePath}) → Future<WorktreeInfo>`**
   - 先执行 `git branch <branch>` 创建分支（忽略"已存在"错误）
   - 如果分支创建失败（远程已存在），自动添加 `-local` 后缀重试，最多 5 次
   - 执行 `git worktree add <path> <branch>`
   - 如果 worktree 已存在，尝试 `git worktree remove --force` 后重试
   - 解析创建结果，返回 WorktreeInfo

6. **`removeWorktree(String repoPath, String path, {bool force = false}) → Future<void>`**
   - 执行 `git worktree remove <path>` 或 `git worktree remove --force <path>`
   - 忽略「目录不存在」错误（可能已被外部删除）

7. **`pruneWorktrees(String repoPath) → Future<void>`**
   - 执行 `git worktree prune`

8. **`createBranch(String repoPath, String name) → Future<String>`**
   - 执行 `git branch <name>`
   - 如果已存在，追加 `-local` 重试

### Step 3: Create WorktreeException
- 创建 `WorktreeException` 类，实现 `Exception`
- 包含字段：`command`、`exitCode`、`stderr`
- `toString()` 返回人类可读的错误信息

### Step 4: Run Tests
- 运行 `flutter test test/swarm/worktree_service_test.dart`
- 确认所有测试通过（GREEN 状态）

## Verification Commands

```bash
# Run tests (should pass - GREEN state)
flutter test test/swarm/worktree_service_test.dart
```

## Success Criteria

- WorktreeService 包含所有 8 个方法
- 所有 9 个单元测试通过
- 无 `dart:io` 之外的额外依赖
