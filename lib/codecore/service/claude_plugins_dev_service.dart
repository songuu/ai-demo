import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:server_box/codecore/model/claude_plugin_dev_item.dart';

/// Service for the claude-plugins.dev open API.
/// No API key required.
/// https://claude-plugins.dev/api/plugins?search=Q&limit=20&offset=0
/// https://claude-plugins.dev/api/plugins?search=Q&category=agents&limit=20&offset=0
class ClaudePluginsDevService {
  ClaudePluginsDevService._();

  static const _baseUrl = 'https://claude-plugins.dev';

  static Dio get _dio {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'Mozilla/5.0 ServerBox/1.0',
        },
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 35),
      ),
    );
    // Use IOHttpClientAdapter so TLS works correctly on desktop platforms.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: SecurityContext.defaultContext)
          ..connectionTimeout = const Duration(seconds: 25);
        return client;
      },
    );
    return dio;
  }

  /// Search plugins (excludes subagents).
  static Future<ClaudePluginsDevResult> searchPlugins({
    required String query,
    int page = 1,
    int limit = 20,
    String? category,
    String sortBy = 'downloads',
  }) async {
    return _query(
      query: query,
      page: page,
      limit: limit,
      category: category,
      sortBy: sortBy,
    );
  }

  /// Search subagents (category=agents).
  static Future<ClaudePluginsDevResult> searchSubagents({
    required String query,
    int page = 1,
    int limit = 20,
    String sortBy = 'downloads',
  }) async {
    return _query(
      query: query,
      page: page,
      limit: limit,
      category: 'agents',
      sortBy: sortBy,
    );
  }

  static Future<ClaudePluginsDevResult> _query({
    required String query,
    required int page,
    required int limit,
    String? category,
    String sortBy = 'downloads',
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': (page - 1) * limit,
      'orderBy': sortBy,
      'order': 'desc',
    };

    if (query.isNotEmpty) params['search'] = query;
    if (category != null) params['category'] = category;

    final resp = await _dio.get<Map<String, dynamic>>(
      '/api/plugins',
      queryParameters: params,
    );

    final body = resp.data ?? const <String, dynamic>{};
    final list = (body['plugins'] as List? ?? const [])
        .whereType<Map>()
        .map((item) =>
            ClaudePluginsDevItem.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.name.isNotEmpty)
        .toList();

    int parseIntVal(dynamic v) => switch (v) {
          final int i => i,
          final num n => n.toInt(),
          final String s => int.tryParse(s) ?? 0,
          _ => 0,
        };
    final total = parseIntVal(body['total']);

    return ClaudePluginsDevResult(
      items: list,
      total: total,
      hasMore: (page - 1) * limit + list.length < total,
    );
  }

  /// Install a plugin/subagent via npx claude-plugins install.
  static Future<void> install(ClaudePluginsDevItem item) async {
    final command = Platform.isWindows ? 'npx.cmd' : 'npx';
    final args = <String>[
      '-y',
      'claude-plugins',
      'install',
      item.fullId,
    ];

    final result = await Process.run(command, args, runInShell: false);
    if (result.exitCode != 0) {
      final stderr = result.stderr?.toString().trim();
      final stdout = result.stdout?.toString().trim();
      throw Exception(
        stderr?.isNotEmpty == true
            ? stderr
            : stdout?.isNotEmpty == true
                ? stdout
                : '安装失败，请确认已安装 Node.js 且可执行 npx claude-plugins',
      );
    }
  }
}
