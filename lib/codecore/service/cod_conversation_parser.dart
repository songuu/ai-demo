import 'dart:convert';
import 'dart:io';

import 'package:server_box/codecore/model/cod_session.dart';

/// 对话消息模型
class ConversationMessage {
  final String id;
  final String role;           // user, assistant, system, tool
  final String content;
  final DateTime timestamp;
  final String? sessionId;
  final String? toolName;      // 如果是工具调用
  final String? toolInput;     // 工具输入
  final String? toolOutput;    // 工具输出
  final Map<String, dynamic>? metadata;

  ConversationMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.sessionId,
    this.toolName,
    this.toolInput,
    this.toolOutput,
    this.metadata,
  });

  bool get isUser => role == 'user' || role == 'human';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
  bool get isTool => role == 'tool' || toolName != null;

  /// 获取显示用的角色名称
  String get displayRole {
    switch (role) {
      case 'user':
      case 'human':
        return 'User';
      case 'assistant':
        return 'Assistant';
      case 'system':
        return 'System';
      case 'tool':
        return toolName ?? 'Tool';
      default:
        return role;
    }
  }

  /// 获取内容摘要（用于预览）
  String get contentSummary {
    if (content.isEmpty) return '(empty)';
    final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= 100) return cleaned;
    return '${cleaned.substring(0, 100)}...';
  }
}

/// 对话解析器
/// 支持解析 Claude Code, Codex, Gemini CLI 的对话日志
class CodConversationParser {
  CodConversationParser._();

  /// 从会话加载对话
  static Future<List<ConversationMessage>> loadConversation(CodSession session) async {
    final file = File(session.logPath);
    if (!await file.exists()) {
      return [];
    }

    switch (session.provider.toLowerCase()) {
      case 'claude':
        return _parseClaudeConversation(file);
      case 'codex':
        return _parseCodexConversation(file);
      case 'gemini':
        return _parseGeminiConversation(file);
      default:
        return _parseGenericLog(file);
    }
  }

