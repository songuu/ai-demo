# Task 007: CodCliRunner.injectCommand Extension

**depends-on**: task-006

## Description

在现有 `CodCliRunner` 中新增 `injectCommand` 静态方法，供 SwarmOrchestrator 直接调用以向运行中的 agent 进程注入命令。

## Execution Context

**Task Number**: 7 of 25
**Phase**: Phase 2 — Enhanced Terminal
**Prerequisites**: Task 006 Worktree 管理页面已完成

## Files to Modify/Create

- Modify: `lib/codecore/service/cod_cli_runner.dart` — 添加 injectCommand 静态方法

## Steps

### Step 1: Add injectCommand Method
在 `CodCliRunner` 类中添加以下静态方法：

```dart
/// 向运行中的进程注入命令（通过 stdin）
///
/// 抛出异常如果进程不存在或不接受输入。
static Future<void> injectCommand(Process process, String command) async {
  if (process.killed || process.exitCode != null) {
    throw StateError('Cannot inject command: process has already exited');
  }
  process.stdin.write('$command\n');
  await process.stdin.flush();
}
```

### Step 2: Add to Public API
- 确认 `CodCliRunner.injectCommand` 是公开静态方法，可被 `SwarmOrchestrator` 调用
- 如需要，在 `lib/codecore/codecore.dart` 中导出该方法

### Step 3: Verify
- 运行 `flutter analyze lib/codecore/service/cod_cli_runner.dart`
- 确认无错误

## Verification Commands

```bash
flutter analyze lib/codecore/service/cod_cli_runner.dart
```

## Success Criteria

- `CodCliRunner.injectCommand` 方法存在且为 public static
- 方法正确处理 stdin write + flush
- 进程已退出时抛出明确的 StateError
