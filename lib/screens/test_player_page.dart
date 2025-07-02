import 'package:flutter/material.dart';
import '../models/audio_player_model.dart';
import '../screens/audio_lyrics_player_page.dart';

class TestPlayerPage extends StatelessWidget {
  const TestPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('音频播放器测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '音频播放器测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openTestPlayer(context),
              icon: const Icon(Icons.music_note),
              label: const Text('打开测试播放器'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '这是一个测试页面，使用模拟数据来测试音频播放器的各种功能：\n\n'
                '• 歌词同步显示\n'
                '• 单词级高亮\n'
                '• 说话人标签\n'
                '• 播放控制\n'
                '• 播放速度调节\n'
                '• 循环播放',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTestPlayer(BuildContext context) {
    // 使用测试数据
    final testData = AudioPlayData.createTestData();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AudioLyricsPlayerPage(audioData: testData),
      ),
    );
  }
}
