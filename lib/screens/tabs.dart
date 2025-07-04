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
import 'package:auralab_0701/screens/note_list_page.dart';
import 'package:auralab_0701/screens/home.dart';

class Tabs extends StatefulWidget {
  final int initialIndex;

  const Tabs({super.key, this.initialIndex = 2});

  @override
  TabsState createState() => TabsState();
}

class TabsState extends State<Tabs> {
  late int _currentIndex;
  final List<Widget> _pages = [
    VocabularyBookPage(),
    TranslationPage(),
    NoteListPage(showAppBar: false),
    TtsPage(),
    AsrPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  // 添加公共方法来切换tab
  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return "生词本";
      case 1:
        return "翻译";
      case 2:
        return "AuraLab笔记";
      case 3:
        return "文生音频";
      case 4:
        return "音频转字";
      case 5:
        return "音频库";
      default:
        return "AuraLab";
    }
  }

  List<Widget> _getAppBarActions() {
    switch (_currentIndex) {
      case 2: // 笔记页面
        return [];
      default:
        return [];
    }
  }

  Widget _getCurrentPage() {
    // 特殊处理音频库页面
    if (_currentIndex == 5) {
      return HomePage();
    }
    return _pages[_currentIndex];
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
              _getAppBarTitle(),
              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            actions: _getAppBarActions(),
          ),
          body: _getCurrentPage(),
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
                currentIndex: _currentIndex > 4 ? 2 : _currentIndex, // 音频库显示为主页
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
