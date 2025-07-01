import 'package:auralab_0701/screens/home.dart';
import 'package:auralab_0701/utils/drawer.dart';
import 'package:flutter/material.dart';
import 'package:auralab_0701/screens/asr_page.dart';
import 'package:auralab_0701/screens/tts/tts_page.dart';
class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  TabsState createState() => TabsState();
}

class TabsState extends State<Tabs> {
  int _currentIndex = 1;
  final List<Widget> _pages = [
    TtsPage(),
    HomePage(),
    AsrPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("AuraLab", style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
        actions: [
          //IconButton(onPressed: () {}, icon: Icon(Icons.add)),
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
        ],
      ),
      body: _pages[_currentIndex],
      drawer: TabsDrawer(),
      // drawerEdgeDragWidth: MediaQuery.of(context).size.width / 2,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.text_format), label: "文生音频"),//tts
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "主页"),
          BottomNavigationBarItem(icon: Icon(Icons.audio_file), label: "音频转字"),//asr
        ],
      ),
    );
  }
}