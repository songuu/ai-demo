# Agent Swarm 实现最佳实践

## 一、代码规范

### 1.1 遵循项目惯例

- **Model**: 使用 `HiveObject` + `@HiveType(typeId: N)` + `copyWith()` + 不可变模式
- **Store**: `Hive Box` + `ValueListenable` 响应式更新，复用 `CodSessionStore` 模式
- **Service**: 纯 Dart 类，`static` 方法为主，`Future` 异步接口
- **View**: `StatefulWidget` + `ValueListenableBuilder`，复用现有三栏布局模式
- **Widget 拆分**: 每个 widget 单文件，200-400 行为佳

### 1.2 文件组织

```
lib/swarm/
  model/
    swarm_session.dart          # + .g.dart（代码生成）
    agent_task.dart
    agent_instance.dart         # 内存态，不需要 .g.dart
    worktree.dart
  store/
    swarm_session_store.dart
    worktree_store.dart
  service/
    worktree_service.dart
    swarm_orchestrator.dart
    merge_service.dart
    git_diff_parser.dart        # 解析 git diff 输出
  widget/
    swarm_terminal_panel.dart   # 基于 computer 包
    swarm_multi_terminal.dart   # 多终端布局
    diff_viewer.dart            # Diff 渲染
    merge_resolver.dart         # 冲突解决
    agent_status_card.dart      # 状态卡片
    new_swarm_dialog.dart
    new_agent_dialog.dart
    worktree_list_tile.dart
  view/
    swarm_tab.dart              # AppTab.swarm 入口
    swarm_dashboard.dart        # 三栏主布局
    worktree_manager_page.dart
```

## 二、安全考虑

### 2.1 Git Worktree 安全

- **路径验证**：worktree 路径必须在目标 git 仓库的 `.git/worktrees/` 目录下，禁止路径穿越
- **分支名过滤**：禁止分支名包含 `/..` 或绝对路径，防止意外的目录创建
- **权限检查**：创建 worktree 前检查目录写权限

### 2.2 进程安全

- **环境变量隔离**：不向 agent 进程传递敏感环境变量（如 API keys），除非用户明确配置
- **命令白名单**：`CodSettingsStore.resolveCli()` 限制只能启动预定义的 agent CLI
- **进程权限**：在 Windows 上使用 `ProcessStartMode.normal` 而非 `detached`，保证可管理性
- **超时控制**：所有 agent 进程设置 30 分钟默认超时，防止僵死

### 2.3 数据安全

- **日志脱敏**：日志文件中自动过滤可能的 API key 模式（`ANTHROPIC_API_KEY`、`OPENAI_API_KEY` 等）
- **项目路径验证**：用户选择的根项目路径必须是一个有效的 git 仓库（`git rev-parse --is-inside-work-tree`）

## 三、性能优化

### 3.1 终端输出流

```dart
// 使用有界 StreamController 防止内存膨胀
final _outputController = StreamController<String>.broadcast(
  onListen: () {},
  onCancel: () {},
);

// 在 SwarmOrchestrator 中限制缓冲
class BoundedOutputController {
  final _buffer = <String>[];
  static const _maxLines = 10000;

  void add(String line) {
    if (_buffer.length >= _maxLines) {
      _buffer.removeAt(0); // 丢弃最旧的行
    }
    _buffer.add(line);
  }

  List<String> getLines() => List.unmodifiable(_buffer);
}
```

### 3.2 日志文件轮转

```dart
class LogRotation {
  static const _maxFileSize = 50 * 1024 * 1024; // 50MB

  static Future<void> write(String path, String content) async {
    final file = File(path);
    if (await file.exists() && await file.length() > _maxFileSize) {
      // 轮转到 .1, .2, ...
      await file.rename('$path.${_timestamp()}.bak');
    }
    await file.writeAsString('$content\n', mode: FileMode.append);
  }
}
```

### 3.3 Diff 大文件处理

```dart
class DiffService {
  // 限制单次 diff 的文件数量
  Future<List<DiffFile>> getDiff(String repoPath, {int maxFiles = 100}) async {
    final result = await Process.run(
      'git', ['diff', '--name-only', '--diff-filter=ACM'],
      workingDirectory: repoPath,
    );
    final files = (result.stdout as String).trim().split('\n');
    if (files.length > maxFiles) {
      throw DiffException('Too many changed files (${files.length}), max $maxFiles');
    }
    // ...
  }
}
```

### 3.4 Flutter 渲染优化

- **终端 Widget 隔离**：每个 `SwarmTerminalPanel` 使用独立的 `RepaintBoundary`，避免整个 Swarm Dashboard 重绘
- **按需渲染**：Agent 输出使用 `StreamBuilder` 而非全量 `ValueNotifier`
- **懒加载 Diff**：Diff 内容在用户滚动到对应文件时才加载

## 四、错误处理

### 4.1 Git 错误处理模式

```dart
class WorktreeException implements Exception {
  final String command;
  final int? exitCode;
  final String? stderr;

  WorktreeException(this.command, {this.exitCode, this.stderr});

  @override
  String toString() {
    return 'WorktreeException: $command failed'
        '${exitCode != null ? ' (exit $exitCode)' : ''}'
        '${stderr != null ? '\n$stderr' : ''}';
  }
}
```

### 4.2 Agent 进程错误

| 场景 | 处理方式 |
|------|---------|
| 进程启动失败 | 更新 task status 为 `failed`，写入日志，通知 UI |
| 进程僵死（无输出 > 5min） | 发送 SIGTERM，30min 后发送 SIGKILL |
| 进程意外退出 | 监听 `exitCode`，更新状态，保留日志供调试 |
| stdin 写入失败 | 捕获异常，显示"命令注入失败"提示 |

### 4.3 UI 错误展示

- **Toast 通知**：操作失败时显示短提示（2-3 秒自动消失）
- **任务卡片状态**：失败的 agent 显示红色边框 + 错误图标 + 错误摘要
- **详细日志**：点击任务卡片的"查看日志"按钮，打开日志查看面板

## 五、可访问性

- 所有按钮有 `tooltip`
- 颜色不作为唯一的信息传达方式（配合图标 + 文字）
- 终端支持键盘导航（参考现有 `xterm.dart` 实现）
- 高对比度主题支持（复用现有 `dynamic_color` 方案）
