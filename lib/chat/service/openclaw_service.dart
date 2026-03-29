import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';

import 'package:server_box/chat/model/chat_stream_event.dart';
import 'package:server_box/chat/store/openclaw_store.dart';

/// Connection states for the OpenClaw WebSocket gateway.
enum OpenClawStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// OpenClaw WebSocket Gateway service.
///
/// Manages a persistent WebSocket connection to the OpenClaw gateway
/// (typically a local `acpx` process), provides message streaming, and
/// exposes helper methods for the ClawHub skill marketplace.
class OpenClawService {
  OpenClawService._();

  static WebSocketChannel? _channel;
  static StreamSubscription? _channelSubscription;

  /// Current connection status exposed as a listenable.
  static final connectionStatus =
      ValueNotifier<OpenClawStatus>(OpenClawStatus.disconnected);

  /// Active response stream controllers keyed by request ID.
  static final Map<String, StreamController<ChatStreamEvent>>
      _responseControllers = {};

  /// Counter for internal request IDs.
  static int _requestId = 0;

  /// Reconnection state.
  static int _reconnectAttempts = 0;
  static Timer? _reconnectTimer;
  static String? _lastUrl;

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static const _clawHubBaseUrl = 'https://clawhub.openclaw.ai/api';

  // ---------------------------------------------------------------------------
  // Connection management
  // ---------------------------------------------------------------------------

  /// Connect to the OpenClaw WebSocket gateway.
  ///
  /// Defaults to `ws://127.0.0.1:18789` which is the standard `acpx` local
  /// gateway address. The URL is also persisted via [OpenClawStore] when a
  /// saved config exists.
  static Future<void> connect({String url = 'ws://127.0.0.1:18789'}) async {
    if (connectionStatus.value == OpenClawStatus.connecting) return;

    connectionStatus.value = OpenClawStatus.connecting;
    _lastUrl = url;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();

    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);

      // Wait for the connection to be ready.
      await _channel!.ready;

