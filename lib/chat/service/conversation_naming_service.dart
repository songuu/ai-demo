import 'dart:async';

import 'package:server_box/chat/model/chat_provider.dart';
import 'package:server_box/chat/service/chat_api_service.dart';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/chat/model/chat_stream_event.dart';

/// Service that auto-generates short conversation titles by asking the model.
class ConversationNamingService {
  ConversationNamingService._();

  static const _systemPrompt =
      'Generate a concise title (max 20 chars) for this conversation. '
      'Reply ONLY with the title, nothing else.';

  static const _timeout = Duration(seconds: 10);

  /// Generate a short title for a conversation based on the first user message.
  ///
  /// Sends a request to the given [provider] / [modelId] and collects the
  /// streamed response. Falls back to the first 30 characters of
  /// [firstMessage] when the API call fails or times out.
  static Future<String> generateTitle(
    String firstMessage,
    ChatProvider provider,
    String modelId,
  ) async {
    try {
      final userMessage = ChatMessage(
        id: 'naming_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: '',
        role: 'user',
        content: firstMessage,
      );

      final requestId = 'naming_${DateTime.now().millisecondsSinceEpoch}';
      final stream = ChatApiService.sendMessage(
        provider: provider,
        modelId: modelId,
        messages: [userMessage],
        temperature: 0.3,
        maxTokens: 30,
        systemPrompt: _systemPrompt,
        requestId: requestId,
      );

      final buffer = StringBuffer();

      await for (final event in stream.timeout(_timeout)) {
        switch (event.type) {
          case ChatStreamEventType.textDelta:
            buffer.write(event.text ?? '');
            break;
          case ChatStreamEventType.done:
            break;
          case ChatStreamEventType.error:
            // On error fall through to fallback below.
            if (buffer.isEmpty) {
              return _fallback(firstMessage);
            }
            break;
          default:
            break;
        }
      }

      final title = buffer.toString().trim();
      if (title.isEmpty) return _fallback(firstMessage);

      // Strip surrounding quotes if the model wrapped the title.
      return _cleanTitle(title);
    } on TimeoutException {
      return _fallback(firstMessage);
    } catch (_) {
      return _fallback(firstMessage);
    }
  }

  /// Produce a fallback title from the raw user message.
  static String _fallback(String message) {
    final trimmed = message.trim();
    if (trimmed.length <= 30) return trimmed;
    return '${trimmed.substring(0, 30)}...';
  }

  /// Remove surrounding quotation marks that models sometimes add.
  static String _cleanTitle(String title) {
    var cleaned = title;
    // Remove leading/trailing double or single quotes
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }
    // Remove trailing period if present
    if (cleaned.endsWith('.')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    return cleaned.isEmpty ? _fallback(title) : cleaned;
  }
}
