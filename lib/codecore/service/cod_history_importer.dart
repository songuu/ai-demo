import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:server_box/codecore/model/cod_session.dart';
import 'package:server_box/codecore/store/cod_session_store.dart';

/// CLI会话历史导入服务
/// 支持从本地CLI工具导入会话历史：Codex, Claude Code, Gemini CLI
///
/// Data locations (Windows):
/// - Claude sessions:
///   - Global history: C:\Users\<user>\.claude\history.jsonl
///   - Project sessions: C:\Users\<user>\.claude\projects\<project>\*.jsonl
/// - Codex sessions: C:\Users\<user>\.codex\sessions
/// - Gemini sessions: C:\Users\<user>\.gemini\tmp
///
/// Data locations (macOS/Linux):
/// - Claude sessions: ~/.claude/projects, ~/.claude/history.jsonl
/// - Codex sessions: ~/.codex/sessions
/// - Gemini sessions: ~/.gemini/tmp
class CodHistoryImporter {
  CodHistoryImporter._();

  /// 从所有支持的CLI工具导入会话历史
  static Future<ImportResult> importAllSessions() async {
    final result = ImportResult();

    // 并行导入不同CLI工具的会话
    final futures = await Future.wait([
      _importCodexSessions(),
      _importClaudeSessions(),
      _importGeminiSessions(),
    ]);

    for (final partialResult in futures) {
      result.merge(partialResult);
    }

    return result;
  }

  /// 只导入 Claude Code 会话
  static Future<ImportResult> importClaudeSessions() async {
    return _importClaudeSessions();
  }

