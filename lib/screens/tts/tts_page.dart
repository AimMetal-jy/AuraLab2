import 'package:flutter/material.dart';
import 'package:auralab_0701/screens/tts/tts_ai.dart';
import 'package:auralab_0701/screens/tts/tts_local.dart';
class TtsPage extends StatefulWidget {
  const TtsPage({super.key});

  @override
  State<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends State<TtsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("这是文枢工坊的TTS界面")),
      body: Stack(
        children: [
          Positioned(
            bottom: 50,
            right: 40,
            child: FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TtsSender()),
              ),
              child: Icon(Icons.text_format),
            ),
          ),
        ],
      ),
    );
  }
}

class TtsSender extends StatefulWidget {
  const TtsSender({super.key});

  @override
  TtsSenderState createState() => TtsSenderState();
}

class TtsSenderState extends State<TtsSender> {
  int _currentIndex = 0;
  final List<Widget> _pages = [TtsSenderWithAI(), TtsSenderLocal()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("这是TTS Sender界面")),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "AI生成"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "本地上传"),
        ],
      ),
    );
  }
}
