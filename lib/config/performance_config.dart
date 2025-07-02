import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 高性能配置类
class PerformanceConfig {
  /// 标准动画持续时间（针对120Hz优化）
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 350);

  /// 高刷新率优化的动画曲线
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve fastCurve = Curves.easeOutQuart;
  static const Curve bounceCurve = Curves.elasticOut;

  /// 为120Hz优化的页面过渡
  static Widget buildPageTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Widget child,
  }) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: smoothCurve)),
      ),
      child: child,
    );
  }

  /// 高性能的淡入动画
  static Widget buildFadeTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: fastCurve)),
      child: child,
    );
  }

  /// 缩放动画（针对按钮等交互元素）
  static Widget buildScaleTransition({
    required Animation<double> animation,
    required Widget child,
  }) {
    return ScaleTransition(
      scale: animation.drive(
        Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: bounceCurve)),
      ),
      child: child,
    );
  }

  /// 配置系统UI以获得最佳性能
  static Future<void> configureSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top],
    );

    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 检查设备是否支持高刷新率
  static bool isHighRefreshRateSupported(BuildContext context) {
    final view = View.of(context);
    return view.display.refreshRate > 60.0;
  }

  /// 获取当前刷新率
  static double getCurrentRefreshRate(BuildContext context) {
    final view = View.of(context);
    return view.display.refreshRate;
  }

  /// 为列表滚动优化的物理效果
  static const ScrollPhysics optimizedScrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  /// 高性能的阴影配置
  static List<BoxShadow> get optimizedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// 高性能的圆角配置
  static BorderRadius get standardRadius => BorderRadius.circular(12);
  static BorderRadius get smallRadius => BorderRadius.circular(8);
  static BorderRadius get largeRadius => BorderRadius.circular(16);
}
