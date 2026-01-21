part of 'modern_server_tab.dart';

class _ModernTopBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueNotifier<Set<String>> tags;
  final String initTag;
  final void Function(String) onTagChanged;
  final VoidCallback onRefresh;

  const _ModernTopBar({
    required this.tags,
    required this.initTag,
    required this.onTagChanged,
    required this.onRefresh,
  });

  @override
  State<_ModernTopBar> createState() => _ModernTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(120);
}

class _ModernTopBarState extends State<_ModernTopBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ModernDesignSystem.animationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernDesignSystem.animationCurve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: ModernDesignSystem.animationCurve,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: ModernDesignSystem.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ModernDesignSystem.spacingL,
                    vertical: ModernDesignSystem.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopRow(),
                      const SizedBox(height: ModernDesignSystem.spacingM),
                      _buildTagSelector(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servers',
                style: ModernDesignSystem.headingLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Monitor your infrastructure',
                style: ModernDesignSystem.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.refresh,
          onPressed: widget.onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: ModernDesignSystem.spacingS),
        _buildActionButton(
          icon: Icons.settings,
          onPressed: () => SettingsPage.route.go(context),
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSelector() {
    return widget.tags.listenVal((tags) {
      final allTags = [TagSwitcher.kDefaultTag, ...tags].toSet().toList();
      
      return SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: allTags.length,
          itemBuilder: (context, index) {
            final tag = allTags[index];
            final isSelected = tag == widget.initTag;
            
            return Container(
              margin: EdgeInsets.only(
                right: index < allTags.length - 1 
                    ? ModernDesignSystem.spacingS 
                    : 0,
              ),
              child: _buildTagChip(
                label: tag == TagSwitcher.kDefaultTag ? 'All' : tag,
                isSelected: isSelected,
                onTap: () => widget.onTagChanged(tag),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildTagChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: ModernDesignSystem.animationFast,
      decoration: BoxDecoration(
        color: isSelected 
            ? Colors.white.withOpacity(0.25)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected 
              ? Colors.white.withOpacity(0.4)
              : Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernDesignSystem.spacingL,
              vertical: ModernDesignSystem.spacingS,
            ),
            child: Text(
              label,
              style: ModernDesignSystem.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}