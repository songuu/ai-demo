import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';
import 'package:server_box/codecore/store/cod_config_store.dart';
import 'package:server_box/codecore/service/cod_cli_runner.dart';

/// CLI启动器服务
/// 支持启动新的Codex、Claude Code、Gemini CLI会话
class CodLauncher {
  CodLauncher._();

  /// 启动新的CLI会话
  static Future<LaunchResult> launchNewSession({
    required String provider,
    required String title,
    String? workingDirectory,
    List<String> additionalArgs = const [],
    Map<String, String> environment = const {},
  }) async {
    try {
      await CodSessionStore.ensureDirs();

      final cwd = await _resolveWorkingDirectory(workingDirectory);
      final command = CodSettingsStore.resolveCli(provider);
      final args = await _buildLaunchArgs(provider, cwd, additionalArgs);

      final session = await CodSessionStore.create(
        provider: provider,
        title: title,
        cwd: cwd,
        command: command,
        args: args,
      );

      final process = await CodCliRunner.run(
        session,
        onStdout: (line) => _onSessionOutput(session.id, 'stdout', line),
        onStderr: (line) => _onSessionOutput(session.id, 'stderr', line),
      );

      if (process != null) {
        return LaunchResult.success(
          session: session,
          process: process,
          message: '成功启动 $provider 会话: ${session.title}',
        );
      } else {
        return LaunchResult.failure(
          error: '无法启动 $provider CLI进程',
          session: session,
        );
      }
    } catch (e) {
      return LaunchResult.failure(
        error: '启动 $provider 会话失败: $e',
      );
    }
  }

  /// 启动Codex会话
  static Future<LaunchResult> launchCodex({
    String title = '新建 Codex 会话',
    String? workingDirectory,
    bool useFullAuto = false,
    bool bypassSandbox = false,
    String? model,
    String? sandboxPolicy,
    String? approvalPolicy,
  }) async {
    final additionalArgs = <String>[];

    if (useFullAuto) {
      additionalArgs.add('--full-auto');
    }

    if (bypassSandbox) {
      additionalArgs.add('--dangerously-bypass-approvals-and-sandbox');
    } else {
      // Codex sandbox policy: -s/--sandbox
      if (sandboxPolicy != null) {
        additionalArgs.addAll(['-s', sandboxPolicy]);
      }
      // Codex approval policy: -a/--ask-for-approval
      if (approvalPolicy != null) {
        additionalArgs.addAll(['-a', approvalPolicy]);
      }
    }

    if (model != null) {
      additionalArgs.addAll(['--model', model]);
    }

    return launchNewSession(
      provider: 'codex',
      title: title,
      workingDirectory: workingDirectory,
      additionalArgs: additionalArgs,
    );
  }

  /// 启动Claude Code会话
  static Future<LaunchResult> launchClaude({
    String title = '新建 Claude 会话',
    String? workingDirectory,
    String? model,
    bool enableMcp = true,
    String? mcpConfig,
    bool mcpStrictMode = false,
  }) async {
    final additionalArgs = <String>[];

    if (model != null) {
      additionalArgs.addAll(['--model', model]);
    }

    // MCP配置
    if (enableMcp) {
      if (mcpConfig != null) {
        additionalArgs.addAll(['--mcp-config', mcpConfig]);
      }
      if (mcpStrictMode) {
        additionalArgs.add('--mcp-strict');
      }
    }

    return launchNewSession(
      provider: 'claude',
      title: title,
      workingDirectory: workingDirectory,
      additionalArgs: additionalArgs,
    );
  }

  /// 启动Gemini CLI会话
  static Future<LaunchResult> launchGemini({
    String title = '新建 Gemini 会话',
    String? workingDirectory,
    String? model,
  }) async {
    final additionalArgs = <String>[];

    if (model != null) {
      additionalArgs.addAll(['--model', model]);
    }

    return launchNewSession(
      provider: 'gemini',
      title: title,
      workingDirectory: workingDirectory,
      additionalArgs: additionalArgs,
    );
  }

