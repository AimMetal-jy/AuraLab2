import 'package:flutter/material.dart';
import 'package:auralab_0701/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: "AuraLab",
      theme: ThemeData(platform: TargetPlatform.iOS,splashFactory: NoSplash.splashFactory,),
    );
  }
}