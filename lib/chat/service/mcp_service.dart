import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:server_box/chat/model/mcp_server_config.dart';

/// MCP (Model Context Protocol) service implementing JSON-RPC 2.0 over stdio.
///
/// Manages lifecycle of MCP server processes and provides methods to
/// list tools and invoke tool calls through the protocol.
class McpService {
  McpService._();

  /// Active MCP server processes keyed by server ID.
  static final Map<String, Process> _processes = {};

  /// Pending JSON-RPC requests awaiting a response, keyed by request ID.
  static final Map<String, Completer<Map<String, dynamic>>> _pendingRequests =
      {};

  /// Monotonically increasing counter for JSON-RPC request IDs.
  static int _requestId = 0;

  /// Accumulated stdout buffers per server (handles partial lines).
  static final Map<String, String> _stdoutBuffers = {};

  /// Connect to an MCP server by spawning its process and performing the
  /// JSON-RPC `initialize` handshake.
  ///
  /// The [config] must have [McpServerConfig.type] set to `"stdio"` and a
  /// non-empty [McpServerConfig.command].
  static Future<void> connect(McpServerConfig config) async {
    if (_processes.containsKey(config.id)) {
      return; // Already connected
    }

    final process = await Process.start(
      config.command,
      config.args,
      environment: config.env.isNotEmpty ? config.env : null,
    );

    _processes[config.id] = process;
    _stdoutBuffers[config.id] = '';

    // Listen to stdout for JSON-RPC responses (line-delimited JSON).
    process.stdout.transform(utf8.decoder).listen(
      (data) {
        _stdoutBuffers[config.id] =
            (_stdoutBuffers[config.id] ?? '') + data;

        // Process complete lines.
        while (_stdoutBuffers[config.id]!.contains('\n')) {
          final idx = _stdoutBuffers[config.id]!.indexOf('\n');
          final line = _stdoutBuffers[config.id]!.substring(0, idx).trim();
          _stdoutBuffers[config.id] =
              _stdoutBuffers[config.id]!.substring(idx + 1);

          if (line.isNotEmpty) {
            _handleResponse(config.id, line);
          }
        }
      },
      onError: (e) {
        // On stream error, fail all pending requests for this server.
        _failPendingRequests(
          config.id,
          'stdout error: $e',
        );
      },
    );

    // Listen to stderr for diagnostics (log but don't parse).
    process.stderr.transform(utf8.decoder).listen((data) {
      // stderr output is informational only; ignore in production.
    });

    // Clean up when the process exits unexpectedly.
    process.exitCode.then((_) {
      _processes.remove(config.id);
      _stdoutBuffers.remove(config.id);
      _failPendingRequests(config.id, 'Process exited');
    });

    // Send the MCP initialize request.
    await _sendRequest(
      process,
      'initialize',
      {
        'protocolVersion': '2024-11-05',
        'capabilities': {},
        'clientInfo': {
          'name': 'ServerBox',
          'version': '1.0.0',
        },
      },
    );

    // After successful init, send initialized notification (no id => notification).
    final notification = jsonEncode({
      'jsonrpc': '2.0',
      'method': 'notifications/initialized',
    });
    process.stdin.writeln(notification);
    await process.stdin.flush();
  }

  /// Disconnect from an MCP server, killing its process and cleaning up
  /// all associated state.
  static Future<void> disconnect(String serverId) async {
    final process = _processes.remove(serverId);
    _stdoutBuffers.remove(serverId);
    _failPendingRequests(serverId, 'Disconnected');

    if (process != null) {
      process.kill();
      // Give it a moment to terminate gracefully.
      await process.exitCode.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
  }

  /// List the tools exposed by the MCP server identified by [serverId].
  ///
  /// Returns a list of tool definition maps, each containing at minimum
  /// `name`, `description`, and `inputSchema`.
  static Future<List<Map<String, dynamic>>> listTools(String serverId) async {
    final process = _processes[serverId];
    if (process == null) {
      throw StateError('MCP server "$serverId" is not connected');
    }

    final result = await _sendRequest(process, 'tools/list', null);
    final tools = result['tools'] as List<dynamic>?;
    if (tools == null) return [];

    return tools.cast<Map<String, dynamic>>();
  }

  /// Call a tool on the MCP server identified by [serverId].
  ///
  /// [toolName] is the name of the tool to invoke, and [input] is the
  /// arguments map matching the tool's `inputSchema`.
  static Future<Map<String, dynamic>> callTool(
    String serverId,
    String toolName,
    Map<String, dynamic> input,
  ) async {
    final process = _processes[serverId];
    if (process == null) {
      throw StateError('MCP server "$serverId" is not connected');
    }

    return _sendRequest(process, 'tools/call', {
      'name': toolName,
      'arguments': input,
    });
  }

  /// Returns `true` if the server identified by [serverId] has an active
  /// process.
  static bool isConnected(String serverId) {
    return _processes.containsKey(serverId);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Send a JSON-RPC 2.0 request over the process's stdin and wait for the
  /// corresponding response on stdout.
  static Future<Map<String, dynamic>> _sendRequest(
    Process process,
    String method,
    Map<String, dynamic>? params,
  ) async {
    final id = ++_requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id.toString()] = completer;

    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
    };
    if (params != null) {
      request['params'] = params;
    }

    process.stdin.writeln(jsonEncode(request));
    await process.stdin.flush();

    // Time out after 30 seconds to avoid indefinitely hung requests.
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pendingRequests.remove(id.toString());
        throw TimeoutException(
          'MCP request "$method" (id=$id) timed out after 30 s',
        );
      },
    );
  }

  /// Parse a single JSON-RPC response line and complete the matching pending
  /// request.
  static void _handleResponse(String serverId, String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;

      // Only process messages that carry an `id` (responses).
      // Notifications (no id) are silently ignored.
      final id = json['id'];
      if (id == null) return;

      final idStr = id.toString();
      final completer = _pendingRequests.remove(idStr);
      if (completer == null) return;

      final error = json['error'] as Map<String, dynamic>?;
      if (error != null) {
        completer.completeError(
          Exception(
            'MCP error ${error['code']}: ${error['message']}',
          ),
        );
        return;
      }

      final result = json['result'] as Map<String, dynamic>? ?? {};
      completer.complete(result);
    } catch (e) {
      // Malformed JSON lines are silently skipped.
    }
  }

  /// Fail all pending requests that belong to a specific server.
  ///
  /// This is called when a server process exits or encounters a fatal error.
  static void _failPendingRequests(String serverId, String reason) {
    // We cannot efficiently know which pending request belongs to which server
    // without extra bookkeeping, so we iterate all and fail the ones whose
    // completers are still pending. In practice the caller should disconnect
    // properly, which removes requests one-by-one.
    final toRemove = <String>[];
    for (final entry in _pendingRequests.entries) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(Exception(reason));
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _pendingRequests.remove(key);
    }
  }
}