  /// 恢复已存在的CLI会话
  static Future<LaunchResult> resumeSession(CodSession session) async {
    try {
      // 确定工作目录：优先使用原始cwd，否则使用日志文件目录
      String resumeCwd = session.cwd;
      if (resumeCwd.isEmpty || !await Directory(resumeCwd).exists()) {
        // 回退到日志文件目录
        final logDir = Directory(session.logPath).parent.path;
        if (await Directory(logDir).exists()) {
          resumeCwd = logDir;
        } else {
          resumeCwd = Directory.current.path;
        }
      }

      // 构建恢复参数
      final args = await _buildResumeArgs(session);

      // 创建恢复会话实例
      final resumedSession = session.copyWith(
        args: args,
        cwd: resumeCwd,
        status: CodSessionStatus.pending,
        updatedAt: DateTime.now(),
      );

      await CodSessionStore.put(resumedSession);

      // 启动CLI进程
      final process = await CodCliRunner.run(
        resumedSession,
        onStdout: (line) => _onSessionOutput(session.id, 'stdout', line),
        onStderr: (line) => _onSessionOutput(session.id, 'stderr', line),
      );

      if (process != null) {
        return LaunchResult.success(
          session: resumedSession,
          process: process,
          message: '成功恢复 ${session.provider} 会话: ${session.title}',
        );
      } else {
        return LaunchResult.failure(
          error: '无法恢复 ${session.provider} CLI进程',
          session: resumedSession,
        );
      }
    } catch (e) {
      return LaunchResult.failure(
        error: '恢复 ${session.provider} 会话失败: $e',
        session: session,
      );
    }
  }

  /// 检查CLI工具是否可用
  static Future<AvailabilityCheck> checkCliAvailability(String provider) async {
    final command = CodSettingsStore.resolveCli(provider);

    try {
      List<String> checkArgs;
      switch (provider.toLowerCase()) {
        case 'claude':
          // Claude Code: 尝试 --version
          checkArgs = ['--version'];
          break;
        case 'codex':
          checkArgs = ['--version'];
          break;
        case 'gemini':
          checkArgs = ['--version'];
          break;
        default:
          checkArgs = ['--version'];
      }

      final result = await Process.run(
        command,
        checkArgs,
        runInShell: true,
        environment: getPatchedEnvironment(),
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final version = _extractVersion(output, provider);
        return AvailabilityCheck.available(
          provider: provider,
          command: command,
          version: version ?? output,
        );
      } else {
        // Claude Code 可能 --version 返回非0，尝试其他方式
        if (provider.toLowerCase() == 'claude') {
          try {
            // 尝试直接调用看是否存在
            final helpResult = await Process.run(
              command,
              ['--help'],
              runInShell: true,
              environment: getPatchedEnvironment(),
            );
            // Claude Code --help 可能返回 0 或 1
            if (helpResult.exitCode == 0 || helpResult.exitCode == 1) {
              // 尝试从 stderr 或 stdout 提取版本
              final output =
                  helpResult.stdout.toString() + helpResult.stderr.toString();
              final version = _extractVersion(output, provider);
              return AvailabilityCheck.available(
                provider: provider,
                command: command,
                version: version ?? '已安装',
              );
            }
          } catch (_) {}
        }

        return AvailabilityCheck.unavailable(
          provider: provider,
          command: command,
          error: 'CLI返回错误代码: ${result.exitCode}',
        );
      }
    } catch (e) {
      return AvailabilityCheck.unavailable(
        provider: provider,
        command: command,
        error: 'CLI不可用: $e',
      );
    }
  }

