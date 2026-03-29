import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:server_box/chat/model/chat_message.dart';
import 'package:server_box/chat/model/chat_provider.dart';
import 'package:server_box/chat/model/chat_stream_event.dart';

class ChatApiService {
  ChatApiService._();

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  /// Active cancel tokens keyed by requestId
  static final Map<String, CancelToken> _cancelTokens = {};

  /// Send a chat completion request, returning a Stream of delta events.
  static Stream<ChatStreamEvent> sendMessage({
    required ChatProvider provider,
    required String modelId,
    required List<ChatMessage> messages,
    double temperature = 0.7,
    int maxTokens = 4096,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
    bool webSearch = false,
    String? requestId,
  }) {
    final id = requestId ?? DateTime.now().millisecondsSinceEpoch.toString();

    switch (provider.type) {
      case 'openai':
      case 'openrouter':
      case 'custom':
        return _sendOpenAI(
          provider: provider,
          modelId: modelId,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          systemPrompt: systemPrompt,
          tools: tools,
          requestId: id,
        );
      case 'anthropic':
        return _sendAnthropic(
          provider: provider,
          modelId: modelId,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          systemPrompt: systemPrompt,
          tools: tools,
          requestId: id,
        );
      case 'google':
        return _sendGoogle(
          provider: provider,
          modelId: modelId,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          systemPrompt: systemPrompt,
          requestId: id,
        );
      default:
        return _sendOpenAI(
          provider: provider,
          modelId: modelId,
          messages: messages,
          temperature: temperature,
          maxTokens: maxTokens,
          systemPrompt: systemPrompt,
          tools: tools,
          requestId: id,
        );
    }
  }

  /// Cancel an ongoing request
  static void cancel(String requestId) {
    _cancelTokens[requestId]?.cancel('User cancelled');
    _cancelTokens.remove(requestId);
  }

  /// Normalize API host: trim and remove trailing slashes to avoid double slashes.
  static String _host(String host) =>
      host.trim().replaceAll(RegExp(r'/+$'), '');

