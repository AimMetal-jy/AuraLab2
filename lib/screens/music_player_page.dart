import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/audio_player_service.dart';
import '../widgets/music_bar.dart';

class MusicPlayerPage extends StatelessWidget {
  const MusicPlayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '正在播放',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<AudioPlayerService>(
        builder: (context, audioService, child) {
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const Spacer(),
                      // 专辑封面
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Colors.grey[400],
                          size: 80,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // 歌曲信息
                      Text(
                        audioService.currentSong ?? 'Unknown Song',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        audioService.currentArtist ?? 'Unknown Artist',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      // 进度条
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ClickableProgressBar(
                              progress: audioService.progress,
                              height: 6,
                              backgroundColor: Colors.grey[800],
                              valueColor: Colors.white,
                              onSeek: (value) {
                                final newPosition = Duration(
                                  milliseconds: (audioService.duration.inMilliseconds * value).round(),
                                );
                                audioService.seek(newPosition);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(audioService.position),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDuration(audioService.duration),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      // 控制按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              audioService.toggleShuffle();
                            },
                            icon: Icon(
                              Icons.shuffle,
                              color: audioService.isShuffle ? Theme.of(context).primaryColor : Colors.white,
                              size: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.skip_previous,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                audioService.togglePlayPause();
                              },
                              icon: Icon(
                                audioService.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                                size: 32,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.skip_next,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              audioService.toggleRepeat();
                            },
                            icon: Icon(
                              Icons.repeat,
                              color: audioService.isRepeat ? Theme.of(context).primaryColor : Colors.white,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // 音量控制
                      Row(
                        children: [
                          const Icon(
                            Icons.volume_down,
                            color: Colors.white,
                            size: 20,
                          ),
                          Expanded(
                            child: Slider(
                              value: audioService.volume,
                              onChanged: (value) {
                                audioService.setVolume(value);
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.grey[800],
                            ),
                          ),
                          const Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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