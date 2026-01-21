import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/service/cod_cli_runner.dart';
import 'package:server_box/codecore/service/cod_launcher.dart';

/// 内置终端组件
/// 支持运行CLI命令并显示输出
class CodEmbeddedTerminal extends StatefulWidget {
  final CodSession? session;
  final String? initialCommand;
  final String? workingDirectory;
  final VoidCallback? onClose;
  final Function(String)? onOutput;

  const CodEmbeddedTerminal({
    super.key,
    this.session,
    this.initialCommand,
    this.workingDirectory,
    this.onClose,
    this.onOutput,
  });

  @override
  State<CodEmbeddedTerminal> createState() => _CodEmbeddedTerminalState();
}

class _CodEmbeddedTerminalState extends State<CodEmbeddedTerminal> {
  final _outputLines = <TerminalLine>[];
  final _scrollController = ScrollController();
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  Process? _process;
  StreamSubscription? _stdoutSub;
  StreamSubscription? _stderrSub;

  bool _isRunning = false;
  String _currentDir = '';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _currentDir = widget.workingDirectory ?? 
                  widget.session?.cwd ?? 
                  Directory.current.path;
    
    _addSystemLine('Terminal initialized');
    _addSystemLine('Working directory: $_currentDir');
    
    // 自动执行命令
    if (widget.initialCommand != null) {
      _addSystemLine('Auto-starting: ${widget.initialCommand}');
      // 延迟执行以确保 UI 已渲染
      Future.delayed(const Duration(milliseconds: 500), () {
        _runCommand(widget.initialCommand);
      });
    } else if (widget.session != null) {
      final cmd = CodCliRunner.buildResumeCommand(widget.session!);
      _addSystemLine('Auto-resuming: $cmd');
      // 延迟执行以确保 UI 已渲染
      Future.delayed(const Duration(milliseconds: 500), () {
        _runCommand();
      });
    }
  }

  @override
  void dispose() {
    _cleanup();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _cleanup() {
    _stdoutSub?.cancel();
    _stderrSub?.cancel();
    _process?.kill();
  }

  void _addLine(String text, TerminalLineType type) {
    setState(() {
      _outputLines.add(TerminalLine(
        text: text,
        type: type,
        timestamp: DateTime.now(),
      ));
    });
    widget.onOutput?.call(text);
    _scrollToBottom();
  }

  void _addSystemLine(String text) => _addLine(text, TerminalLineType.system);
  void _addStdoutLine(String text) => _addLine(text, TerminalLineType.stdout);
  void _addStderrLine(String text) => _addLine(text, TerminalLineType.stderr);
  void _addInputLine(String text) => _addLine('> $text', TerminalLineType.input);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runCommand([String? command]) async {
    if (_isRunning) {
      _addSystemLine('Already running a command');
      return;
    }

    String cmd;
    List<String> args;

    if (command != null) {
      // 解析用户输入的命令
      final parts = _parseCommand(command);
      if (parts.isEmpty) return;
      cmd = parts[0];
      args = parts.length > 1 ? parts.sublist(1) : [];
    } else if (widget.initialCommand != null) {
      // 使用初始命令
      final parts = _parseCommand(widget.initialCommand!);
      if (parts.isEmpty) return;
      cmd = parts[0];
      args = parts.length > 1 ? parts.sublist(1) : [];
    } else if (widget.session != null) {
      // 使用会话命令 - 构建 resume 命令
      final fullCmd = CodCliRunner.buildResumeCommand(widget.session!);
      final parts = _parseCommand(fullCmd);
      if (parts.isEmpty) return;
      
      // 提取命令和参数（跳过可能的 cd 部分）
      if (fullCmd.contains('&&')) {
        // 如果有 cd 命令，提取实际的 CLI 命令
        final cmdPart = fullCmd.split('&&').last.trim();
        final cmdParts = _parseCommand(cmdPart);
        cmd = cmdParts[0];
        args = cmdParts.length > 1 ? cmdParts.sublist(1) : [];
      } else {
        cmd = parts[0];
        args = parts.length > 1 ? parts.sublist(1) : [];
      }
    } else {
      _addSystemLine('No command to run');
      return;
    }

    setState(() {
      _isRunning = true;
      _statusMessage = 'Running...';
    });

    _addInputLine('$cmd ${args.join(' ')}');

    try {
      // 对于交互式 CLI（如 Claude Code），需要特殊处理
      final isInteractive = cmd.toLowerCase().contains('claude') || 
                           cmd.toLowerCase().contains('codex') ||
                           cmd.toLowerCase().contains('gemini');
      
      _process = await Process.start(
        cmd,
        args,
        workingDirectory: _currentDir,
        environment: CodLauncher.getPatchedEnvironment(),
        runInShell: true,
        mode: isInteractive ? ProcessStartMode.normal : ProcessStartMode.normal,
      );

      // 监听标准输出（非阻塞）
      _addSystemLine('[DEBUG] Setting up stdout listener...');
      _stdoutSub = _process!.stdout
          .transform(utf8.decoder)
          .listen(
            (data) {
              _addSystemLine('[DEBUG] Received stdout data: ${data.length} bytes');
              // 按行分割并添加
              final lines = data.split('\n');
              for (final line in lines) {
                if (line.isNotEmpty) {
                  _addStdoutLine(line);
                }
              }
            },
            onError: (e) => _addStderrLine('Stdout error: $e'),
            onDone: () => _addSystemLine('[DEBUG] Stdout stream closed'),
          );

      // 监听标准错误（非阻塞）
      _addSystemLine('[DEBUG] Setting up stderr listener...');
      _stderrSub = _process!.stderr
          .transform(utf8.decoder)
          .listen(
            (data) {
              _addSystemLine('[DEBUG] Received stderr data: ${data.length} bytes');
              final lines = data.split('\n');
              for (final line in lines) {
                if (line.isNotEmpty) {
                  _addStderrLine(line);
                }
              }
            },
            onError: (e) => _addStderrLine('Stderr error: $e'),
            onDone: () => _addSystemLine('[DEBUG] Stderr stream closed'),
          );

      // 监听退出（但不阻塞）
      _process!.exitCode.then((exitCode) {
        _addSystemLine('Process exited with code: $exitCode');
        
        if (mounted) {
          setState(() {
            _isRunning = false;
            _statusMessage = exitCode == 0 ? 'Completed' : 'Failed';
          });
        }
      });
      
      // 对于交互式进程，显示提示和警告
      if (isInteractive) {
        _addSystemLine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        _addSystemLine('✓ Process started successfully!');
        _addSystemLine('');
        _addSystemLine('⚠️  IMPORTANT NOTE:');
        _addSystemLine('Interactive CLI tools like Claude Code work best in external terminals.');
        _addSystemLine('The embedded terminal has limitations on Windows:');
        _addSystemLine('  • stdin/stdout buffering issues');
        _addSystemLine('  • No TTY/PTY support');
        _addSystemLine('  • Response delays or no response');
        _addSystemLine('');
        _addSystemLine('📌 RECOMMENDED: Use the "Terminal" dropdown menu above to');
        _addSystemLine('   open in Windows Terminal, PowerShell, or cmd for full interaction.');
        _addSystemLine('');
        _addSystemLine('You can still try typing below, but if no response appears,');
        _addSystemLine('please use an external terminal instead.');
        _addSystemLine('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e) {
      _addStderrLine('Error: $e');
      setState(() {
        _isRunning = false;
        _statusMessage = 'Error';
      });
    }
  }

  List<String> _parseCommand(String command) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    var quoteChar = '';

    for (var i = 0; i < command.length; i++) {
      final char = command[i];
      
      if (inQuote) {
        if (char == quoteChar) {
          inQuote = false;
        } else {
          buffer.write(char);
        }
      } else if (char == '"' || char == "'") {
        inQuote = true;
        quoteChar = char;
      } else if (char == ' ') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  Future<void> _sendInput(String input) async {
    if (input.trim().isEmpty) return;
    
    if (_process != null && _isRunning) {
      // 进程正在运行，发送输入到 stdin
      _addInputLine(input);
      try {
        // 添加调试信息
        _addSystemLine('[DEBUG] Sending to stdin: $input');
        _process!.stdin.write('$input\n');
        await _process!.stdin.flush();
        _addSystemLine('[DEBUG] Sent successfully, waiting for response...');
        
        // 检查进程是否还活着
        _process!.exitCode.then((code) {
          _addSystemLine('[DEBUG] Process exited unexpectedly with code: $code');
        }).catchError((e) {
          // 进程还在运行
        });
      } catch (e) {
        _addStderrLine('Failed to send input: $e');
        _addSystemLine('Tip: The process may have stopped. Check if it\'s still running.');
      }
    } else {
      // 进程未运行，处理内置命令
      if (input.startsWith('cd ')) {
        final newDir = input.substring(3).trim();
        final dir = Directory(newDir.startsWith('/') || newDir.contains(':')
            ? newDir
            : '$_currentDir${Platform.pathSeparator}$newDir');
        if (await dir.exists()) {
          setState(() => _currentDir = dir.path);
          _addSystemLine('Changed directory to: $_currentDir');
        } else {
          _addStderrLine('Directory not found: $newDir');
        }
      } else if (input == 'clear' || input == 'cls') {
        setState(() => _outputLines.clear());
      } else if (input == 'pwd') {
        _addStdoutLine(_currentDir);
      } else if (input == 'help') {
        _addSystemLine('Available commands:');
        _addSystemLine('  cd <dir>  - Change directory');
        _addSystemLine('  pwd       - Print working directory');
        _addSystemLine('  clear/cls - Clear screen');
        _addSystemLine('  help      - Show this help');
        _addSystemLine('  <command> - Run any command');
      } else {
        // 运行命令
        _runCommand(input);
      }
    }

    _inputController.clear();
  }

  void _stopProcess() {
    if (_process != null && _isRunning) {
      _process!.kill();
      _addSystemLine('Process killed');
    }
  }

  void _copyOutput() {
    final text = _outputLines.map((l) => l.text).join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Output copied to clipboard')),
    );
  }

  void _copyCommand() {
    String? cmd;
    if (widget.session != null) {
      cmd = CodCliRunner.buildResumeCommand(widget.session!);
    } else if (widget.initialCommand != null) {
      cmd = widget.initialCommand;
    }
    
    if (cmd != null) {
      Clipboard.setData(ClipboardData(text: cmd));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Command copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        children: [
          // 标题栏
          _buildTitleBar(),
          // 输出区域
          Expanded(child: _buildOutputArea()),
          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // 窗口控制按钮
          _buildWindowButton(Colors.red, () {
            widget.onClose?.call();
          }),
          const SizedBox(width: 6),
          _buildWindowButton(Colors.yellow, () {}),
          const SizedBox(width: 6),
          _buildWindowButton(Colors.green, () {}),
          const SizedBox(width: 12),
          
          // 标题
          const Icon(Icons.terminal, color: Colors.grey, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.session?.title ?? 'Terminal',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // 状态
          if (_statusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: _isRunning ? Colors.green : Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // 操作按钮
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            color: Colors.grey,
            onPressed: _copyCommand,
            tooltip: 'Copy command',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 14),
            color: Colors.grey,
            onPressed: _copyOutput,
            tooltip: 'Copy output',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          if (_isRunning)
            IconButton(
              icon: const Icon(Icons.stop, size: 14),
              color: Colors.red,
              onPressed: _stopProcess,
              tooltip: 'Stop',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 14),
              color: Colors.green,
              onPressed: _runCommand,
              tooltip: 'Run',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Widget _buildWindowButton(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildOutputArea() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: _outputLines.length,
        itemBuilder: (context, index) {
          final line = _outputLines[index];
          return _buildOutputLine(line);
        },
      ),
    );
  }

  Widget _buildOutputLine(TerminalLine line) {
    Color textColor;
    FontWeight fontWeight = FontWeight.normal;
    
    switch (line.type) {
      case TerminalLineType.system:
        textColor = Colors.grey;
        break;
      case TerminalLineType.stdout:
        textColor = Colors.white;
        break;
      case TerminalLineType.stderr:
        textColor = Colors.red.shade300;
        break;
      case TerminalLineType.input:
        textColor = Colors.green;
        fontWeight = FontWeight.bold;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SelectableText(
        line.text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: textColor,
          fontWeight: fontWeight,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFF252525),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Row(
        children: [
          // 提示符
          Text(
            '\$ ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Colors.green.shade300,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: _isRunning 
                    ? 'Type your message and press Enter...' 
                    : 'Type command (or "help" for available commands)...',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              enabled: true, // 始终允许输入
              onSubmitted: _sendInput,
            ),
          ),
          // 发送按钮
          IconButton(
            icon: const Icon(Icons.send, size: 16),
            color: Colors.blue,
            onPressed: () => _sendInput(_inputController.text),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

/// 终端行类型
enum TerminalLineType {
  system,
  stdout,
  stderr,
  input,
}

/// 终端行数据
class TerminalLine {
  final String text;
  final TerminalLineType type;
  final DateTime timestamp;

  TerminalLine({
    required this.text,
    required this.type,
    required this.timestamp,
  });
}
