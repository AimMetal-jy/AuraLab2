import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import 'clickable_progress_bar.dart';
import 'playlist_dialog.dart';
import 'unified_player_page.dart';

/// 迷你播放器组件
/// 显示在底部的小型播放控制栏
class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        // 如果没有正在播放的音乐，不显示迷你播放器
        if (audioService.currentSong == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 进度条 - 位于顶部边界
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClickableProgressBar(
                  progress: audioService.progress,
                  height: 2,
                  backgroundColor: Colors.grey[300],
                  valueColor: Theme.of(context).primaryColor,
                  onSeek: (value) {
                    final newPosition = Duration(
                      milliseconds:
                          (audioService.totalDuration.inMilliseconds * value)
                              .round(),
                    );
                    audioService.seekTo(newPosition);
                  },
                ),
              ),
              // 主要内容区域
              Positioned(
                top: 2, // 为进度条留出空间
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () => _openFullPlayer(context, audioService),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // 专辑封面
                        _buildAlbumCover(audioService),
                        const SizedBox(width: 12),
                        // 歌曲信息
                        _buildSongInfo(audioService),
                        // 播放控制按钮
                        _buildControlButtons(context, audioService),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumCover(AudioPlayerService audioService) {
    // 根据音频类型显示不同的图标
    final isTranscriptionAudio = audioService.audioData != null;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        isTranscriptionAudio ? Icons.record_voice_over : Icons.music_note,
        color: Colors.grey[600],
        size: 20,
      ),
    );
  }

  Widget _buildSongInfo(AudioPlayerService audioService) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            audioService.currentSong ?? 'Unknown Song',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            audioService.currentArtist ?? 'Unknown Artist',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    AudioPlayerService audioService,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 播放/暂停按钮
        IconButton(
          onPressed: () {
            audioService.togglePlayPause();
          },
          icon: Icon(
            audioService.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 28,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        // 播放列表按钮
        IconButton(
          onPressed: () {
            _showPlaylistDialog(context);
          },
          icon: const Icon(Icons.queue_music, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  /// 打开全屏播放器
  void _openFullPlayer(BuildContext context, AudioPlayerService audioService) {
    if (onTap != null) {
      onTap!();
      return;
    }

    // 智能判断音频类型并打开相应的播放器
    final audioData = audioService.audioData;
    final isTranscriptionAudio = audioData != null;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnifiedPlayerPage(
          audioData:
              audioData ??
              {
                'filePath': '', // 这里可能需要从audioService获取当前文件路径
                'title': audioService.currentSong,
                'artist': audioService.currentArtist,
              },
          isTranscriptionAudio: isTranscriptionAudio,
        ),
      ),
    );
  }

  /// 显示播放列表对话框
  void _showPlaylistDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const PlaylistDialog());
  }
}

/// 向后兼容的别名
typedef MusicBar = MiniPlayer;