  static String? _extractVersion(String output, String provider) {
    // 匹配版本号格式
    final versionPattern = RegExp(r'(\d+\.\d+\.\d+)');
    final match = versionPattern.firstMatch(output);
    if (match != null) {
      return match.group(1);
    }

    // Claude Code 特殊格式
    if (provider.toLowerCase() == 'claude') {
      final claudePattern = RegExp(r'claude[-\s]?code[-\s]?v?(\d+\.\d+\.\d+)',
          caseSensitive: false);
      final claudeMatch = claudePattern.firstMatch(output);
      if (claudeMatch != null) {
        return claudeMatch.group(1);
      }
    }

    return null;
  }

  /// 获取补丁后的环境变量（用于CLI工具）
  static Map<String, String> getPatchedEnvironment({String? provider}) {
    final env = Map<String, String>.from(Platform.environment);

    // 如果指定了提供商，从配置加载环境变量
    if (provider != null) {
      final config = CodConfigStore().get(provider);
      if (config != null && config.enabled) {
        // 添加配置中的环境变量
        env.addAll(config.getFullEnvironment());
      }
    }

    final pathEntries = <String>[];

    if (Platform.isWindows) {
      // Windows: 添加常见的 npm 全局安装路径
      final userProfile = env['USERPROFILE'] ?? r'C:\Users\Administrator';
      pathEntries.addAll([
        '$userProfile\\AppData\\Roaming\\npm',
        '$userProfile\\AppData\\Local\\Programs\\Microsoft VS Code\\bin',
        '$userProfile\\.local\\bin',
        r'C:\Program Files\nodejs',
        r'C:\Program Files (x86)\nodejs',
        r'C:\Program Files',
        r'C:\Program Files (x86)',
        r'C:\Windows\System32',
      ]);
    } else {
      pathEntries.addAll([
        '/opt/homebrew/bin',
        '/usr/local/bin',
        '/usr/bin',
        '/bin',
        '${env['HOME']}/.local/bin',
        '${env['HOME']}/.nvm/versions/node/v20/bin',
      ]);
    }

    if (env['PATH'] != null) {
      pathEntries.add(env['PATH']!);
    }

    env['PATH'] = pathEntries.join(Platform.isWindows ? ';' : ':');
    return env;
  }

  /// 获取所有CLI工具的可用性状态
  static Future<Map<String, AvailabilityCheck>>
      checkAllCliAvailability() async {
    final providers = ['codex', 'claude', 'gemini'];
    final results = <String, AvailabilityCheck>{};

    await Future.wait(providers.map((provider) async {
      results[provider] = await checkCliAvailability(provider);
    }));

    return results;
  }

  /// 解析工作目录
  static Future<String> _resolveWorkingDirectory(
      String? workingDirectory) async {
    if (workingDirectory != null && workingDirectory.isNotEmpty) {
      final dir = Directory(workingDirectory);
      if (await dir.exists()) {
        return workingDirectory;
      }
    }
    return Directory.current.path;
  }

  /// 构建启动参数
  static Future<List<String>> _buildLaunchArgs(
    String provider,
    String cwd,
    List<String> additionalArgs,
  ) async {
    final args = <String>[];

    switch (provider.toLowerCase()) {
      case 'codex':
        // Codex: codex chat [--cwd <dir>] [options]
        args.add('chat');
        if (cwd.isNotEmpty && cwd != Directory.current.path) {
          args.addAll(['--cwd', cwd]);
        }
        break;
      case 'claude':
        // Claude Code: claude [options]
        // 工作目录通过 Process.start 的 workingDirectory 参数设置
        // 不需要添加 chat 子命令，Claude Code 直接启动即可
        break;
      case 'gemini':
        // Gemini: gemini chat [options]
        args.add('chat');
        if (cwd.isNotEmpty && cwd != Directory.current.path) {
          args.addAll(['--working-dir', cwd]);
        }
        break;
    }

    args.addAll(additionalArgs);
    return args;
  }

