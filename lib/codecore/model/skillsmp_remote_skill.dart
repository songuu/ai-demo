import 'package:flutter/foundation.dart';

@immutable
class SkillsMpRemoteSkill {
  final String name;
  final String description;
  final String author;
  final int stars;
  final String skillUrl;
  final String githubUrl;

  const SkillsMpRemoteSkill({
    required this.name,
    required this.description,
    required this.author,
    required this.stars,
    required this.skillUrl,
    required this.githubUrl,
  });

  factory SkillsMpRemoteSkill.fromJson(Map<String, dynamic> json) {
    return SkillsMpRemoteSkill(
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      stars: switch (json['stars']) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      skillUrl: (json['skillUrl'] ?? '').toString(),
      githubUrl: (json['githubUrl'] ?? '').toString(),
    );
  }

  String get githubSource {
    final uri = Uri.tryParse(githubUrl);
    if (uri == null || !uri.host.contains('github.com')) {
      return githubUrl;
    }

    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length >= 2) {
      return '${segments[0]}/${segments[1]}';
    }
    return githubUrl;
  }
}
