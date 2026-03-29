import 'package:flutter/material.dart';
import 'package:server_box/chat/model/chat_provider.dart';
import 'package:server_box/chat/store/chat_provider_store.dart';
import 'package:server_box/view/page/chat/provider_config_page.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// Result returned by the model selector.
class ModelSelection {
  final String providerId;
  final String modelId;

  const ModelSelection({
    required this.providerId,
    required this.modelId,
  });
}

/// Shows a model selection dialog/bottom sheet grouped by provider.
/// Returns a [ModelSelection] if the user picked a model, or null if dismissed.
class ModelSelector extends StatelessWidget {
  final String? currentProviderId;
  final String? currentModelId;

  const ModelSelector({
    super.key,
    this.currentProviderId,
    this.currentModelId,
  });

  /// Convenience method to show the selector as a bottom sheet.
  static Future<ModelSelection?> show(
    BuildContext context, {
    String? currentProviderId,
    String? currentModelId,
  }) {
    return showModalBottomSheet<ModelSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModelSelector(
        currentProviderId: currentProviderId,
        currentModelId: currentModelId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;
    final providers = ChatProviderStore.enabled();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ModernDesignSystem.borderRadiusLarge),
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(
              top: ModernDesignSystem.spacingM,
              bottom: ModernDesignSystem.spacingS,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingL,
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.model_training_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: ModernDesignSystem.spacingS),
                Text(
                  'Select Model',
                  style: ModernDesignSystem.headingSmall.copyWith(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
          // Provider + Model list
          Flexible(
            child: providers.isEmpty
                ? _buildEmptyState(context, isDark)
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: ModernDesignSystem.spacingS,
                    ),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      return _ProviderSection(
                        provider: provider,
                        currentProviderId: currentProviderId,
                        currentModelId: currentModelId,
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onModelSelected: (modelId) {
                          Navigator.of(context).pop(ModelSelection(
                            providerId: provider.id,
                            modelId: modelId,
                          ));
                        },
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final primaryColor = ModernDesignSystem.primaryGradient.colors.first;

    return Padding(
      padding: const EdgeInsets.all(ModernDesignSystem.spacingXL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.15),
          ),
          const SizedBox(height: ModernDesignSystem.spacingM),
          Text(
            'No providers configured',
            style: ModernDesignSystem.bodyMedium.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: ModernDesignSystem.spacingXS),
          Text(
            'Add a provider in Settings to get started.',
            style: ModernDesignSystem.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: ModernDesignSystem.spacingM),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProviderConfigPage(),
                ),
              );
            },
            icon: Icon(Icons.add, size: 18, color: primaryColor),
            label: Text(
              'Add Provider',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderSection extends StatelessWidget {
  final ChatProvider provider;
  final String? currentProviderId;
  final String? currentModelId;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<String> onModelSelected;

  const _ProviderSection({
    required this.provider,
    this.currentProviderId,
    this.currentModelId,
    required this.isDark,
    required this.primaryColor,
    required this.onModelSelected,
  });

  IconData _providerIcon() {
    switch (provider.type) {
      case 'openai':
        return Icons.auto_awesome;
      case 'anthropic':
        return Icons.psychology;
      case 'google':
        return Icons.science;
      default:
        return Icons.cloud_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (provider.models.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Provider header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
            vertical: ModernDesignSystem.spacingS,
          ),
          child: Row(
            children: [
              Icon(
                _providerIcon(),
                size: 16,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.4),
              ),
              const SizedBox(width: ModernDesignSystem.spacingS),
              Text(
                provider.name,
                style: ModernDesignSystem.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        // Model items
        ...provider.models.map((modelId) {
          final isSelected =
              provider.id == currentProviderId && modelId == currentModelId;
          return _ModelTile(
            modelId: modelId,
            isSelected: isSelected,
            isDark: isDark,
            primaryColor: primaryColor,
            onTap: () => onModelSelected(modelId),
          );
        }),
        const SizedBox(height: ModernDesignSystem.spacingS),
      ],
    );
  }
}

class _ModelTile extends StatelessWidget {
  final String modelId;
  final bool isSelected;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _ModelTile({
    required this.modelId,
    required this.isSelected,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ModernDesignSystem.spacingM,
        vertical: 1,
      ),
      child: Material(
        color: isSelected
            ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(ModernDesignSystem.borderRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingM,
              vertical: ModernDesignSystem.spacingS + 2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    modelId,
                    style: ModernDesignSystem.bodyMedium.copyWith(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: primaryColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
