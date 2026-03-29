import 'package:flutter/material.dart';
import 'package:fl_lib/fl_lib.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders a web search citation as a tappable chip with title and URL.
class CitationBlockWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const CitationBlockWidget({
    super.key,
    required this.data,
  });

  String get _title => data['title'] as String? ?? 'Source';
  String get _url => data['url'] as String? ?? '';

  String get _truncatedUrl {
    if (_url.length <= 50) return _url;
    // Show scheme + host + truncated path
    try {
      final uri = Uri.parse(_url);
      final host = uri.host;
      final path = uri.path;
      final truncatedPath =
          path.length > 20 ? '${path.substring(0, 20)}...' : path;
      return '$host$truncatedPath';
    } catch (_) {
      return '${_url.substring(0, 47)}...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _url.isNotEmpty ? () => _url.launchUrl() : null,
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusSmall,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingM,
            vertical: ModernDesignSystem.spacingS,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF667EEA).withValues(alpha: 0.15),
                      const Color(0xFF764BA2).withValues(alpha: 0.1),
                    ]
                  : [
                      const Color(0xFF667EEA).withValues(alpha: 0.08),
                      const Color(0xFF764BA2).withValues(alpha: 0.05),
                    ],
            ),
            borderRadius: BorderRadius.circular(
              ModernDesignSystem.borderRadiusSmall,
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF667EEA).withValues(alpha: 0.3)
                  : const Color(0xFF667EEA).withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Link icon
              Container(
                padding: const EdgeInsets.all(ModernDesignSystem.spacingXS),
                decoration: BoxDecoration(
                  gradient: ModernDesignSystem.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    ModernDesignSystem.borderRadiusSmall / 2,
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: ModernDesignSystem.spacingS),
              // Title and URL
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      style: ModernDesignSystem.bodySmall.copyWith(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_url.isNotEmpty)
                      Text(
                        _truncatedUrl,
                        style: ModernDesignSystem.caption.copyWith(
                          color: ModernDesignSystem
                              .primaryGradient.colors.first,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: ModernDesignSystem.spacingXS),
              Icon(
                Icons.open_in_new_rounded,
                size: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
