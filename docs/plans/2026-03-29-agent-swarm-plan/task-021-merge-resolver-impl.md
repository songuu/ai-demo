# Task 021: MergeResolver Widget Implementation

**depends-on**: task-020

## Description

实现 MergeResolver widget——提供冲突解决操作界面。

## Execution Context

**Task Number**: 21 of 25
**Phase**: Phase 4 — Diff + Merge
**Prerequisites**: Task 020 DiffViewer 已完成

## BDD Scenario

```gherkin
Scenario: 合并时检测到文件冲突
  Given Agent A 和 Agent B 都修改了同一个文件
  And 用户尝试将变更合并到 main
  When 用户点击"合并到主分支"
  Then 系统显示冲突区域和解决选项
  And 提供: 保留主分支版本 / 保留 agent 版本 / 手动解决 / 取消合并
```

```gherkin
Scenario: Rebase 过程中发生冲突
  Given 用户对 Agent 分支执行 rebase 操作
  And rebase 过程中发生冲突
  Then 系统暂停 rebase，提供解决选项
```

**Spec Source**: `test/agent_swarm.feature` (D-6, D-4)

## Files to Modify/Create

- Create: `lib/swarm/widget/merge_resolver.dart`

## Steps

### Step 1: Create MergeResolver
创建 `lib/swarm/widget/merge_resolver.dart`：

```dart
class MergeResolver extends StatelessWidget {
  final MergeConflict conflict;
  final void Function(ConflictResolution)? onResolve;
  final VoidCallback? onCancel;

  const MergeResolver({
    super.key,
    required this.conflict,
    required this.onResolve,
    this.onCancel,
  });
}
```

### Step 2: Implement Conflict Display
- 显示三栏对比：ours（主分支）/ base / theirs（agent 分支）
- 冲突区域用红色背景高亮
- 三个操作按钮：采用 ours、采用 theirs、手动编辑

### Step 3: Implement Manual Resolution
- 手动编辑时打开内联编辑器
- 用户编辑完成后点击「标记为已解决」→ 调用 `MergeService.resolveConflict()`

### Step 4: Implement Batch Merge Panel
- 创建 `BatchMergePanel`：显示多个冲突文件列表
- 支持批量选择 resolution 策略
- 显示合并预览（变更文件数、预计冲突数）

### Step 5: Verify
- 运行 `flutter analyze lib/swarm/widget/merge_resolver.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/merge_resolver.dart
```

## Success Criteria

- MergeResolver 显示 ours/theirs/base 三栏对比
- 操作按钮正确调用 MergeService
- 手动解决流程完整
- 批量合并面板支持多文件处理
