import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Renders an image from a URL or base64-encoded data with tap-to-fullscreen.
class ImageBlockWidget extends StatelessWidget {
  final String? url;
  final String? base64Data;

  const ImageBlockWidget({
    super.key,
    this.url,
    this.base64Data,
  });

  ImageProvider? get _imageProvider {
    if (base64Data != null && base64Data!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(base64Data!));
      } catch (_) {
        return null;
      }
    }
    if (url != null && url!.isNotEmpty) {
      return NetworkImage(url!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider;

    if (provider == null) {
      return _buildErrorPlaceholder(context);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusMedium,
        ),
        child: GestureDetector(
          onTap: () => _openFullScreen(context, provider),
          child: Image(
            image: provider,
            fit: BoxFit.contain,
            loadingBuilder: _loadingBuilder,
            errorBuilder: (context, error, stackTrace) =>
                _buildErrorPlaceholder(context),
          ),
        ),
      ),
    );
  }

  Widget _loadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = loadingProgress.expectedTotalBytes != null
        ? loadingProgress.cumulativeBytesLoaded /
            loadingProgress.expectedTotalBytes!
        : null;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusMedium,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  ModernDesignSystem.primaryGradient.colors.first,
                ),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: ModernDesignSystem.spacingS),
              Text(
                '${(progress * 100).toInt()}%',
                style: ModernDesignSystem.caption.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(
          ModernDesignSystem.borderRadiusMedium,
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.2),
            ),
            const SizedBox(height: ModernDesignSystem.spacingS),
            Text(
              'Image unavailable',
              style: ModernDesignSystem.caption.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context, ImageProvider provider) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageView(
            provider: provider,
            animation: animation,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class _FullScreenImageView extends StatelessWidget {
  final ImageProvider provider;
  final Animation<double> animation;

  const _FullScreenImageView({
    required this.provider,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image(
              image: provider,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
