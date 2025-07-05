import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:auralab_0701/routes/app_routes.dart';
import 'package:auralab_0701/services/audio_player_service.dart';
import 'package:auralab_0701/services/audio_library_service.dart';
import 'package:auralab_0701/services/background_task_service.dart';
import 'package:auralab_0701/services/mini_player_service.dart';
import 'package:auralab_0701/services/license_service.dart';


void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 注册自定义许可证
  LicenseService.registerLicenses();



  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AudioPlayerService()),
        ChangeNotifierProvider(create: (context) => AudioLibraryService()),
        ChangeNotifierProvider(create: (context) => BackgroundTaskService()),
        ChangeNotifierProvider(create: (context) => MiniPlayerService()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        title: "AuraLab",
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          splashFactory: NoSplash.splashFactory,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),

      ),
    );
  }
}
