import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:server_box/codecore/model/skillsmp_remote_skill.dart';
import 'package:server_box/codecore/store/cod_settings_store.dart';

class SkillsMpSearchResult {
  final List<SkillsMpRemoteSkill> skills;
  final int total;
  final bool hasMore;

  const SkillsMpSearchResult({
    required this.skills,
    required this.total,
    required this.hasMore,
  });
}

class SkillsMpService {
  SkillsMpService._();

  static const _baseUrl = 'https://skillsmp.com/api/v1';

  static Dio _buildDio(String apiKey) {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.userAgentHeader: 'Mozilla/5.0 ServerBox/1.0',
        },
        sendTimeout: const Duration(seconds: 20),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    // Use IOHttpClientAdapter so TLS works correctly on desktop platforms.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          HttpClient(context: SecurityContext.defaultContext)
            ..connectionTimeout = const Duration(seconds: 20),
    );
    return dio;
  }

  static String get _apiKey => CodSettingsStore.skillsMpApiKey.trim();

  static bool get hasApiKey => _apiKey.isNotEmpty;

  static Future<SkillsMpSearchResult> searchSkills({
    required String query,
    int page = 1,
    int limit = 20,
    String sortBy = 'stars',
  }) async {
    if (!hasApiKey) {
      throw Exception('请先配置 SkillsMP API Key');
    }

    final resp = await _buildDio(_apiKey).get<Map<String, dynamic>>(
      '/skills/search',
      queryParameters: {
        'q': query,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
      },
    );

    final body = resp.data ?? const <String, dynamic>{};
    final data =
        body['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final list = (data['skills'] as List? ?? const [])
        .whereType<Map>()
        .map((item) =>
            SkillsMpRemoteSkill.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.name.isNotEmpty && item.githubUrl.isNotEmpty)
        .toList();

    final pagination = data['pagination'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final total = switch (pagination['total']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? list.length,
      _ => list.length,
    };
    final totalPages = switch (pagination['totalPages']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 1,
      _ => 1,
    };

    return SkillsMpSearchResult(
      skills: list,
      total: total,
      hasMore: page < totalPages,
    );
  }

  static Future<void> installToClaudeCode(
    SkillsMpRemoteSkill skill, {
    bool global = true,
  }) async {
    final command = Platform.isWindows ? 'npx.cmd' : 'npx';
    final args = <String>[
      '-y',
      'add-skill',
      skill.githubSource,
      '-s',
      skill.name,
      '-a',
      'claude-code',
      '-y',
      if (global) '-g',
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
                : '安装失败，请确认已安装 Node.js 且可以执行 npx add-skill',
      );
    }
  }
}
