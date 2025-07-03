import 'package:auralab_0701/screens/home.dart';
import 'package:auralab_0701/widgets/drawer.dart';
import 'package:flutter/material.dart';
import 'package:auralab_0701/screens/asr_page.dart';
import 'package:auralab_0701/screens/tts/tts_page.dart';
import 'package:auralab_0701/screens/vocabulary_book_page.dart';
import 'package:auralab_0701/screens/translation_page.dart';
import 'package:auralab_0701/widgets/music_player/music_player.dart';
import 'package:auralab_0701/widgets/music_player/floating_mini_player.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:auralab_0701/services/background_task_service.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  TabsState createState() => TabsState();
}

class TabsState extends State<Tabs> {
  int _currentIndex = 2;
  final List<Widget> _pages = [
    VocabularyBookPage(),
    TranslationPage(),
    HomePage(),
    TtsPage(),
    AsrPage(),
  ];

  @override
  void initState() {
    super.initState();
    // 在下一帧设置BackgroundTaskService的context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final backgroundTaskService = Provider.of<BackgroundTaskService>(
          context,
          listen: false,
        );
        backgroundTaskService.setContext(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要的Scaffold内容
        Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              "AuraLab",
              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            actions: [
              //IconButton(onPressed: () {}, icon: Icon(Icons.add)),
              IconButton(onPressed: () {}, icon: Icon(Icons.search)),
            ],
          ),
          body: _pages[_currentIndex],
          drawer: TabsDrawer(),
          // drawerEdgeDragWidth: MediaQuery.of(context).size.width / 2,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 全局音乐播放器横条
              MiniPlayer(
                onTap: () {
                  context.push('/music-player');
                },
              ),
              // 底部导航栏
              BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.book), label: "生词本"),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.translate),
                    label: "翻译",
                  ),
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: "主页"),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.text_format),
                    label: "文生音频",
                  ), //tts
                  BottomNavigationBarItem(
                    icon: Icon(Icons.audio_file),
                    label: "音频转字",
                  ), //asr
                ],
              ),
            ],
          ),
        ),
        // 全局悬浮播放器
        const FloatingMiniPlayer(),
        // 恢复Mini Player的按钮
        const RestoreMiniPlayerButton(),
      ],
    );
  }
}
