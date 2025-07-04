import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/music_player/mini_player.dart';

class CommonBottomBar extends StatelessWidget {
  final int currentIndex;

  const CommonBottomBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
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
          currentIndex: currentIndex,
          onTap: (index) {
            // 所有tab都回到主页面，主页面会根据当前选中的tab显示对应内容
            context.pushReplacement('/');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.book), label: "生词本"),
            BottomNavigationBarItem(icon: Icon(Icons.translate), label: "翻译"),
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
    );
  }
}
