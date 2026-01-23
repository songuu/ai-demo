/*
 * @Author: songyu
 * @Date: 2026-01-06 17:27:20
 * @LastEditTime: 2026-01-14 12:00:00
 * @LastEditor: AI Assistant
 */
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';
import 'package:server_box/codecore/service/cod_launcher.dart';

/// CLI运行器
/// 负责启动和管理CLI进程
class CodCliRunner {
  CodCliRunner._();

  /// 启动/恢复会话，输出实时写入日志文件。
  static Future<Process?> run(
    CodSession session, {
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  }) async {
    await CodSessionStore.ensureDirs();
    final logFile = File(session.logPath);
    await logFile.parent.create(recursive: true);

    // 解析命令和参数
    final resolvedCmd = CodSettingsStore.resolveCli(session.provider);
    final executable =
        session.command.isNotEmpty ? session.command : resolvedCmd;
    final args = session.args;

    // 解析工作目录
    String? workingDir = await _resolveWorkingDirectory(session, logFile);

    // 记录启动信息
    await _logStartInfo(logFile, session, executable, args, workingDir);

    Process process;
    try {
      process = await Process.start(
        executable,
        args,
        workingDirectory: workingDir,
        environment:
            CodLauncher.getPatchedEnvironment(provider: session.provider),
        runInShell: true,
      );
    } catch (e) {
      await logFile.writeAsString('[launcher error] $e\n',
          mode: FileMode.append);
      final failed = session.copyWith(
        status: CodSessionStatus.failed,
        exitCode: -1,
        updatedAt: DateTime.now(),
      );
      await CodSessionStore.put(failed);
      return null;
    }

    // 更新状态为运行中
    final running = session.copyWith(
      status: CodSessionStatus.running,
      updatedAt: DateTime.now(),
    );
    await CodSessionStore.put(running);

    // 监听输出
    _setupOutputListeners(process, logFile, onStdout, onStderr);

    // 监听退出
    _setupExitHandler(process, running, logFile);

    return process;
  }

  /// 解析工作目录
  static Future<String?> _resolveWorkingDirectory(
      CodSession session, File logFile) async {
    String? workingDir;

    if (session.cwd.isNotEmpty) {
      final dir = Directory(session.cwd);
      if (await dir.exists()) {
        workingDir = session.cwd;
      } else {
        // 尝试创建目录
        try {
          await dir.create(recursive: true);
          workingDir = session.cwd;
          await logFile.writeAsString(
            '[info] Created working directory: ${session.cwd}\n',
            mode: FileMode.append,
          );
        } catch (e) {
          await logFile.writeAsString(
            '[warning] Cannot create working directory: ${session.cwd}, error: $e\n',
            mode: FileMode.append,
          );
        }
      }
    }

    // 对于Claude Code，工作目录是必需的
    if (session.provider.toLowerCase() == 'claude') {
      if (workingDir == null || workingDir.isEmpty) {
        // 尝试从日志文件路径提取工作目录
        final logDir = logFile.parent.path;
        if (await Directory(logDir).exists()) {
          workingDir = logDir;
        } else {
          // 最后使用当前目录
          workingDir = Directory.current.path;
        }
        await logFile.writeAsString(
          '[warning] Claude Code requires a working directory. Using: $workingDir\n'
          '[info] If you see "No messages returned" error, make sure you are in the correct project directory.\n',
          mode: FileMode.append,
        );
      }
    }

    return workingDir;
  }

  /// 记录启动信息
  static Future<void> _logStartInfo(
    File logFile,
    CodSession session,
    String executable,
    List<String> args,
    String? workingDir,
  ) async {
    final startTime = DateTime.now().toIso8601String();
    final cmdLine = '$executable ${args.join(' ')}';

    await logFile.writeAsString(
      '''
=== Session Started ===
Time: $startTime
Provider: ${session.provider}
Title: ${session.title}
Command: $cmdLine
Working Directory: ${workingDir ?? '(default)'}
========================

''',
      mode: FileMode.append,
    );
  }

