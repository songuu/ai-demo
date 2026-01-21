import 'package:flutter/material.dart';
import 'package:server_box/data/model/app/tab.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// 现代化底部导航栏
class ModernNavigationBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isLandscape;

  const ModernNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isLandscape = false,
  });

  @override
  State<ModernNavigationBar> createState() => _ModernNavigationBarState();
}

class _ModernNavigationBarState extends State<ModernNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<Color?>> _colorAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      AppTab.values.length,
      (index) => AnimationController(
        duration: ModernDesignSystem.animationMedium,
        vsync: this,
      ),
    );

    _scaleAnimations = _controllers.map(
      (controller) => Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: ModernDesignSystem.animationBounceCurve,
      )),
    ).toList();

    _colorAnimations = _controllers.map(
      (controller) => ColorTween(
        begin: Colors.grey,
        end: Colors.blue, // 使用默认颜色，在 build 中应用正确颜色
      ).animate(CurvedAnimation(
        parent: controller,
        curve: ModernDesignSystem.animationCurve,
      )),
    ).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在此处更新颜色动画，因为现在可以安全访问 Theme
    _updateColorAnimations();
    // 延迟执行动画避免在widget更新期间的冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selectedIndex < _controllers.length) {
        _controllers[widget.selectedIndex].forward();
      }
    });
  }

  void _updateColorAnimations() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    _colorAnimations = _controllers.map(
      (controller) => ColorTween(
        begin: Colors.grey,
        end: primaryColor,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: ModernDesignSystem.animationCurve,
      )),
    ).toList();
  }

  @override
  void didUpdateWidget(ModernNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateAnimations(oldWidget.selectedIndex, widget.selectedIndex);
    }
  }

  void _updateAnimations(int oldIndex, int newIndex) {
    // 延迟执行动画避免在widget更新期间的冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (oldIndex < _controllers.length) {
          _controllers[oldIndex].reverse();
        }
        if (newIndex < _controllers.length) {
          _controllers[newIndex].forward();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: widget.isLandscape ? 60 : 80,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF1A2332),
                  Color(0xFF16213E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        border: Border(
          top: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            AppTab.values.length,
            (index) => _buildNavItem(index, AppTab.values[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, AppTab tab) {
    final isSelected = index == widget.selectedIndex;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onDestinationSelected(index);
          _playTapAnimation(index);
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimations[index],
            _colorAnimations[index],
          ]),
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: isSelected
                          ? BoxDecoration(
                              gradient: ModernDesignSystem.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            )
                          : null,
                      child: Icon(
                        _getIconData(tab, isSelected),
                        color: isSelected 
                            ? Colors.white
                            : _colorAnimations[index].value,
                        size: widget.isLandscape ? 20 : 24,
                      ),
                    ),
                  ),
                  if (!widget.isLandscape) ...[
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: ModernDesignSystem.animationFast,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      child: Text(
                        _getLabel(tab),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _playTapAnimation(int index) {
    _controllers[index].forward().then((_) {
      _controllers[index].reverse();
    });
  }

  IconData _getIconData(AppTab tab, bool isSelected) {
    final destination = tab.navDestination;
    return isSelected 
        ? (destination.selectedIcon as Icon).icon!
        : (destination.icon as Icon).icon!;
  }

  String _getLabel(AppTab tab) {
    return tab.navDestination.label;
  }
}

/// 现代化导航抽屉（为平板/桌面端）
class ModernNavigationRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const ModernNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  State<ModernNavigationRail> createState() => _ModernNavigationRailState();
}

class _ModernNavigationRailState extends State<ModernNavigationRail>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      AppTab.values.length,
      (index) => AnimationController(
        duration: ModernDesignSystem.animationMedium,
        vsync: this,
      ),
    );

    _slideAnimations = _controllers.map(
      (controller) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: ModernDesignSystem.animationCurve,
      )),
    ).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 延迟执行动画避免在widget更新期间的冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.selectedIndex < _controllers.length) {
        _controllers[widget.selectedIndex].forward();
      }
    });
  }

  @override
  void didUpdateWidget(ModernNavigationRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _updateAnimations(oldWidget.selectedIndex, widget.selectedIndex);
    }
  }

  void _updateAnimations(int oldIndex, int newIndex) {
    // 延迟执行动画避免在widget更新期间的冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (oldIndex < _controllers.length) {
          _controllers[oldIndex].reverse();
        }
        if (newIndex < _controllers.length) {
          _controllers[newIndex].forward();
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 80,
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF1A2332),
                  Color(0xFF16213E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        border: Border(
          right: BorderSide(
            color: isDark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: ModernDesignSystem.spacingL),
            ...List.generate(
              AppTab.values.length,
              (index) => _buildRailItem(index, AppTab.values[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRailItem(int index, AppTab tab) {
    final isSelected = index == widget.selectedIndex;
    
    return Container(
      margin: const EdgeInsets.only(bottom: ModernDesignSystem.spacingM),
      child: GestureDetector(
        onTap: () => widget.onDestinationSelected(index),
        child: AnimatedBuilder(
          animation: _slideAnimations[index],
          builder: (context, child) {
            return Stack(
              children: [
                // Selection indicator
                AnimatedPositioned(
                  duration: ModernDesignSystem.animationMedium,
                  left: isSelected ? 0 : -4,
                  top: 8,
                  bottom: 8,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: ModernDesignSystem.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(2),
                        bottomRight: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: isSelected
                      ? BoxDecoration(
                          gradient: ModernDesignSystem.primaryGradient.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 1,
                          ),
                        )
                      : null,
                  child: Icon(
                    _getIconData(tab, isSelected),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    size: 24,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getIconData(AppTab tab, bool isSelected) {
    final destination = tab.navDestination;
    return isSelected 
        ? (destination.selectedIcon as Icon).icon!
        : (destination.icon as Icon).icon!;
  }
}