  /// 构建恢复参数
  /// Claude Code: --continue (在工作目录中恢复最近的会话)
  /// Codex: resume <id>
  /// Gemini: resume <id>
  static Future<List<String>> _buildResumeArgs(CodSession session) async {
    final args = <String>[];

    switch (session.provider.toLowerCase()) {
      case 'codex':
        // Codex: codex resume <session_id>
        final originalId = _extractOriginalSessionId(session.id, 'codex');
        if (originalId.isNotEmpty) {
          args.addAll(['resume', originalId]);
        } else {
          args.add('chat'); // 如果没有有效ID，启动新会话
        }
        break;
      case 'claude':
        // Claude Code: claude --continue
        // 在工作目录中恢复最近的会话，不需要指定会话ID
        args.add('--continue');
        break;
      case 'gemini':
        // Gemini: gemini resume <session_id>
        final originalId = _extractOriginalSessionId(session.id, 'gemini');
        if (originalId.isNotEmpty) {
          args.addAll(['resume', originalId]);
        } else {
          args.add('chat');
        }
        break;
      default:
        args.addAll(['resume', session.id]);
        break;
    }

    return args;
  }

  /// 从导入的会话ID中提取原始CLI会话ID
  static String _extractOriginalSessionId(String importedId, String provider) {
    final prefix = '${provider}_';
    if (!importedId.startsWith(prefix)) {
      return importedId;
    }

    // 移除前缀
    final id = importedId.substring(prefix.length);

    // 处理 Claude 项目格式: projectName_fileName
    // 我们需要提取实际可用于 resume 的 ID

    // 检查是否是时间戳格式的ID（我们自己创建的会话）
    if (RegExp(r'^\d{13}$').hasMatch(id)) {
      return id;
    }

    // 检查是否是 UUID 格式
    if (_looksLikeUuid(id)) {
      return id;
    }

    // 对于从 Claude projects 导入的会话，ID 格式是 projectName_fileName
    // 这种情况下，我们需要在工作目录中恢复，而不是用 ID
    // 返回空字符串表示应该使用 --continue 而不是 resume <id>
    return '';
  }

  /// 检查字符串是否看起来像UUID
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

  /// 处理会话输出
  static void _onSessionOutput(String sessionId, String type, String line) {
    if (kDebugMode) {
      debugPrint('[$sessionId][$type] $line');
    }
  }
}

/// 启动结果类
class LaunchResult {
  final bool success;
  final String message;
  final String? error;
  final CodSession? session;
  final Process? process;

  const LaunchResult._({
    required this.success,
    required this.message,
    this.error,
    this.session,
    this.process,
  });

  factory LaunchResult.success({
    required CodSession session,
    required Process process,
    required String message,
  }) {
    return LaunchResult._(
      success: true,
      message: message,
      session: session,
      process: process,
    );
  }

  factory LaunchResult.failure({
    required String error,
    CodSession? session,
  }) {
    return LaunchResult._(
      success: false,
      message: error,
      error: error,
      session: session,
    );
  }
}

/// CLI可用性检查结果
class AvailabilityCheck {
  final String provider;
  final String command;
  final bool available;
  final String? version;
  final String? error;

  const AvailabilityCheck._({
    required this.provider,
    required this.command,
    required this.available,
    this.version,
    this.error,
  });

  factory AvailabilityCheck.available({
    required String provider,
    required String command,
    required String version,
  }) {
    return AvailabilityCheck._(
      provider: provider,
      command: command,
      available: true,
      version: version,
    );
  }

  factory AvailabilityCheck.unavailable({
    required String provider,
    required String command,
    required String error,
  }) {
    return AvailabilityCheck._(
      provider: provider,
      command: command,
      available: false,
      error: error,
    );
  }

  String get status {
    if (available && version != null) {
      return '$command v$version';
    } else if (!available && error != null) {
      return '不可用: $error';
    } else {
      return '未知状态';
    }
  }
}