  /// 设置输出监听器
  static void _setupOutputListeners(
    Process process,
    File logFile,
    void Function(String line)? onStdout,
    void Function(String line)? onStderr,
  ) {
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      logFile.writeAsStringSync('$line\n', mode: FileMode.append);
      onStdout?.call(line);
    });

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      logFile.writeAsStringSync('[stderr] $line\n', mode: FileMode.append);
      onStderr?.call(line);
    });
  }

  /// 设置退出处理器
  static void _setupExitHandler(
    Process process,
    CodSession runningSession,
    File logFile,
  ) {
    process.exitCode.then((code) async {
      final endTime = DateTime.now().toIso8601String();
      final done = runningSession.copyWith(
        status:
            code == 0 ? CodSessionStatus.completed : CodSessionStatus.failed,
        exitCode: code,
        updatedAt: DateTime.now(),
      );
      await CodSessionStore.put(done);

      logFile.writeAsStringSync(
        '''

=== Session Ended ===
Time: $endTime
Exit Code: $code
Status: ${code == 0 ? 'Completed' : 'Failed'}
=====================
''',
        mode: FileMode.append,
      );
    });
  }

  /// 在外部终端中运行会话（用于交互式会话）
  static Future<bool> runInTerminal(
    CodSession session, {
    String? terminalApp,
  }) async {
    final command = buildResumeCommand(session);
    final workingDir =
        session.cwd.isNotEmpty ? session.cwd : Directory.current.path;

    try {
      if (Platform.isWindows) {
        return await _runInWindowsTerminal(command, workingDir, terminalApp);
      } else if (Platform.isMacOS) {
        return await _runInMacTerminal(command, workingDir, terminalApp);
      } else {
        return await _runInLinuxTerminal(command, workingDir, terminalApp);
      }
    } catch (e) {
      return false;
    }
  }

  /// Windows 终端支持
  static Future<bool> _runInWindowsTerminal(
      String command, String workingDir, String? terminalApp) async {
    final terminal = terminalApp?.toLowerCase() ?? 'cmd';

    switch (terminal) {
      case 'powershell':
        // 使用 PowerShell
        await Process.start(
          'powershell',
          ['-NoExit', '-Command', 'cd "$workingDir"; $command'],
          runInShell: true,
          mode: ProcessStartMode.detached,
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;

      case 'windows terminal':
      case 'wt':
        // 使用 Windows Terminal
        await Process.start(
          'wt',
          ['-d', workingDir, 'cmd', '/k', command],
          runInShell: true,
          mode: ProcessStartMode.detached,
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;

      case 'cmd':
      default:
        // 使用 cmd
        await Process.start(
          'cmd',
          ['/c', 'start', 'cmd', '/k', 'cd /d "$workingDir" && $command'],
          runInShell: true,
          mode: ProcessStartMode.detached,
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;
    }

    return true;
  }

  /// macOS 终端支持
  static Future<bool> _runInMacTerminal(
      String command, String workingDir, String? terminalApp) async {
    final terminal = terminalApp?.toLowerCase() ?? 'terminal';

    switch (terminal) {
      case 'iterm':
      case 'iterm2':
        // 使用 iTerm2
        await Process.run('osascript', [
          '-e',
          'tell application "iTerm" to create window with default profile command "cd \\"$workingDir\\" && $command"',
        ]);
        break;

      case 'warp':
        // 使用 Warp
        await Process.run('open',
            ['-a', 'Warp', '--args', '-e', 'cd "$workingDir" && $command']);
        break;

      case 'terminal':
      default:
        // 使用 Terminal.app
        await Process.run('osascript', [
          '-e',
          'tell application "Terminal" to do script "cd \\"$workingDir\\" && $command"',
        ]);
        break;
    }

    return true;
  }

  /// Linux 终端支持
  static Future<bool> _runInLinuxTerminal(
      String command, String workingDir, String? terminalApp) async {
    final terminal = terminalApp?.toLowerCase() ?? 'gnome-terminal';

    switch (terminal) {
      case 'konsole':
        await Process.start(
          'konsole',
          [
            '--workdir',
            workingDir,
            '-e',
            'bash',
            '-c',
            '$command; read -p "Press enter to close..."'
          ],
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;

      case 'xterm':
        await Process.start(
          'xterm',
          [
            '-e',
            'bash',
            '-c',
            'cd "$workingDir" && $command; read -p "Press enter to close..."'
          ],
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;

      case 'gnome-terminal':
      default:
        await Process.start(
          'gnome-terminal',
          [
            '--working-directory=$workingDir',
            '--',
            'bash',
            '-c',
            '$command; read -p "Press enter to close..."'
          ],
          environment: CodLauncher.getPatchedEnvironment(),
        );
        break;
    }

    return true;
  }

  /// 构建恢复会话的命令字符串
  /// 用于复制到剪贴板或在终端中执行
  static String buildResumeCommand(CodSession session) {
    final resolvedCmd = CodSettingsStore.resolveCli(session.provider);
    final executable =
        session.command.isNotEmpty ? session.command : resolvedCmd;

    // 根据提供商构建命令
    switch (session.provider.toLowerCase()) {
      case 'claude':
        // Claude Code: claude --continue
        return '$executable --continue';

      case 'codex':
        // Codex: codex resume <id> 或 codex chat
        final originalId = _extractOriginalId(session.id, 'codex');
        if (originalId.isNotEmpty) {
          return '$executable resume $originalId';
        }
        return '$executable chat';

      case 'gemini':
        // Gemini: gemini resume <id> 或 gemini chat
        final originalId = _extractOriginalId(session.id, 'gemini');
        if (originalId.isNotEmpty) {
          return '$executable resume $originalId';
        }
        return '$executable chat';

      default:
        return '$executable ${session.args.join(' ')}';
    }
  }

  /// 构建新会话命令
  static String buildNewSessionCommand(String provider, {String? workingDir}) {
    final executable = CodSettingsStore.resolveCli(provider);

    switch (provider.toLowerCase()) {
      case 'claude':
        return executable;
      case 'codex':
        if (workingDir != null) {
          return '$executable chat --cwd "$workingDir"';
        }
        return '$executable chat';
      case 'gemini':
        if (workingDir != null) {
          return '$executable chat --working-dir "$workingDir"';
        }
        return '$executable chat';
      default:
        return executable;
    }
  }

  /// 从导入的会话ID中提取原始ID
  static String _extractOriginalId(String importedId, String provider) {
    final prefix = '${provider}_';
    if (!importedId.startsWith(prefix)) {
      return importedId;
    }

    final id = importedId.substring(prefix.length);

    // 检查是否是UUID格式
    if (_looksLikeUuid(id)) {
      return id;
    }

    // 检查是否是时间戳格式
    if (RegExp(r'^\d{13}$').hasMatch(id)) {
      return id;
    }

    // 对于项目格式的ID，返回空字符串
    return '';
  }

  /// 检查是否是UUID格式
  static bool _looksLikeUuid(String str) {
    if (str.length == 36 && str.contains('-')) {
      return RegExp(
              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
          .hasMatch(str);
    }
    if (str.length == 32) {
      return RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(str);
    }
    return false;
  }

  /// 获取可用的终端列表
  static List<String> getAvailableTerminals() {
    if (Platform.isWindows) {
      return ['cmd', 'PowerShell', 'Windows Terminal'];
    } else if (Platform.isMacOS) {
      return ['Terminal', 'iTerm2', 'Warp'];
    } else {
      return ['gnome-terminal', 'xterm', 'konsole'];
    }
  }

  /// 获取命令的完整路径信息（用于调试）
  static Future<CommandInfo> getCommandInfo(CodSession session) async {
    final resolvedCmd = CodSettingsStore.resolveCli(session.provider);
    final executable =
        session.command.isNotEmpty ? session.command : resolvedCmd;
    final args = session.args;
    final workingDir =
        session.cwd.isNotEmpty ? session.cwd : Directory.current.path;

    // 尝试查找可执行文件的完整路径
    String? fullPath;
    try {
      ProcessResult result;
      if (Platform.isWindows) {
        result = await Process.run('where', [executable], runInShell: true);
      } else {
        result = await Process.run('which', [executable], runInShell: true);
      }
      if (result.exitCode == 0) {
        fullPath = result.stdout.toString().trim().split('\n').first;
      }
    } catch (_) {}

    return CommandInfo(
      executable: executable,
      fullPath: fullPath,
      args: args,
      workingDir: workingDir,
      commandLine: '$executable ${args.join(' ')}',
      resumeCommand: buildResumeCommand(session),
    );
  }
}

/// 命令信息类
class CommandInfo {
  final String executable;
  final String? fullPath;
  final List<String> args;
  final String workingDir;
  final String commandLine;
  final String resumeCommand;

  CommandInfo({
    required this.executable,
    this.fullPath,
    required this.args,
    required this.workingDir,
    required this.commandLine,
    required this.resumeCommand,
  });

  /// 格式化用于显示
  String toDisplayString() {
    final buffer = StringBuffer();
    buffer.writeln('命令: $commandLine');
    buffer.writeln('工作目录: $workingDir');
    if (fullPath != null) {
      buffer.writeln('完整路径: $fullPath');
    }
    buffer.writeln('恢复命令: $resumeCommand');
    return buffer.toString();
  }
}
