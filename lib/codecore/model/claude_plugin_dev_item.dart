import 'package:flutter/foundation.dart';

int _parseInt(dynamic v) => switch (v) {
      final int i => i,
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

/// Plugin / Subagent item from claude-plugins.dev API
@immutable
class ClaudePluginsDevItem {
  final String id;
  final String name;

  /// e.g. "@anthropics/claude-code-plugins"
  final String namespace;
  final String description;

  /// "agents" → subagent; otherwise plugin
  final String? category;
  final String author;
  final int stars;
  final int downloads;
  final String gitUrl;
  final bool verified;
  final List<String> keywords;
  final List<String> skills;
  final String? version;
  final String? license;

  const ClaudePluginsDevItem({
    required this.id,
    required this.name,
    required this.namespace,
    required this.description,
    required this.category,
    required this.author,
    required this.stars,
    required this.downloads,
    required this.gitUrl,
    required this.verified,
    required this.keywords,
    required this.skills,
    this.version,
    this.license,
  });

  factory ClaudePluginsDevItem.fromJson(Map<String, dynamic> json) {
    List<String> _toStringList(dynamic v) {
      if (v == null) return const [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    final meta = json['metadata'] as Map<String, dynamic>?;

    return ClaudePluginsDevItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      namespace: (json['namespace'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: json['category']?.toString(),
      author: (json['author'] ?? '').toString(),
      stars: _parseInt(json['stars']),
      downloads: _parseInt(json['downloads']),
      gitUrl: (json['gitUrl'] ?? '').toString(),
      verified: json['verified'] == true,
      keywords: _toStringList(json['keywords']),
      skills: _toStringList(json['skills']),
      version: json['version']?.toString(),
      license: meta?['license']?.toString(),
    );
  }

  bool get isSubagent => category == 'agents' || keywords.contains('subagent');

  /// Full install identifier: "@namespace/name"
  String get fullId => '$namespace/$name';

  /// CLI install command
  String get installCommand => 'npx claude-plugins install $namespace/$name';
}

class ClaudePluginsDevResult {
  final List<ClaudePluginsDevItem> items;
  final int total;
  final bool hasMore;

  const ClaudePluginsDevResult({
    required this.items,
    required this.total,
    required this.hasMore,
  });
}
