import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "文枢工坊主页",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 40),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.music_note,
                    size: 48,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "全局音乐播放器测试",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "点击下方按钮播放测试音频",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final audioService = Provider.of<AudioPlayerService>(context, listen: false);
                      audioService.play(
                        'audio/English_Pod_30s.wav',
                        songName: 'English Pod Sample',
                        artist: 'Test Audio',
                        album: 'Sample Album',
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放测试音频'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<AudioPlayerService>(
                    builder: (context, audioService, child) {
                      if (audioService.currentSong != null) {
                        return Column(
                          children: [
                            Text(
                              '正在播放: ${audioService.currentSong}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDuration(audioService.position)} / ${_formatDuration(audioService.duration)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
}