  /// 解析Claude Code对话日志
  static Future<List<ConversationMessage>> _parseClaudeConversation(File file) async {
    final messages = <ConversationMessage>[];

    try {
      final content = await file.readAsString();
      final lines = content.split('\n');

      int msgIndex = 0;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        try {
          final json = jsonDecode(trimmed) as Map<String, dynamic>;
          
          // 跳过非对话消息
          final type = json['type']?.toString() ?? '';
          if (type == 'file-history-snapshot' || 
              type == 'command' || 
              type == 'summary' ||
              type.isEmpty) {
            continue;
          }

          // 跳过元消息（isMeta: true）
          if (json['isMeta'] == true) continue;

          // 解析角色
          String role;
          if (type == 'user' || type == 'human') {
            role = 'user';
          } else if (type == 'assistant') {
            role = 'assistant';
          } else if (type == 'tool_use' || type == 'tool_result') {
            role = 'tool';
          } else {
            role = type;
          }

          // 解析内容
          String messageContent = '';
          String? toolName;
          String? toolInput;
          String? toolOutput;

          final message = json['message'] as Map<String, dynamic>?;
          if (message != null) {
            final content = message['content'];
            messageContent = _extractContent(content);
            
            // 检查工具调用
            if (content is List) {
              for (final item in content) {
                if (item is Map) {
                  if (item['type'] == 'tool_use') {
                    toolName = item['name']?.toString();
                    toolInput = jsonEncode(item['input']);
                  } else if (item['type'] == 'tool_result') {
                    toolOutput = _extractContent(item['content']);
                  }
                }
              }
            }
          }

          // 跳过空消息
          if (messageContent.isEmpty && toolName == null) continue;

          // 解析时间戳
          final timestamp = _parseTimestamp(json['timestamp']);

          messages.add(ConversationMessage(
            id: 'msg_${msgIndex++}',
            role: role,
            content: messageContent,
            timestamp: timestamp,
            sessionId: json['sessionId']?.toString(),
            toolName: toolName,
            toolInput: toolInput,
            toolOutput: toolOutput,
            metadata: json,
          ));
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      // 如果不是JSONL格式，按普通日志解析
      return _parseGenericLog(file);
    }

    return messages;
  }

  /// 解析Codex对话日志
  static Future<List<ConversationMessage>> _parseCodexConversation(File file) async {
    final messages = <ConversationMessage>[];

    try {
      final content = await file.readAsString();
      final lines = content.split('\n');

      int msgIndex = 0;
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        try {
          final json = jsonDecode(trimmed) as Map<String, dynamic>;
          
          // Codex 格式可能不同，尝试多种字段
          final role = json['role']?.toString() ?? 
                       json['type']?.toString() ?? 
                       'unknown';
          
          final messageContent = _extractContent(json['content'] ?? json['message']);
          if (messageContent.isEmpty) continue;

          final timestamp = _parseTimestamp(
            json['timestamp'] ?? json['ts'] ?? json['created_at']
          );

          messages.add(ConversationMessage(
            id: 'msg_${msgIndex++}',
            role: role,
            content: messageContent,
            timestamp: timestamp,
            metadata: json,
          ));
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      return _parseGenericLog(file);
    }

    return messages;
  }

  /// 解析Gemini对话日志
  static Future<List<ConversationMessage>> _parseGeminiConversation(File file) async {
    final messages = <ConversationMessage>[];

    try {
      final content = await file.readAsString();
      
      // 尝试作为JSON数组解析
      if (content.trimLeft().startsWith('[')) {
        final jsonArray = jsonDecode(content) as List;
        int msgIndex = 0;
        for (final item in jsonArray) {
          if (item is Map<String, dynamic>) {
            final role = item['role']?.toString() ?? 'unknown';
            final messageContent = _extractContent(item['content'] ?? item['parts']);
            if (messageContent.isEmpty) continue;

            final timestamp = _parseTimestamp(item['timestamp']);

            messages.add(ConversationMessage(
              id: 'msg_${msgIndex++}',
              role: role,
              content: messageContent,
              timestamp: timestamp,
              metadata: item,
            ));
          }
        }
      } else {
        // 作为JSONL解析
        final lines = content.split('\n');
        int msgIndex = 0;
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          try {
            final json = jsonDecode(trimmed) as Map<String, dynamic>;
            
            final role = json['role']?.toString() ?? 'unknown';
            final messageContent = _extractContent(json['content'] ?? json['parts']);
            if (messageContent.isEmpty) continue;

            final timestamp = _parseTimestamp(json['timestamp']);

            messages.add(ConversationMessage(
              id: 'msg_${msgIndex++}',
              role: role,
              content: messageContent,
              timestamp: timestamp,
              metadata: json,
            ));
          } catch (_) {
            continue;
          }
        }
      }
    } catch (_) {
      return _parseGenericLog(file);
    }

    return messages;
  }

  /// 解析通用日志文件
  static Future<List<ConversationMessage>> _parseGenericLog(File file) async {
    final messages = <ConversationMessage>[];

    try {
      final content = await file.readAsLines();
      int msgIndex = 0;

      for (final line in content) {
        if (line.isEmpty) continue;

        // 跳过会话头尾标记
        if (line.startsWith('===') || line.startsWith('---')) continue;
        if (line.startsWith('Time:') || line.startsWith('Provider:') ||
            line.startsWith('Title:') || line.startsWith('Command:') ||
            line.startsWith('Working Directory:') || line.startsWith('Exit Code:') ||
            line.startsWith('Status:')) continue;

        // 判断角色
        String role = 'system';
        String content = line;

        if (line.startsWith('User →') || line.startsWith('User:') || line.startsWith('>')) {
          role = 'user';
          content = line.replaceFirst(RegExp(r'^(User →|User:|>)\s*'), '');
        } else if (line.startsWith('Claude →') || line.startsWith('Claude:') ||
                   line.startsWith('Assistant →') || line.startsWith('Assistant:')) {
          role = 'assistant';
          content = line.replaceFirst(RegExp(r'^(Claude →|Claude:|Assistant →|Assistant:)\s*'), '');
        } else if (line.startsWith('[stderr]')) {
          role = 'system';
          content = line.replaceFirst('[stderr] ', '');
        }

        if (content.isEmpty) continue;

        messages.add(ConversationMessage(
          id: 'msg_${msgIndex++}',
          role: role,
          content: content,
          timestamp: DateTime.now(),
        ));
      }
    } catch (_) {
      // 返回空列表
    }

    return messages;
  }

  /// 提取内容字符串
  static String _extractContent(dynamic content) {
    if (content == null) return '';
    
    if (content is String) {
      // 跳过命令消息和系统输出
      if (content.contains('<command-name>') || 
          content.contains('<local-command-stdout>') ||
          content.contains('<local-command-stderr>') ||
          content.contains('DO NOT respond to these messages')) {
        return '';
      }
      return content;
    }
    
    if (content is List) {
      final texts = <String>[];
      for (final item in content) {
        if (item is String) {
          texts.add(item);
        } else if (item is Map) {
          if (item['type'] == 'text') {
            texts.add(item['text']?.toString() ?? '');
          } else if (item['type'] == 'tool_use') {
            texts.add('[Tool: ${item['name']}]');
          } else if (item['type'] == 'tool_result') {
            final resultContent = _extractContent(item['content']);
            if (resultContent.isNotEmpty) {
              texts.add('[Tool Result]\n$resultContent');
            }
          }
        }
      }
      return texts.join('\n');
    }
    
    if (content is Map) {
      if (content['text'] != null) {
        return content['text'].toString();
      }
      // Gemini 的 parts 格式
      if (content['parts'] != null) {
        return _extractContent(content['parts']);
      }
    }
    
    return content.toString();
  }

  /// 解析时间戳
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    
    if (value is int) {
      final ts = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }
    
    if (value is double) {
      final ts = (value > 1000000000000 ? value : value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ts);
    }
    
    return DateTime.now();
  }

  /// 获取对话统计信息
  static ConversationStats getStats(List<ConversationMessage> messages) {
    int userCount = 0;
    int assistantCount = 0;
    int toolCount = 0;
    int totalChars = 0;

    for (final msg in messages) {
      if (msg.isUser) userCount++;
      else if (msg.isAssistant) assistantCount++;
      else if (msg.isTool) toolCount++;
      totalChars += msg.content.length;
    }

    return ConversationStats(
      totalMessages: messages.length,
      userMessages: userCount,
      assistantMessages: assistantCount,
      toolCalls: toolCount,
      totalCharacters: totalChars,
    );
  }
}

/// 对话统计信息
class ConversationStats {
  final int totalMessages;
  final int userMessages;
  final int assistantMessages;
  final int toolCalls;
  final int totalCharacters;

  ConversationStats({
    required this.totalMessages,
    required this.userMessages,
    required this.assistantMessages,
    required this.toolCalls,
    required this.totalCharacters,
  });

  String get summary {
    final parts = <String>[];
    parts.add('$totalMessages messages');
    if (userMessages > 0) parts.add('$userMessages user');
    if (assistantMessages > 0) parts.add('$assistantMessages assistant');
    if (toolCalls > 0) parts.add('$toolCalls tool calls');
    return parts.join(', ');
  }
}
