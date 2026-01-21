import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:server_box/view/widget/modern_design_system.dart';

/// 现代化主题配置
class ModernTheme {
  static ThemeData get lightTheme {
    const primaryColor = Color(0xFF667EEA);
    const backgroundColor = Color(0xFFF8FAFC);
    const surfaceColor = Colors.white;
    const cardColor = Colors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: Color(0xFF11998e),
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1A202C),
        onBackground: Color(0xFF1A202C),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: Color(0xFF1A202C),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF1A202C)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        indicatorColor: primaryColor.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            );
          },
        ),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: primaryColor);
            }
            return const IconThemeData(color: Color(0xFF64748B));
          },
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
            vertical: ModernDesignSystem.spacingM,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: ModernDesignSystem.headingLarge,
        headlineMedium: ModernDesignSystem.headingMedium,
        headlineSmall: ModernDesignSystem.headingSmall,
        bodyLarge: ModernDesignSystem.bodyLarge,
        bodyMedium: ModernDesignSystem.bodyMedium,
        bodySmall: ModernDesignSystem.bodySmall,
        labelSmall: ModernDesignSystem.caption,
      ).apply(
        bodyColor: const Color(0xFF1A202C),
        displayColor: const Color(0xFF1A202C),
      ),
    );
  }

  static ThemeData get darkTheme {
    const primaryColor = Color(0xFF667EEA);
    const backgroundColor = Color(0xFF0F0F23);
    const surfaceColor = Color(0xFF16213E);
    const cardColor = Color(0xFF1A2332);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFF38ef7d),
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Color(0xFF0F0F23),
        onSurface: Color(0xFFE2E8F0),
        onBackground: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            );
          },
        ),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: primaryColor);
            }
            return const IconThemeData(color: Color(0xFF94A3B8));
          },
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
            vertical: ModernDesignSystem.spacingM,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: ModernDesignSystem.headingLarge,
        headlineMedium: ModernDesignSystem.headingMedium,
        headlineSmall: ModernDesignSystem.headingSmall,
        bodyLarge: ModernDesignSystem.bodyLarge,
        bodyMedium: ModernDesignSystem.bodyMedium,
        bodySmall: ModernDesignSystem.bodySmall,
        labelSmall: ModernDesignSystem.caption,
      ).apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFE2E8F0),
      ),
    );
  }

  static ThemeData get amoledTheme {
    const primaryColor = Color(0xFF667EEA);
    const backgroundColor = Color(0xFF000000);
    const surfaceColor = Color(0xFF111111);
    const cardColor = Color(0xFF1A1A1A);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: Color(0xFF38ef7d),
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: backgroundColor,
        onSurface: Color(0xFFE2E8F0),
        onBackground: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith<TextStyle?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            );
          },
        ),
        iconTheme: MaterialStateProperty.resolveWith<IconThemeData?>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: primaryColor);
            }
            return const IconThemeData(color: Color(0xFF94A3B8));
          },
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernDesignSystem.borderRadiusMedium),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ModernDesignSystem.spacingL,
            vertical: ModernDesignSystem.spacingM,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: ModernDesignSystem.headingLarge,
        headlineMedium: ModernDesignSystem.headingMedium,
        headlineSmall: ModernDesignSystem.headingSmall,
        bodyLarge: ModernDesignSystem.bodyLarge,
        bodyMedium: ModernDesignSystem.bodyMedium,
        bodySmall: ModernDesignSystem.bodySmall,
        labelSmall: ModernDesignSystem.caption,
      ).apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFE2E8F0),
      ),
    );
  }
}

/// 现代化应用栏组件
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGradient;
  final VoidCallback? onLeadingPressed;

  const ModernAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showGradient = true,
    this.onLeadingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showGradient
          ? const BoxDecoration(
              gradient: ModernDesignSystem.primaryGradient,
            )
          : null,
      child: AppBar(
        title: Text(
          title,
          style: ModernDesignSystem.headingMedium.copyWith(
            color: showGradient ? Colors.white : null,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: leading != null
            ? IconButton(
                icon: leading!,
                onPressed: onLeadingPressed,
                color: showGradient ? Colors.white : null,
              )
            : null,
        actions: actions?.map((action) {
          if (action is IconButton && showGradient) {
            return IconButton(
              icon: action.icon,
              onPressed: action.onPressed,
              color: Colors.white,
            );
          }
          return action;
        }).toList(),
        systemOverlayStyle: showGradient 
            ? SystemUiOverlayStyle.light
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// 现代化浮动操作按钮
class ModernFloatingActionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? tooltip;
  final Gradient? gradient;

  const ModernFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.gradient,
  });

  @override
  State<ModernFloatingActionButton> createState() => _ModernFloatingActionButtonState();
}

class _ModernFloatingActionButtonState extends State<ModernFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernDesignSystem.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ModernDesignSystem.animationCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? ModernDesignSystem.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: ModernDesignSystem.modernShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  child: Center(child: widget.icon),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}