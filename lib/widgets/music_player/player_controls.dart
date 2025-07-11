import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_player_model.dart';
import '../../services/audio_player_service.dart';
import '../../services/audio_library_service.dart';
import 'progress_bar.dart';
import 'playlist_dialog.dart';

/// 统一的播放控制组件
class PlayerControls extends StatelessWidget {
  final bool isTranscriptionAudio;
  final dynamic audioData;
  final VoidCallback? onSettingsPressed;
  final bool showProgressBar;

  const PlayerControls({
    super.key,
    required this.isTranscriptionAudio,
    this.audioData,
    this.onSettingsPressed,
    this.showProgressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 进度条（只在歌词视图时显示）
              if (showProgressBar) ...[
                UnifiedProgressBar(),
                const SizedBox(height: 24),
              ],
              // 播放控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 播放速度（转录音频才显示）
                  if (isTranscriptionAudio)
                    GestureDetector(
                      onTap: () => _showSpeedDialog(context, player),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${player.config.playbackSpeed}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  else
                    // 普通音频显示随机播放
                    IconButton(
                      onPressed: () => player.toggleShuffle(),
                      icon: Icon(
                        Icons.shuffle,
                        color: player.isShuffle ? Colors.white : Colors.white54,
                        size: 24,
                      ),
                    ),

                  // 上一句/上一首
                  IconButton(
                    onPressed: () => _seekToPrevious(context, player),
                    icon: const Icon(
                      Icons.skip_previous,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  // 播放/暂停
                  GestureDetector(
                    onTap: () => _togglePlayPause(player),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        player.playerState == PlayerState.playing
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),

                  // 下一句/下一首
                  IconButton(
                    onPressed: () => _seekToNext(context, player),
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  // 循环播放/播放列表
                  if (isTranscriptionAudio)
                    IconButton(
                      onPressed: () => _toggleRepeat(player),
                      icon: Icon(
                        Icons.repeat,
                        color: _getRepeatColor(player),
                        size: 24,
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () => _showPlaylist(context),
                      icon: const Icon(
                        Icons.queue_music,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),

              // 音量控制（普通音频才显示）
              if (!isTranscriptionAudio) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.volume_down,
                      color: Colors.white,
                      size: 20,
                    ),
                    Expanded(
                      child: Slider(
                        value: player.volume,
                        onChanged: (value) => player.setVolume(value),
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey[800],
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white, size: 20),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _togglePlayPause(AudioPlayerService player) {
    if (player.playerState == PlayerState.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seekToPrevious(BuildContext context, AudioPlayerService player) {
    if (isTranscriptionAudio && audioData is AudioPlayData) {
      final data = audioData as AudioPlayData;
      final lyrics = data.lyrics;
      if (lyrics.isEmpty) return;

      final currentIndex = player.currentLyricLine?.id ?? 0;
      if (currentIndex > 0) {
        final targetLyric = lyrics[currentIndex - 1];
        player.seekToLyricLine(targetLyric);
      }
    } else {
      // 普通音频：播放上一首
      _playPreviousInPlaylist(context, player);
    }
  }

  void _seekToNext(BuildContext context, AudioPlayerService player) {
    if (isTranscriptionAudio && audioData is AudioPlayData) {
      final data = audioData as AudioPlayData;
      final lyrics = data.lyrics;
      if (lyrics.isEmpty) return;

      final currentIndex = player.currentLyricLine?.id ?? -1;
      if (currentIndex < lyrics.length - 1) {
        final targetLyric = lyrics[currentIndex + 1];
        player.seekToLyricLine(targetLyric);
      }
    } else {
      // 普通音频：播放下一首
      _playNextInPlaylist(context, player);
    }
  }

  void _playPreviousInPlaylist(
    BuildContext context,
    AudioPlayerService player,
  ) {
    final audioLibrary = Provider.of<AudioLibraryService>(
      context,
      listen: false,
    );
    final audioItems = audioLibrary.audioItems;

    if (audioItems.isEmpty) return;

    // 找到当前播放的音频在列表中的位置
    int currentIndex = audioItems.indexWhere(
      (item) => item.title == player.currentSong,
    );

    if (currentIndex == -1) {
      // 如果找不到当前歌曲，播放第一首
      final firstItem = audioItems.first;
      player.playFromFile(
        firstItem.filePath,
        songTitle: firstItem.title,
        artist: firstItem.artist,
      );
    } else if (currentIndex > 0) {
      // 播放上一首
      final previousItem = audioItems[currentIndex - 1];
      player.playFromFile(
        previousItem.filePath,
        songTitle: previousItem.title,
        artist: previousItem.artist,
      );
    } else {
      // 已经是第一首，循环到最后一首
      final lastItem = audioItems.last;
      player.playFromFile(
        lastItem.filePath,
        songTitle: lastItem.title,
        artist: lastItem.artist,
      );
    }
  }

  void _playNextInPlaylist(BuildContext context, AudioPlayerService player) {
    final audioLibrary = Provider.of<AudioLibraryService>(
      context,
      listen: false,
    );
    final audioItems = audioLibrary.audioItems;

    if (audioItems.isEmpty) return;

    // 找到当前播放的音频在列表中的位置
    int currentIndex = audioItems.indexWhere(
      (item) => item.title == player.currentSong,
    );

    if (currentIndex == -1) {
      // 如果找不到当前歌曲，播放第一首
      final firstItem = audioItems.first;
      player.playFromFile(
        firstItem.filePath,
        songTitle: firstItem.title,
        artist: firstItem.artist,
      );
    } else if (currentIndex < audioItems.length - 1) {
      // 播放下一首
      final nextItem = audioItems[currentIndex + 1];
      player.playFromFile(
        nextItem.filePath,
        songTitle: nextItem.title,
        artist: nextItem.artist,
      );
    } else {
      // 已经是最后一首，循环到第一首
      final firstItem = audioItems.first;
      player.playFromFile(
        firstItem.filePath,
        songTitle: firstItem.title,
        artist: firstItem.artist,
      );
    }
  }

  void _toggleRepeat(AudioPlayerService player) {
    if (isTranscriptionAudio) {
      player.setLoopEnabled(!player.config.loopEnabled);
    } else {
      player.toggleRepeat();
    }
  }

  Color _getRepeatColor(AudioPlayerService player) {
    if (isTranscriptionAudio) {
      return player.config.loopEnabled ? Colors.white : Colors.white54;
    } else {
      return player.isRepeat ? Colors.white : Colors.white54;
    }
  }

  void _showPlaylist(BuildContext context) {
    showDialog(context: context, builder: (context) => const PlaylistDialog());
  }

  void _showSpeedDialog(BuildContext context, AudioPlayerService player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('播放速度', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text(
                '${speed}x',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                player.setPlaybackSpeed(speed);
                Navigator.of(context).pop();
              },
              trailing: player.config.playbackSpeed == speed
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}
