# Task 020: DiffViewer Widget Implementation

**depends-on**: task-019

## Description

实现内置 DiffViewer widget——以 unified diff 格式显示文件变更，支持语法高亮。

## Execution Context

**Task Number**: 20 of 25
**Phase**: Phase 4 — Diff + Merge
**Prerequisites**: Task 019 MergeService 已完成

## BDD Scenario

```gherkin
Scenario: 用户查看单个 Agent 任务的变更 Diff
  Given 一个 Agent 任务已完成，worktree 包含变更
  When 用户点击该任务卡片的"查看 Diff"按钮
  Then 系统打开内置 Diff Viewer
  And Diff 区域以 unified diff 格式显示
  And 增加行绿色背景，删除行红色背景
```

**Spec Source**: `test/agent_swarm.feature` (D-1, D-2)

## Files to Modify/Create

- Create: `lib/swarm/widget/diff_viewer.dart`

## Steps

### Step 1: Create DiffViewer
创建 `lib/swarm/widget/diff_viewer.dart`：

```dart
class DiffViewer extends StatelessWidget {
  final List<DiffFile> diffFiles;
  final void Function(String filePath)? onFileTap;

  const DiffViewer({
    super.key,
    required this.diffFiles,
    this.onFileTap,
  });
}
```

### Step 2: Implement Unified Diff Rendering
- 文件列表头部：显示变更统计（5 个文件修改, 3 个文件创建, 2 个文件删除）
- 每个文件展开为 `ExpansionTile`：
  - 文件头：路径（蓝色背景）
  - Hunk 内容：
    - 上下文行：默认背景
    - 增加行：`+` 绿色文字，浅绿色背景
    - 删除行：`-` 红色文字，浅红色背景
- 使用 `highlight` 包进行语法高亮（参考 `lib/data/res/highlight.dart` 的用法）
- 支持跳转到上一个/下一个变更

### Step 3: Implement Aggregate Diff View
- 创建 `AggregateDiffViewer`：显示多个 agent 的变更合并视图
- 按文件分组，同一文件的变更按 agent 分组显示（不同颜色边框区分）
- 冲突文件用红色边框高亮

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/widget/diff_viewer.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/widget/diff_viewer.dart
```

## Success Criteria

- DiffViewer 显示 unified diff 格式
- 颜色映射正确（增加=绿，删除=红）
- 语法高亮集成正确
- 二进制文件显示为「[二进制文件]」占位符
