# Task 009: SwarmTerminalPanel Widget Implementation

**depends-on**: task-008

## Description

实现基于 xterm.dart 的 SwarmTerminalPanel widget，支持实时输出显示和命令注入。

## Execution Context

**Task Number**: 9 of 25
**Phase**: Phase 2 — Enhanced Terminal
**Prerequisites**: Task 008 测试已编写（RED 状态）

## Files to Modify/Create

- Create: `lib/swarm/widget/swarm_terminal_panel.dart`

## Steps

### Step 1: Create SwarmTerminalPanel
创建 `lib/swarm/widget/swarm_terminal_panel.dart`：

```dart
class SwarmTerminalPanel extends StatefulWidget {
  final AgentInstance? agent;
  final bool interactive;
  final void Function(String)? onCommand;

  const SwarmTerminalPanel({
    super.key,
    this.agent,
    this.interactive = true,
    this.onCommand,
  });
}

class _SwarmTerminalPanelState extends State<SwarmTerminalPanel> {
  late final Terminal _terminal;
  late final TerminalController _terminalController;
  Process? _process;
  final _outputBuffer = <String>[];
  static const _maxLines = 5000;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(
      options: TerminalOptions(
        fontFamily: 'JetBrains Mono, monospace',
        fontSize: 13,
        theme: TerminalTheme(
          foreground: Colors.white,
          background: const Color(0xFF1E1E1E),
          cursor: Colors.green,
        ),
      ),
    );
    _terminalController = TerminalController();
    if (widget.agent != null) {
      _attachToAgent(widget.agent!);
    }
  }

  void _attachToAgent(AgentInstance agent) {
    _process = agent.process;
    agent.process.stdout.listen((data) {
      final line = utf8.decode(data, allowMalformed: true);
      _appendLine(line, isStderr: false);
    });
    agent.process.stderr.listen((data) {
      final line = utf8.decode(data, allowMalformed: true);
      _appendLine('\x1b[31m$line\x1b[0m', isStderr: true);
    });
    _terminal.onOutput = (data) {
      _process?.stdin.add(utf8.encode(data));
      _process?.stdin.flush();
    };
  }

  void _appendLine(String line, {required bool isStderr}) {
    if (_outputBuffer.length >= _maxLines) {
      _outputBuffer.removeRange(0, 1000);
    }
    _outputBuffer.add(line);
    _terminal.write('$line\n');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: TerminalView(
            _terminal,
            controller: _terminalController,
            autofocus: false,
          ),
        ),
        if (widget.interactive)
          _buildInputBar(),
      ],
    );
  }

  Widget _buildInputBar() {
    // 输入框 + 发送按钮
    // 调用 injectCommand 或 _terminal.onOutput
  }
}
```

### Step 2: Implement injectCommand Public Method
```dart
/// 向运行中的 agent 注入命令
Future<void> injectCommand(String command) async {
  if (_process == null) {
    return;
  }
  _process!.stdin.write('$command\n');
  await _process!.stdin.flush();
}
```

### Step 3: Verify
- 运行 `flutter test test/swarm/swarm_terminal_panel_test.dart`
- 确认测试通过（GREEN 状态）

## Verification Commands

```bash
# Run widget tests (should pass - GREEN state)
flutter test test/swarm/swarm_terminal_panel_test.dart
```

## Success Criteria

- `SwarmTerminalPanel` 使用 `TerminalView` (computer 包) 渲染终端
- 实时显示 stdout（白色）和 stderr（红色）
- 命令注入通过 stdin
- 输出超过 5000 行时自动截断旧内容
