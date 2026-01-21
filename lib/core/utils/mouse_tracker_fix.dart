import 'package:flutter/material.dart';

/// 用于修复 mouse_tracker 断言错误的工具类
/// 
/// mouse_tracker 错误通常发生在以下情况：
/// 1. 在 MouseRegion 的 onEnter/onExit 回调中直接调用 setState
/// 2. 在 widget 生命周期方法中执行动画
/// 3. 在鼠标事件处理期间修改 widget 树
class MouseTrackerFix {
  /// 安全地执行可能触发 mouse_tracker 问题的操作
  /// 
  /// 这个方法会在下一帧开始时执行回调，避免在鼠标事件处理期间的冲突
  static void safeExecute(VoidCallback callback, {bool checkMounted = true, State? state}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!checkMounted || (state?.mounted ?? true)) {
        callback();
      }
    });
  }

  /// 安全地执行 setState 操作
  /// 
  /// 用于在鼠标事件回调中安全地更新状态
  static void safeSetState(State state, VoidCallback callback) {
    safeExecute(() {
      if (state.mounted) {
        // ignore: invalid_use_of_protected_member
        state.setState(callback);
      }
    }, state: state);
  }

  /// 安全地执行动画操作
  /// 
  /// 用于在 widget 生命周期方法中安全地启动动画
  static void safeAnimateController(AnimationController controller, {required bool forward}) {
    safeExecute(() {
      if (controller.isAnimating) return;
      
      if (forward) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  /// 创建安全的 MouseRegion
  /// 
  /// 自动处理 onEnter 和 onExit 回调，避免 mouse_tracker 断言错误
  static Widget createSafeMouseRegion({
    required Widget child,
    required State state,
    VoidCallback? onEnter,
    VoidCallback? onExit,
  }) {
    return MouseRegion(
      onEnter: onEnter != null ? (_) => safeSetState(state, onEnter) : null,
      onExit: onExit != null ? (_) => safeSetState(state, onExit) : null,
      child: child,
    );
  }
}

/// 扩展方法，为 State 添加安全操作方法
extension StateMouseTrackerFix on State {
  /// 安全地执行 setState
  void safeSetState(VoidCallback callback) {
    MouseTrackerFix.safeSetState(this, callback);
  }

  /// 安全地执行操作
  void safeExecute(VoidCallback callback) {
    MouseTrackerFix.safeExecute(callback, state: this);
  }
}

/// 扩展方法，为 AnimationController 添加安全操作方法
extension AnimationControllerMouseTrackerFix on AnimationController {
  /// 安全地向前播放动画
  void safeForward() {
    MouseTrackerFix.safeAnimateController(this, forward: true);
  }

  /// 安全地反向播放动画
  void safeReverse() {
    MouseTrackerFix.safeAnimateController(this, forward: false);
  }
}