  /// 导入Codex会话历史
  static Future<ImportResult> _importCodexSessions() async {
    final result = ImportResult();

    try {
      final homeDir = _getHomeDirectory();

      final possiblePaths = [
        p.join(homeDir, '.codex', 'sessions'),
        p.join(homeDir, '.codex', 'conversations'),
        p.join(homeDir, '.codex'),
      ];

      int totalScanned = 0;

      for (final basePath in possiblePaths) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.jsonl')) {
            totalScanned++;
            try {
              final sessions = await _parseCodexSessionFile(entity);
              for (final session in sessions) {
                final existing = CodSessionStore.byId(session.id);
                if (existing == null) {
                  await CodSessionStore.put(session);
                  result.imported++;
                }
              }
            } catch (e) {
              result.addError('Failed to parse Codex file ${entity.path}: $e');
            }
          }
        }
      }

      if (totalScanned == 0) {
        result.addMessage('No Codex session files found');
      } else {
        result.addMessage('Scanned $totalScanned Codex file(s)');
      }
    } catch (e) {
      result.addError('Failed to import Codex sessions: $e');
    }

    return result;
  }

  /// 导入Claude Code会话历史
  /// Claude Code 存储结构:
  /// 1. 全局历史文件: ~/.claude/history.jsonl
  /// 2. 项目会话文件: ~/.claude/projects/<project-folder>/*.jsonl
  ///
  /// 项目文件夹名称格式 (Windows): C--Users-Administrator--project -> C:\Users\Administrator\project
  /// 项目文件夹名称格式 (Unix): -Users-john-project -> /Users/john/project
  ///
  /// JSONL格式 (每行一个JSON对象):
  /// {"type":"user","sessionId":"uuid","cwd":"...","message":{"role":"user","content":"..."},"timestamp":"..."}
  /// {"type":"assistant","sessionId":"uuid","message":{"role":"assistant","content":[...]},"timestamp":"..."}
  static Future<ImportResult> _importClaudeSessions() async {
    final result = ImportResult();

    try {
      final homeDir = _getHomeDirectory();
      final claudeDir = Directory(p.join(homeDir, '.claude'));

      if (!await claudeDir.exists()) {
        result.addMessage('Claude directory not found: ${claudeDir.path}');
        return result;
      }

      int projectCount = 0;
      int sessionCount = 0;
      int fileCount = 0;

      // 1. 首先导入全局历史文件
      final globalHistoryFile = File(p.join(claudeDir.path, 'history.jsonl'));
      if (await globalHistoryFile.exists()) {
        result
            .addMessage('Found global history file: ${globalHistoryFile.path}');
        try {
          final sessions = await _parseClaudeGlobalHistory(globalHistoryFile);
          for (final session in sessions) {
            final existing = CodSessionStore.byId(session.id);
            if (existing == null) {
              await CodSessionStore.put(session);
              result.imported++;
              sessionCount++;
            }
          }
          result.addMessage(
              'Imported ${sessions.length} session(s) from global history');
        } catch (e) {
          result.addError('Failed to parse global history: $e');
        }
      }

      // 2. 导入项目文件夹中的会话
      final claudeProjectsDir = Directory(p.join(claudeDir.path, 'projects'));

      if (await claudeProjectsDir.exists()) {
        // 遍历项目文件夹
        await for (final projectEntity in claudeProjectsDir.list()) {
          if (projectEntity is Directory) {
            projectCount++;
            final projectName = p.basename(projectEntity.path);
            final workingDir = _parseClaudeProjectPath(projectName);

            // 扫描项目文件夹中的所有JSONL文件（包括子目录）
            await for (final fileEntity
                in projectEntity.list(recursive: true)) {
              if (fileEntity is File && fileEntity.path.endsWith('.jsonl')) {
                fileCount++;
                try {
                  final sessions = await _parseClaudeJsonlFile(
                    fileEntity,
                    projectName,
                    workingDir,
                  );
                  for (final session in sessions) {
                    final existing = CodSessionStore.byId(session.id);
                    if (existing == null) {
                      await CodSessionStore.put(session);
                      result.imported++;
                      sessionCount++;
                    }
                  }
                } catch (e) {
                  result.addError(
                      'Failed to parse Claude file ${fileEntity.path}: $e');
                }
              }
            }
          }
        }
      }

      if (projectCount == 0 && !await globalHistoryFile.exists()) {
        result.addMessage('No Claude session files found');
      } else {
        result.addMessage(
            'Scanned $projectCount project(s), $fileCount file(s), found $sessionCount session(s)');
      }
    } catch (e) {
      result.addError('Failed to import Claude sessions: $e');
    }

    return result;
  }

  /// 解析 Claude 全局历史文件
  /// history.jsonl 包含所有会话的历史记录
  static Future<List<CodSession>> _parseClaudeGlobalHistory(File file) async {
    final sessions = <CodSession>[];
    final content = await file.readAsString();
    final lines = content.split('\n');

    // 按 sessionId 分组消息
    final sessionData = <String, _ClaudeSessionData>{};

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      try {
        final json = jsonDecode(trimmedLine) as Map<String, dynamic>;

        // 提取会话ID
        final sessionId = json['sessionId']?.toString();
        if (sessionId == null || sessionId.isEmpty) continue;

        // 跳过文件历史快照等非对话消息
        final type = json['type']?.toString() ?? '';
        if (type == 'file-history-snapshot' ||
            type == 'command' ||
            type == 'summary' ||
            type.isEmpty) continue;

        // 跳过元消息（isMeta: true）和命令输出
        if (json['isMeta'] == true) continue;

        // 检查消息内容，跳过命令相关消息
        final message = json['message'] as Map<String, dynamic>?;
        if (message != null) {
          final content = message['content']?.toString() ?? '';
          if (content.contains('<command-name>') ||
              content.contains('<local-command-stdout>') ||
              content.contains('<local-command-stderr>')) {
            continue;
          }
        }

        // 提取工作目录
        final cwd = json['cwd']?.toString() ?? '';

        // 初始化会话数据
        sessionData.putIfAbsent(
            sessionId,
            () => _ClaudeSessionData(
                  sessionId: sessionId,
                  cwd: cwd,
                  version: json['version']?.toString(),
                  logPath: file.path,
                ));

        final data = sessionData[sessionId]!;

        // 如果当前消息有更具体的cwd，更新它
        if (cwd.isNotEmpty && data.cwd.isEmpty) {
          data.cwd = cwd;
        }

        // 解析时间戳
        final timestamp = _parseDateTime(json['timestamp']);
        if (data.firstTimestamp == null ||
            timestamp.isBefore(data.firstTimestamp!)) {
          data.firstTimestamp = timestamp;
        }
        if (data.lastTimestamp == null ||
            timestamp.isAfter(data.lastTimestamp!)) {
          data.lastTimestamp = timestamp;
        }

        // 提取消息内容作为标题
        if (data.title == null && (type == 'user' || type == 'human')) {
          final message = json['message'] as Map<String, dynamic>?;
          if (message != null) {
            final content = _extractMessageContent(message['content']);
            if (content != null &&
                content.isNotEmpty &&
                !json.containsKey('isMeta')) {
              data.title = content.length > 80
                  ? '${content.substring(0, 80)}...'
                  : content;
            }
          }
        }

        data.messageCount++;
        data.messages.add(json);
      } catch (_) {
        continue;
      }
    }

    // 为每个会话创建 CodSession
    for (final entry in sessionData.entries) {
      final sessionId = entry.key;
      final data = entry.value;

      if (data.messageCount == 0) continue;

      // 使用 sessionId 作为唯一ID
      final uniqueId = 'claude_global_$sessionId';

      final session = CodSession(
        id: uniqueId,
        provider: 'claude',
        title: data.title ?? 'Claude Session: ${_truncateId(sessionId)}',
        cwd: data.cwd,
        command: 'claude',
        args: ['--continue'], // Claude Code 使用 --continue 恢复会话
        logPath: data.logPath,
        createdAt: data.firstTimestamp ?? DateTime.now(),
        updatedAt: data.lastTimestamp ?? DateTime.now(),
        status: CodSessionStatus.completed,
        exitCode: 0,
      );

      sessions.add(session);
    }

    return sessions;
  }

  /// 解析 Claude Code JSONL 文件
  /// 每个JSONL文件通常包含一个或多个会话，由sessionId标识
  static Future<List<CodSession>> _parseClaudeJsonlFile(
    File file,
    String projectName,
    String workingDir,
  ) async {
    final sessions = <CodSession>[];
    final content = await file.readAsString();
    final lines = content.split('\n');
    final fileName = p.basenameWithoutExtension(file.path);

    // 按 sessionId 分组消息
    final sessionData = <String, _ClaudeSessionData>{};

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      try {
        final json = jsonDecode(trimmedLine) as Map<String, dynamic>;

        // 跳过文件历史快照等非对话消息
        final type = json['type']?.toString() ?? '';
        if (type == 'file-history-snapshot' ||
            type == 'command' ||
            type == 'summary' ||
            type.isEmpty) continue;

        // 跳过元消息（isMeta: true）和命令输出
        if (json['isMeta'] == true) continue;

        // 检查消息内容，跳过命令相关消息
        final message = json['message'] as Map<String, dynamic>?;
        if (message != null) {
          final content = message['content']?.toString() ?? '';
          if (content.contains('<command-name>') ||
              content.contains('<local-command-stdout>') ||
              content.contains('<local-command-stderr>')) {
            continue;
          }
        }

        // 提取会话ID，如果没有则使用文件名
        final sessionId = json['sessionId']?.toString() ?? fileName;

        // 提取工作目录（优先使用消息中的cwd）
        final msgCwd = json['cwd']?.toString() ?? '';
        final effectiveCwd = msgCwd.isNotEmpty ? msgCwd : workingDir;

        // 初始化会话数据
        sessionData.putIfAbsent(
            sessionId,
            () => _ClaudeSessionData(
                  sessionId: sessionId,
                  cwd: effectiveCwd,
                  version: json['version']?.toString(),
                  logPath: file.path,
                ));

        final data = sessionData[sessionId]!;

        // 更新cwd如果当前为空
        if (data.cwd.isEmpty && effectiveCwd.isNotEmpty) {
          data.cwd = effectiveCwd;
        }

        // 解析时间戳
        final timestamp = _parseDateTime(json['timestamp']);
        if (data.firstTimestamp == null ||
            timestamp.isBefore(data.firstTimestamp!)) {
          data.firstTimestamp = timestamp;
        }
        if (data.lastTimestamp == null ||
            timestamp.isAfter(data.lastTimestamp!)) {
          data.lastTimestamp = timestamp;
        }

        // 提取消息内容作为标题
        if (data.title == null && (type == 'user' || type == 'human')) {
          final message = json['message'] as Map<String, dynamic>?;
          if (message != null) {
            final content = _extractMessageContent(message['content']);
            if (content != null &&
                content.isNotEmpty &&
                !json.containsKey('isMeta')) {
              data.title = content.length > 80
                  ? '${content.substring(0, 80)}...'
                  : content;
            }
          }
        }

        data.messageCount++;
        data.messages.add(json);
      } catch (_) {
        continue;
      }
    }

    // 为每个会话创建 CodSession
    for (final entry in sessionData.entries) {
      final sessionId = entry.key;
      final data = entry.value;

      if (data.messageCount == 0) continue;

      // 使用项目名+sessionId作为唯一ID
      final uniqueId = 'claude_${projectName}_$sessionId';

      final session = CodSession(
        id: uniqueId,
        provider: 'claude',
        title: data.title ?? 'Claude: ${_formatProjectName(projectName)}',
        cwd: data.cwd.isNotEmpty ? data.cwd : workingDir,
        command: 'claude',
        args: ['--continue'], // Claude Code 使用 --continue 恢复会话
        logPath: file.path,
        createdAt: data.firstTimestamp ?? DateTime.now(),
        updatedAt: data.lastTimestamp ?? DateTime.now(),
        status: CodSessionStatus.completed,
        exitCode: 0,
      );

      sessions.add(session);
    }

    return sessions;
  }

  /// 提取消息内容
  static String? _extractMessageContent(dynamic content) {
    if (content == null) return null;
    if (content is String) {
      // 跳过命令消息
      if (content.contains('<command-name>')) return null;
      return content;
    }
    if (content is List) {
      final texts = <String>[];
      for (final item in content) {
        if (item is Map && item['type'] == 'text') {
          texts.add(item['text']?.toString() ?? '');
        } else if (item is String) {
          texts.add(item);
        }
      }
      return texts.isNotEmpty ? texts.join('\n') : null;
    }
    if (content is Map) {
      return content['text']?.toString();
    }
    return content.toString();
  }

  /// 格式化项目名称用于显示
  static String _formatProjectName(String projectName) {
    // 将 C--Users-Administrator--project 转换为可读格式
    final parts = projectName.split('--');
    if (parts.length > 1) {
      // 取最后一个部分作为项目名
      return parts.last.replaceAll('-', ' ');
    }
    return projectName.replaceAll('-', ' ');
  }

  /// 截断ID用于显示
  static String _truncateId(String id) {
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}...';
  }

  /// 解析Claude项目路径
  /// Windows: C--Users-Administrator--project -> C:\Users\Administrator\project
  /// Unix: -Users-john-project -> /Users/john/project
  static String _parseClaudeProjectPath(String projectName) {
    if (Platform.isWindows) {
      // Windows格式: C--Users-Administrator--project
      // 第一部分是驱动器号，然后是路径组件（用--分隔）

      final segments = <String>[];
      final chars = projectName.split('');
      var currentSegment = '';
      var i = 0;

      while (i < chars.length) {
        if (i < chars.length - 1 && chars[i] == '-' && chars[i + 1] == '-') {
          // 双横线表示路径分隔符
          if (currentSegment.isNotEmpty) {
            segments.add(currentSegment);
            currentSegment = '';
          }
          i += 2;
        } else {
          currentSegment += chars[i];
          i++;
        }
      }

      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment);
      }

      if (segments.isEmpty) return projectName;

      // 第一个段如果是单个字母，则是驱动器号
      if (segments[0].length == 1 &&
          RegExp(r'^[A-Za-z]$').hasMatch(segments[0])) {
        final drive = '${segments[0].toUpperCase()}:';
        if (segments.length > 1) {
          return '$drive\\${segments.sublist(1).join('\\')}';
        }
        return '$drive\\';
      }

      return segments.join('\\');
    } else {
      // Unix格式: -Users-john-project -> /Users/john/project
      final segments = <String>[];
      final chars = projectName.split('');
      var currentSegment = '';
      var i = 0;

      while (i < chars.length) {
        if (i < chars.length - 1 && chars[i] == '-' && chars[i + 1] == '-') {
          if (currentSegment.isNotEmpty) {
            segments.add(currentSegment);
            currentSegment = '';
          }
          i += 2;
        } else {
          currentSegment += chars[i];
          i++;
        }
      }

      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment);
      }

      if (segments.isEmpty) return '/$projectName';

      return '/${segments.join('/')}';
    }
  }

  /// 导入Gemini CLI会话历史
  static Future<ImportResult> _importGeminiSessions() async {
    final result = ImportResult();

    try {
      final homeDir = _getHomeDirectory();

      final possiblePaths = [
        p.join(homeDir, '.gemini', 'tmp'),
        p.join(homeDir, '.gemini', 'sessions'),
        p.join(homeDir, '.gemini'),
      ];

      int totalScanned = 0;

      for (final basePath in possiblePaths) {
        final dir = Directory(basePath);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list()) {
          if (entity is Directory) {
            try {
              final session = await _parseGeminiSessionDir(entity);
              if (session != null) {
                final existing = CodSessionStore.byId(session.id);
                if (existing == null) {
                  await CodSessionStore.put(session);
                  result.imported++;
                }
                totalScanned++;
              }
            } catch (e) {
              result.addError('Failed to parse Gemini dir ${entity.path}: $e');
            }
          } else if (entity is File &&
              (entity.path.endsWith('.jsonl') ||
                  entity.path.endsWith('.json'))) {
            try {
              final sessions = await _parseGeminiSessionFile(entity);
              for (final session in sessions) {
                final existing = CodSessionStore.byId(session.id);
                if (existing == null) {
                  await CodSessionStore.put(session);
                  result.imported++;
                }
                totalScanned++;
              }
            } catch (e) {
              result.addError('Failed to parse Gemini file ${entity.path}: $e');
            }
          }
        }
      }

      if (totalScanned == 0) {
        result.addMessage('No Gemini session files found');
      } else {
        result.addMessage('Scanned $totalScanned Gemini session(s)');
      }
    } catch (e) {
      result.addError('Failed to import Gemini sessions: $e');
    }

    return result;
  }

  /// 解析Codex JSONL会话文件
  static Future<List<CodSession>> _parseCodexSessionFile(File file) async {
    final sessions = <CodSession>[];

    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      final fileName = p.basenameWithoutExtension(file.path);

      DateTime? firstTimestamp;
      DateTime? lastTimestamp;
      String? sessionTitle;
      String? workingDir;

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        try {
          final json = jsonDecode(trimmedLine) as Map<String, dynamic>;

          final timestamp = _parseDateTime(
              json['timestamp'] ?? json['created_at'] ?? json['ts']);

          if (firstTimestamp == null || timestamp.isBefore(firstTimestamp)) {
            firstTimestamp = timestamp;
          }
          if (lastTimestamp == null || timestamp.isAfter(lastTimestamp)) {
            lastTimestamp = timestamp;
          }

          sessionTitle ??=
              json['title']?.toString() ?? json['name']?.toString();
          workingDir ??=
              json['cwd']?.toString() ?? json['working_directory']?.toString();
        } catch (_) {
          continue;
        }
      }

      if (firstTimestamp != null) {
        final uniqueId = 'codex_$fileName';

        final session = CodSession(
          id: uniqueId,
          provider: 'codex',
          title: sessionTitle ?? 'Codex: $fileName',
          cwd: workingDir ?? '',
          command: 'codex',
          args: ['chat'],
          logPath: file.path,
          createdAt: firstTimestamp,
          updatedAt: lastTimestamp ?? firstTimestamp,
          status: CodSessionStatus.completed,
        );

        sessions.add(session);
      }
    } catch (e) {
      throw Exception('Failed to read Codex file ${file.path}: $e');
    }

    return sessions;
  }

  /// 解析Gemini会话目录
  static Future<CodSession?> _parseGeminiSessionDir(Directory dir) async {
    try {
      final metaFile = File(p.join(dir.path, 'metadata.json'));
      final sessionFile = File(p.join(dir.path, 'session.json'));
      final conversationFile = File(p.join(dir.path, 'conversation.jsonl'));

      Map<String, dynamic>? metadata;

      if (await metaFile.exists()) {
        metadata =
            jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      } else if (await sessionFile.exists()) {
        metadata = jsonDecode(await sessionFile.readAsString())
            as Map<String, dynamic>;
      }

      final dirName = p.basename(dir.path);
      final uniqueId = 'gemini_$dirName';

      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      String title = 'Gemini: $dirName';
      String cwd = '';

      if (metadata != null) {
        createdAt =
            _parseDateTime(metadata['created_at'] ?? metadata['timestamp']);
        updatedAt = _parseDateTime(metadata['updated_at'] ??
            metadata['last_activity'] ??
            metadata['created_at']);
        title = metadata['title']?.toString() ??
            metadata['name']?.toString() ??
            title;
        cwd = metadata['cwd']?.toString() ??
            metadata['working_directory']?.toString() ??
            '';
      }

      if (await conversationFile.exists()) {
        final stat = await conversationFile.stat();
        updatedAt = stat.modified;
      }

      return CodSession(
        id: uniqueId,
        provider: 'gemini',
        title: title,
        cwd: cwd,
        command: 'gemini',
        args: ['chat'],
        logPath:
            conversationFile.existsSync() ? conversationFile.path : dir.path,
        createdAt: createdAt,
        updatedAt: updatedAt,
        status: CodSessionStatus.completed,
      );
    } catch (_) {
      return null;
    }
  }

  /// 解析Gemini会话文件
  static Future<List<CodSession>> _parseGeminiSessionFile(File file) async {
    final sessions = <CodSession>[];

    try {
      final content = await file.readAsString();
      final fileName = p.basenameWithoutExtension(file.path);

      if (file.path.endsWith('.json')) {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final session = CodSession(
          id: 'gemini_$fileName',
          provider: 'gemini',
          title: json['title']?.toString() ?? 'Gemini: $fileName',
          cwd: json['cwd']?.toString() ?? '',
          command: 'gemini',
          args: ['chat'],
          logPath: file.path,
          createdAt: _parseDateTime(json['created_at']),
          updatedAt: _parseDateTime(json['updated_at'] ?? json['created_at']),
          status: CodSessionStatus.completed,
        );
        sessions.add(session);
      } else {
        final lines = content.split('\n');
        DateTime? firstTimestamp;
        DateTime? lastTimestamp;

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            final ts = _parseDateTime(json['timestamp'] ?? json['ts']);

            firstTimestamp ??= ts;
            if (ts.isAfter(lastTimestamp ?? DateTime(1970))) {
              lastTimestamp = ts;
            }
          } catch (_) {
            continue;
          }
        }

        if (firstTimestamp != null) {
          final session = CodSession(
            id: 'gemini_$fileName',
            provider: 'gemini',
            title: 'Gemini: $fileName',
            cwd: '',
            command: 'gemini',
            args: ['chat'],
            logPath: file.path,
            createdAt: firstTimestamp,
            updatedAt: lastTimestamp ?? firstTimestamp,
            status: CodSessionStatus.completed,
          );
          sessions.add(session);
        }
      }
    } catch (e) {
      throw Exception('Failed to read Gemini file ${file.path}: $e');
    }

    return sessions;
  }

  /// 解析日期时间
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        try {
          return DateTime.parse(value.replaceAll(' ', 'T'));
        } catch (_) {
          return DateTime.now();
        }
      }
    }

    if (value is int) {
      try {
        final timestamp = value > 1000000000000 ? value : value * 1000;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }

    if (value is double) {
      try {
        final timestamp =
            (value > 1000000000000 ? value : value * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (_) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  /// 获取用户主目录
  static String _getHomeDirectory() {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          Platform.environment['HOMEDRIVE']! +
              Platform.environment['HOMEPATH']!;
    } else {
      return Platform.environment['HOME'] ?? '/tmp';
    }
  }
}

/// Claude会话数据辅助类
class _ClaudeSessionData {
  final String sessionId;
  String cwd;
  final String? version;
  final String logPath;
  DateTime? firstTimestamp;
  DateTime? lastTimestamp;
  String? title;
  int messageCount = 0;
  final List<Map<String, dynamic>> messages = [];

  _ClaudeSessionData({
    required this.sessionId,
    required this.cwd,
    this.version,
    required this.logPath,
  });
}

/// 导入结果类
class ImportResult {
  int imported = 0;
  final List<String> messages = [];
  final List<String> errors = [];

  void addMessage(String message) {
    messages.add(message);
  }

  void addError(String error) {
    errors.add(error);
  }

  void merge(ImportResult other) {
    imported += other.imported;
    messages.addAll(other.messages);
    errors.addAll(other.errors);
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasMessages => messages.isNotEmpty;

  String get summary {
    final parts = <String>[];

    if (imported > 0) {
      parts.add('成功导入 $imported 个会话');
    }

    if (errors.isNotEmpty) {
      parts.add('${errors.length} 个错误');
    }

    if (messages.isNotEmpty) {
      parts.add('${messages.length} 条消息');
    }

    return parts.isEmpty ? '无导入结果' : parts.join(', ');
  }
}
