import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auralab_0701/routes/app_routes.dart';
import 'package:auralab_0701/services/audio_player_service.dart';
import 'package:auralab_0701/services/audio_library_service.dart';

void main() {
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
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        title: "AuraLab",
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
    );
  }
}
