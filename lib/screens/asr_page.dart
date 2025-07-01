import 'package:flutter/material.dart';

class AsrPage extends StatefulWidget {
  const AsrPage({super.key});

  @override
  State<AsrPage> createState() => _AsrPageState();
}

class _AsrPageState extends State<AsrPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("这是文枢工坊的ASR界面"),
        automaticallyImplyLeading: true,
      ),
    );
  }
}