      connectionStatus.value = OpenClawStatus.connected;

      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          connectionStatus.value = OpenClawStatus.error;
          _scheduleReconnect();
        },
        onDone: () {
          connectionStatus.value = OpenClawStatus.disconnected;
          _channel = null;
          _channelSubscription = null;
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      connectionStatus.value = OpenClawStatus.error;
      _channel = null;
      _channelSubscription = null;
      _scheduleReconnect();
    }
  }

  /// Disconnect from the gateway and stop any reconnection attempts.
  static Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _lastUrl = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    await _channel?.sink.close();
    _channel = null;

    // Fail any outstanding response streams.
    for (final controller in _responseControllers.values) {
      controller.add(ChatStreamEvent.error('Disconnected'));
      controller.add(ChatStreamEvent.done());
      controller.close();
    }
    _responseControllers.clear();

    connectionStatus.value = OpenClawStatus.disconnected;
  }

  // ---------------------------------------------------------------------------
  // Messaging
  // ---------------------------------------------------------------------------

  /// Send a chat message through the WebSocket and return a [Stream] of
  /// [ChatStreamEvent]s representing the incremental response.
  ///
  /// An optional [sessionId] can be supplied to continue a previous
  /// conversation on the gateway side.
  static Stream<ChatStreamEvent> sendMessage({
    required String content,
    String? sessionId,
  }) {
    if (_channel == null ||
        connectionStatus.value != OpenClawStatus.connected) {
      return Stream.fromIterable([
        ChatStreamEvent.error('Not connected to OpenClaw gateway'),
        ChatStreamEvent.done(),
      ]);
    }

    final id = (++_requestId).toString();
    final controller = StreamController<ChatStreamEvent>();
    _responseControllers[id] = controller;

    final payload = jsonEncode({
      'type': 'message',
      'id': id,
      'content': content,
      if (sessionId != null) 'sessionId': sessionId,
    });

    _channel!.sink.add(payload);

    // Safety timeout – if no `done` arrives in 5 minutes, close the stream.
    Future.delayed(const Duration(minutes: 5), () {
      if (_responseControllers.containsKey(id)) {
        controller.add(ChatStreamEvent.error('Response timed out'));
        controller.add(ChatStreamEvent.done());
        controller.close();
        _responseControllers.remove(id);
      }
    });

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Gateway status
  // ---------------------------------------------------------------------------

  /// Query the gateway for its current status (connected agents, sessions,
  /// etc.).
  ///
  /// Returns the parsed JSON map from the gateway's status response, or an
  /// error map on failure.
  static Future<Map<String, dynamic>> getStatus() async {
    if (_channel == null ||
        connectionStatus.value != OpenClawStatus.connected) {
      return {'error': 'Not connected'};
    }

    final id = (++_requestId).toString();
    final completer = Completer<Map<String, dynamic>>();

    // We reuse the response controller mechanism but collect into a single
    // map instead of streaming.
    final controller = StreamController<ChatStreamEvent>();
    _responseControllers[id] = controller;

    controller.stream.listen((event) {
      if (event.type == ChatStreamEventType.done) {
        if (!completer.isCompleted) {
          completer.complete(event.data ?? {});
        }
        controller.close();
        _responseControllers.remove(id);
      } else if (event.data != null && !completer.isCompleted) {
        completer.complete(event.data!);
        controller.close();
        _responseControllers.remove(id);
      } else if (event.type == ChatStreamEventType.error) {
        if (!completer.isCompleted) {
          completer.complete({'error': event.errorMessage});
        }
        controller.close();
        _responseControllers.remove(id);
      }
    });

    _channel!.sink.add(jsonEncode({
      'type': 'status',
      'id': id,
    }));

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _responseControllers.remove(id);
        controller.close();
        return {'error': 'Status request timed out'};
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ClawHub skill marketplace
  // ---------------------------------------------------------------------------

  /// Browse / search skills on the ClawHub marketplace.
  ///
  /// Returns a list of skill maps, each containing `id`, `name`,
  /// `description`, `author`, etc.
  static Future<List<Map<String, dynamic>>> browseSkills({
    String? query,
  }) async {
    try {
      final response = await _dio.get(
        '$_clawHubBaseUrl/skills',
        queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
        },
      );

      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        final skills = data['skills'] ?? data['data'] ?? data['items'];
        if (skills is List) {
          return skills.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } on DioException catch (e) {
      debugPrint('ClawHub browseSkills error: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('ClawHub browseSkills error: $e');
      return [];
    }
  }

  /// Install a skill from ClawHub by its [skillId].
  ///
  /// Returns `true` on success, `false` on failure.
  static Future<bool> installSkill(String skillId) async {
    try {
      final response = await _dio.post(
        '$_clawHubBaseUrl/skills/$skillId/install',
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('ClawHub installSkill error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('ClawHub installSkill error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Route an incoming WebSocket message to the correct response controller.
  static void _handleMessage(dynamic data) {
    try {
      final json = (data is String)
          ? jsonDecode(data) as Map<String, dynamic>
          : data as Map<String, dynamic>;

      final id = json['id']?.toString();
      final type = json['type'] as String?;

      if (id != null && _responseControllers.containsKey(id)) {
        final controller = _responseControllers[id]!;

        switch (type) {
          case 'text_delta':
          case 'delta':
            final text = json['text'] as String? ??
                json['content'] as String? ??
                '';
            controller.add(ChatStreamEvent.textDelta(text));
            break;

          case 'thinking_delta':
            final text = json['text'] as String? ?? '';
            controller.add(ChatStreamEvent.thinkingDelta(text));
            break;

          case 'tool_use':
            controller.add(ChatStreamEvent.toolUse(json));
            break;

          case 'error':
            controller.add(
              ChatStreamEvent.error(
                json['message'] as String? ?? 'Unknown gateway error',
              ),
            );
            break;

          case 'done':
          case 'end':
            controller.add(ChatStreamEvent.done());
            controller.close();
            _responseControllers.remove(id);
            break;

          case 'status':
            // Status response – wrap in a done event carrying the data.
            controller.add(ChatStreamEvent(
              type: ChatStreamEventType.done,
              data: json,
            ));
            break;

          default:
            // Unknown type – forward the raw data.
            controller.add(ChatStreamEvent(
              type: ChatStreamEventType.textDelta,
              text: json['content'] as String? ?? json.toString(),
            ));
            break;
        }
      }
    } catch (e) {
      debugPrint('OpenClaw _handleMessage error: $e');
    }
  }

  /// Schedule a reconnection attempt with exponential backoff.
  ///
  /// Backs off from 1 s up to 60 s between attempts and stops after 10
  /// consecutive failures.
  static void _scheduleReconnect() {
    if (_lastUrl == null) return; // disconnect() was called explicitly.
    if (_reconnectAttempts >= 10) return; // Give up.

    _reconnectTimer?.cancel();

    final delay = Duration(
      seconds: min(pow(2, _reconnectAttempts).toInt(), 60),
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(delay, () {
      if (_lastUrl != null &&
          connectionStatus.value != OpenClawStatus.connected) {
        connect(url: _lastUrl!);
      }
    });
  }
}
