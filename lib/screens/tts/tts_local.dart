import 'package:flutter/material.dart';
class TtsSenderLocal extends StatefulWidget {
  const TtsSenderLocal({super.key});

  @override
  TtsSenderLocalState createState() => TtsSenderLocalState();
}

class TtsSenderLocalState extends State<TtsSenderLocal> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("自行上传文件"), automaticallyImplyLeading: false),
    );
  }
}