  /// Extract a user-friendly error message from DioException.
  /// When using ResponseType.stream, response.data is ResponseBody - avoid toString().
  static String _dioErrorMessage(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return 'Request cancelled';
    }
    final data = e.response?.data;
    // Avoid ResponseBody.toString() which yields "Instance of 'ResponseBody'"
    if (data is String && data.isNotEmpty) {
      return data;
    }
    if (data is Map && data['error'] != null) {
      final err = data['error'];
      if (err is Map && err['message'] != null) {
        return err['message'].toString();
      }
      if (err is String) return err;
    }
    final status = e.response?.statusCode;
    final statusMsg = e.response?.statusMessage ?? '';
    if (status != null) {
      final friendly = _friendlyHttpError(status);
      if (friendly != null) return friendly;
      if (statusMsg.isNotEmpty) {
        return 'HTTP $status: $statusMsg';
      }
      return 'Request failed (HTTP $status)';
    }
    return e.message ?? 'Network error';
  }

  static String? _friendlyHttpError(int status) {
    return switch (status) {
      401 => 'Invalid or missing API key. Check Provider Settings.',
      403 => 'Access denied. Check your API key and permissions.',
      404 => 'API endpoint not found. Check: 1) API host (no trailing slash) 2) Model ID 3) Provider type in Provider Settings.',
      429 => 'Rate limit exceeded. Please try again later.',
      500 => 'Server error. Please try again later.',
      502 || 503 => 'Service temporarily unavailable.',
      _ => null,
    };
  }

  /// Format any error for user display. Handles DioException and filters
  /// "Instance of 'ResponseBody'" and similar non-helpful strings.
  static String formatError(dynamic e) {
    if (e is DioException) {
      return _dioErrorMessage(e);
    }
    final s = e?.toString() ?? '';
    // Filter out "Instance of 'X'" which is unhelpful to users
    if (s.contains("Instance of '")) {
      return 'Request failed. Please check your connection and API settings.';
    }
    return s.isNotEmpty ? s : 'Unknown error';
  }

  /// Test provider connection. Returns null on success, error message on failure.
  static Future<String?> testConnection(ChatProvider provider) async {
    try {
      switch (provider.type) {
        case 'openai':
        case 'openrouter':
        case 'custom':
          await _dio.get(
            '${_host(provider.apiHost)}/models',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${provider.apiKey}',
                ...provider.extraHeaders,
              },
            ),
          );
          break;
        case 'anthropic':
          await _dio.get(
            '${_host(provider.apiHost)}/v1/models',
            options: Options(
              headers: {
                'x-api-key': provider.apiKey,
                'anthropic-version': '2023-06-01',
                ...provider.extraHeaders,
              },
            ),
          );
          break;
        case 'google':
          await _dio.get(
            '${_host(provider.apiHost)}/v1beta/models',
            queryParameters: {'key': provider.apiKey, 'pageSize': 1},
            options: Options(headers: provider.extraHeaders),
          );
          break;
        default:
          await _dio.get(
            '${_host(provider.apiHost)}/models',
            options: Options(
              headers: {
                'Authorization': 'Bearer ${provider.apiKey}',
                ...provider.extraHeaders,
              },
            ),
          );
      }
      return null;
    } on DioException catch (e) {
      return _dioErrorMessage(e);
    } catch (e) {
      return formatError(e);
    }
  }

  /// Fetch available models from provider
  static Future<List<String>> fetchModels(ChatProvider provider) async {
    try {
      switch (provider.type) {
        case 'openai':
        case 'openrouter':
        case 'custom':
          final resp = await _dio.get(
            '${_host(provider.apiHost)}/models',
            options: Options(headers: {
              'Authorization': 'Bearer ${provider.apiKey}',
              ...provider.extraHeaders,
            }),
          );
          final data = resp.data as Map<String, dynamic>;
          final models = (data['data'] as List)
              .map((m) => m['id'] as String)
              .toList();
          models.sort();
          return models;
        case 'anthropic':
          // Anthropic doesn't have a models endpoint, return defaults
          return provider.models;
        case 'google':
          final resp = await _dio.get(
            '${_host(provider.apiHost)}/v1beta/models',
            queryParameters: {'key': provider.apiKey},
          );
          final data = resp.data as Map<String, dynamic>;
          final models = (data['models'] as List)
              .map((m) => (m['name'] as String).replaceFirst('models/', ''))
              .where((name) => name.contains('gemini'))
              .toList();
          models.sort();
          return models;
        default:
          return provider.models;
      }
    } catch (e) {
      return provider.models;
    }
  }

  // ==================== OpenAI Compatible ====================

  static Stream<ChatStreamEvent> _sendOpenAI({
    required ChatProvider provider,
    required String modelId,
    required List<ChatMessage> messages,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
    required String requestId,
  }) async* {
    final cancelToken = CancelToken();
    _cancelTokens[requestId] = cancelToken;

    try {
      final apiMessages = <Map<String, dynamic>>[];

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        apiMessages.add({'role': 'system', 'content': systemPrompt});
      }

      for (final msg in messages) {
        apiMessages.add({
          'role': msg.role,
          'content': msg.content.isNotEmpty ? msg.content : msg.displayContent,
        });
      }

      final body = <String, dynamic>{
        'model': modelId,
        'messages': apiMessages,
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': true,
      };

      if (tools != null && tools.isNotEmpty) {
        body['tools'] = tools;
      }

      final resp = await _dio.post(
        '${_host(provider.apiHost)}/chat/completions',
        data: body,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${provider.apiKey}',
            'Content-Type': 'application/json',
            ...provider.extraHeaders,
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
      );

      final stream = resp.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        // Keep the last potentially incomplete line
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed == 'data: [DONE]') {
            if (trimmed == 'data: [DONE]') {
              yield ChatStreamEvent.done();
            }
            continue;
          }
          if (!trimmed.startsWith('data: ')) continue;

          try {
            final json = jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta == null) continue;

            final content = delta['content'] as String?;
            if (content != null) {
              yield ChatStreamEvent.textDelta(content);
            }

            // Handle tool calls
            final toolCalls = delta['tool_calls'] as List?;
            if (toolCalls != null) {
              for (final tc in toolCalls) {
                yield ChatStreamEvent.toolUse(tc as Map<String, dynamic>);
              }
            }
          } catch (_) {
            // Skip malformed JSON lines
          }
        }
      }

      // Process any remaining buffer
      if (buffer.trim().isNotEmpty && buffer.trim() != 'data: [DONE]') {
        if (buffer.trim().startsWith('data: ')) {
          try {
            final json =
                jsonDecode(buffer.trim().substring(6)) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null) {
                yield ChatStreamEvent.textDelta(content);
              }
            }
          } catch (_) {}
        }
      }

      yield ChatStreamEvent.done();
    } on DioException catch (e) {
      yield ChatStreamEvent.error(_dioErrorMessage(e));
    } catch (e) {
      yield ChatStreamEvent.error(formatError(e));
    } finally {
      _cancelTokens.remove(requestId);
    }
  }

  // ==================== Anthropic ====================

  static Stream<ChatStreamEvent> _sendAnthropic({
    required ChatProvider provider,
    required String modelId,
    required List<ChatMessage> messages,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
    required String requestId,
  }) async* {
    final cancelToken = CancelToken();
    _cancelTokens[requestId] = cancelToken;

    try {
      final apiMessages = <Map<String, dynamic>>[];

      for (final msg in messages) {
        if (msg.role == 'system') continue; // handled separately
        apiMessages.add({
          'role': msg.role,
          'content': msg.content.isNotEmpty ? msg.content : msg.displayContent,
        });
      }

      final body = <String, dynamic>{
        'model': modelId,
        'messages': apiMessages,
        'max_tokens': maxTokens,
        'stream': true,
      };

      if (temperature > 0) {
        body['temperature'] = temperature;
      }

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['system'] = systemPrompt;
      }

      if (tools != null && tools.isNotEmpty) {
        body['tools'] = tools;
      }

      final resp = await _dio.post(
        '${_host(provider.apiHost)}/v1/messages',
        data: body,
        options: Options(
          headers: {
            'x-api-key': provider.apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
            ...provider.extraHeaders,
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
      );

      final stream = resp.data.stream as Stream<List<int>>;
      String buffer = '';
      bool inThinking = false;

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          if (trimmed.startsWith('event: ')) {
            continue; // Event type line, data follows
          }

          if (!trimmed.startsWith('data: ')) continue;

          try {
            final json =
                jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
            final type = json['type'] as String?;

            switch (type) {
              case 'content_block_start':
                final block = json['content_block'] as Map<String, dynamic>?;
                if (block?['type'] == 'thinking') {
                  inThinking = true;
                } else {
                  inThinking = false;
                }
                break;
              case 'content_block_delta':
                final delta = json['delta'] as Map<String, dynamic>?;
                if (delta == null) continue;

                final deltaType = delta['type'] as String?;
                if (deltaType == 'text_delta') {
                  final text = delta['text'] as String?;
                  if (text != null) {
                    if (inThinking) {
                      yield ChatStreamEvent.thinkingDelta(text);
                    } else {
                      yield ChatStreamEvent.textDelta(text);
                    }
                  }
                } else if (deltaType == 'thinking_delta') {
                  final thinking = delta['thinking'] as String?;
                  if (thinking != null) {
                    yield ChatStreamEvent.thinkingDelta(thinking);
                  }
                } else if (deltaType == 'input_json_delta') {
                  // Tool input streaming
                  yield ChatStreamEvent.toolUse({
                    'partial_json': delta['partial_json'],
                  });
                }
                break;
              case 'content_block_stop':
                inThinking = false;
                break;
              case 'message_stop':
                yield ChatStreamEvent.done();
                break;
              case 'message_delta':
                // Could contain stop_reason, usage info
                break;
              case 'error':
                final error = json['error'] as Map<String, dynamic>?;
                yield ChatStreamEvent.error(
                    error?['message'] as String? ?? 'Unknown Anthropic error');
                break;
            }
          } catch (_) {}
        }
      }

      yield ChatStreamEvent.done();
    } on DioException catch (e) {
      yield ChatStreamEvent.error(_dioErrorMessage(e));
    } catch (e) {
      yield ChatStreamEvent.error(formatError(e));
    } finally {
      _cancelTokens.remove(requestId);
    }
  }

  // ==================== Google Gemini ====================

  static Stream<ChatStreamEvent> _sendGoogle({
    required ChatProvider provider,
    required String modelId,
    required List<ChatMessage> messages,
    required double temperature,
    required int maxTokens,
    String? systemPrompt,
    required String requestId,
  }) async* {
    final cancelToken = CancelToken();
    _cancelTokens[requestId] = cancelToken;

    try {
      final contents = <Map<String, dynamic>>[];

      for (final msg in messages) {
        if (msg.role == 'system') continue;
        contents.add({
          'role': msg.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {
              'text':
                  msg.content.isNotEmpty ? msg.content : msg.displayContent,
            }
          ],
        });
      }

      final body = <String, dynamic>{
        'contents': contents,
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        },
      };

      if (systemPrompt != null && systemPrompt.isNotEmpty) {
        body['systemInstruction'] = {
          'parts': [
            {'text': systemPrompt}
          ]
        };
      }

      final resp = await _dio.post(
        '${_host(provider.apiHost)}/v1beta/models/$modelId:streamGenerateContent',
        data: body,
        queryParameters: {
          'key': provider.apiKey,
          'alt': 'sse',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            ...provider.extraHeaders,
          },
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
      );

      final stream = resp.data.stream as Stream<List<int>>;
      String buffer = '';

      await for (final chunk in stream) {
        buffer += utf8.decode(chunk);
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (!trimmed.startsWith('data: ')) continue;

          try {
            final json =
                jsonDecode(trimmed.substring(6)) as Map<String, dynamic>;
            final candidates = json['candidates'] as List?;
            if (candidates == null || candidates.isEmpty) continue;

            final content =
                candidates[0]['content'] as Map<String, dynamic>?;
            if (content == null) continue;

            final parts = content['parts'] as List?;
            if (parts == null) continue;

            for (final part in parts) {
              final text = (part as Map<String, dynamic>)['text'] as String?;
              if (text != null) {
                yield ChatStreamEvent.textDelta(text);
              }
            }
          } catch (_) {}
        }
      }

      yield ChatStreamEvent.done();
    } on DioException catch (e) {
      yield ChatStreamEvent.error(_dioErrorMessage(e));
    } catch (e) {
      yield ChatStreamEvent.error(formatError(e));
    } finally {
      _cancelTokens.remove(requestId);
    }
  }
}
