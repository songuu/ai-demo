import 'package:flutter/material.dart';
import 'dart:ui';

/// 现代化设计系统 - 炫酷UI设计
class ModernDesignSystem {
  // 现代渐变色彩方案
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667EEA), // 蓝紫色
      Color(0xFF764BA2), // 深紫色
    ],
  );

  static const secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF11998e), // 青绿色
      Color(0xFF38ef7d), // 亮绿色
    ],
  );

  static const warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF6B6B), // 红色
      Color(0xFFFFE66D), // 黄色
    ],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF48CAE4), // 浅蓝
      Color(0xFF023047), // 深蓝
    ],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2D3748), // 深灰蓝
      Color(0xFF1A202C), // 更深灰
    ],
  );

  // 玻璃态效果颜色
  static const glassmorphismLight = Color(0x1AFFFFFF);
  static const glassmorphismDark = Color(0x1A000000);

  // 阴影效果
  static const modernShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static const glowShadow = [
    BoxShadow(
      color: Color(0x33667EEA),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  // 边框半径
  static const borderRadiusSmall = 8.0;
  static const borderRadiusMedium = 16.0;
  static const borderRadiusLarge = 24.0;
  static const borderRadiusXL = 32.0;

  // 间距
  static const spacingXS = 4.0;
  static const spacingS = 8.0;
  static const spacingM = 16.0;
  static const spacingL = 24.0;
  static const spacingXL = 32.0;
  static const spacingXXL = 48.0;

  // 字体样式
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );

  // 动画持续时间
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // 动画曲线
  static const Curve animationCurve = Curves.easeInOutCubic;
  static const Curve animationBounceCurve = Curves.elasticOut;
}

/// 现代化玻璃态卡片组件
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Gradient? gradient;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = ModernDesignSystem.borderRadiusMedium,
    this.onTap,
    this.showBorder = true,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(ModernDesignSystem.spacingM),
            decoration: BoxDecoration(
              gradient: gradient ?? (isDark 
                ? const LinearGradient(
                    colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0x1A000000), Color(0x0D000000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )),
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                ? Border.all(
                    color: isDark 
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                    width: 1,
                  )
                : null,
              boxShadow: ModernDesignSystem.modernShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius - 1),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 现代化渐变按钮
class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? icon;
  final double? width;
  final double? height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.borderRadius = ModernDesignSystem.borderRadiusMedium,
    this.padding,
    this.textStyle,
    this.icon,
    this.width,
    this.height,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
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
      end: 0.95,
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
              width: widget.width,
              height: widget.height ?? 48,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? ModernDesignSystem.primaryGradient,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                boxShadow: ModernDesignSystem.modernShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.symmetric(
                      horizontal: ModernDesignSystem.spacingL,
                      vertical: ModernDesignSystem.spacingM,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          widget.icon!,
                          const SizedBox(width: ModernDesignSystem.spacingS),
                        ],
                        Text(
                          widget.text,
                          style: widget.textStyle ?? ModernDesignSystem.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 现代化进度指示器
class ModernProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Gradient? gradient;
  final String? label;
  final String? value;

  const ModernProgressIndicator({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 6,
    this.gradient,
    this.label,
    this.value,
  });

  @override
  State<ModernProgressIndicator> createState() => _ModernProgressIndicatorState();
}

class _ModernProgressIndicatorState extends State<ModernProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernDesignSystem.animationSlow,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ModernDesignSystem.animationCurve,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ModernProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: ModernDesignSystem.animationCurve,
      ));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              // Progress circle
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  value: _progressAnimation.value,
                  strokeWidth: widget.strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    widget.gradient != null ? null : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              // Center content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.value != null)
                    Text(
                      widget.value!,
                      style: ModernDesignSystem.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: ModernDesignSystem.caption.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 现代化状态指示器
class StatusIndicator extends StatelessWidget {
  final bool isOnline;
  final double size;
  final bool showPulse;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isOnline 
          ? ModernDesignSystem.successGradient
          : ModernDesignSystem.warningGradient,
        boxShadow: showPulse && isOnline ? [
          BoxShadow(
            color: const Color(0xFF48CAE4).withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: showPulse && isOnline
        ? _PulsingDot(size: size)
        : null,
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final double size;

  const _PulsingDot({required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: ModernDesignSystem.successGradient,
            ),
          ),
        );
      },
    );
  }
}