# Task 019: MergeService Implementation

**depends-on**: task-018

## Description

实现 MergeService——通过 subprocess 调用 git diff/merge 命令，提供变更查看和合并操作。

## Execution Context

**Task Number**: 19 of 25
**Phase**: Phase 4 — Diff + Merge
**Prerequisites**: Task 018 集成测试已完成

## Files to Modify/Create

- Create: `lib/swarm/model/diff_file.dart` — Diff 文件 DTO
- Create: `lib/swarm/model/merge_conflict.dart` — 合并冲突 DTO
- Create: `lib/swarm/service/merge_service.dart`

## Steps

### Step 1: Create DiffFile Model
```dart
class DiffFile {
  final String path;
  final DiffFileStatus status; // added/modified/deleted
  final String? oldContent;
  final String? newContent;
  final List<DiffHunk> hunks;
}

class DiffHunk {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final String content;
}
```

### Step 2: Create MergeConflict Model
```dart
class MergeConflict {
  final String filePath;
  final String baseContent;
  final String oursContent; // 当前分支
  final String theirsContent; // agent 分支
}

enum ConflictResolution { ours, theirs, manual }
```

### Step 3: Implement MergeService
```dart
class MergeService {
  /// 获取 git diff
  Future<List<DiffFile>> getDiff(String repoPath, {String? branch});

  /// 获取 merge 状态
  Future<MergeStatus> getMergeStatus(String repoPath);

  /// 检测冲突文件
  Future<List<MergeConflict>> getConflicts(String repoPath);

  /// 解决单个冲突
  Future<void> resolveConflict(String repoPath, String filePath, ConflictResolution resolution);

  /// 执行 merge
  Future<MergeResult> merge(String repoPath, String fromBranch, String toBranch, {bool noFf = true});

  /// 执行 rebase
  Future<RebaseResult> rebase(String repoPath, String ontoBranch);
}
```

### Step 4: Verify
- 运行 `flutter analyze lib/swarm/service/merge_service.dart`

## Verification Commands

```bash
flutter analyze lib/swarm/service/merge_service.dart
```

## Success Criteria

- MergeService 包含所有 6 个方法
- git diff 输出正确解析
- 冲突检测正确识别 `<<<<<<< HEAD / ======= / >>>>>>>` 标记
