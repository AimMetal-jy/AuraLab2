import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:auralab_0701/routes/app_routes.dart';
import 'package:auralab_0701/services/audio_player_service.dart';
import 'package:auralab_0701/services/audio_library_service.dart';
import 'package:auralab_0701/config/performance_config.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 启用高刷新率支持
  await _configureHighRefreshRate();

  runApp(const MyApp());
}

/// 配置高刷新率支持
Future<void> _configureHighRefreshRate() async {
  try {
    // 使用性能配置类配置系统UI
    await PerformanceConfig.configureSystemUI();

    // 设置首选方向（可选）
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    debugPrint('高刷新率配置完成');
  } catch (e) {
    debugPrint('高刷新率配置失败: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioPlayerService()),
        ChangeNotifierProvider(create: (context) => AudioLibraryService()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        title: "AuraLab",
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          splashFactory: NoSplash.splashFactory,
          // 启用高性能渲染
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // 优化动画性能 - 使用120Hz优化的动画持续时间
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _HighRefreshRatePageTransitionsBuilder(),
              TargetPlatform.iOS: _HighRefreshRatePageTransitionsBuilder(),
            },
          ),
        ),
        // 启用高刷新率的构建器
        builder: (context, child) {
          // 检查并显示当前刷新率（调试用）
          if (PerformanceConfig.isHighRefreshRateSupported(context)) {
            final refreshRate = PerformanceConfig.getCurrentRefreshRate(
              context,
            );
            debugPrint('当前刷新率: ${refreshRate}Hz');
          }

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // 确保文本缩放不会影响性能
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

/// 针对高刷新率优化的页面过渡构建器
class _HighRefreshRatePageTransitionsBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return PerformanceConfig.buildPageTransition(
      context: context,
      animation: animation,
      child: child,
    );
  }
}
