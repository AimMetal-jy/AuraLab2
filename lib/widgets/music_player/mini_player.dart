import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/mini_player_service.dart';
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
    return Consumer2<AudioPlayerService, MiniPlayerService>(
      builder: (context, audioService, miniPlayerService, child) {
        // 如果没有正在播放的音乐，不显示迷你播放器
        if (audioService.currentSong == null) {
          return const SizedBox.shrink();
        }

        // 如果Mini Player被隐藏，不显示
        if (!miniPlayerService.isVisible) {
          return const SizedBox.shrink();
        }

        // 如果Mini Player被最小化，只显示一个小的悬浮按钮
        if (miniPlayerService.isMinimized) {
          return _buildMinimizedPlayer(
            context,
            audioService,
            miniPlayerService,
          );
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // 专辑封面
                      _buildAlbumCover(context, audioService),
                      const SizedBox(width: 12),
                      // 歌曲信息（也可以点击进入全屏）
                      _buildSongInfo(context, audioService),
                      // 播放控制按钮
                      _buildControlButtons(
                        context,
                        audioService,
                        miniPlayerService,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumCover(
    BuildContext context,
    AudioPlayerService audioService,
  ) {
    // 根据音频类型显示不同的图标
    final isTranscriptionAudio = audioService.audioData != null;

    return GestureDetector(
      onTap: () => _openFullPlayer(context, audioService),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, AudioPlayerService audioService) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _openFullPlayer(context, audioService),
        behavior: HitTestBehavior.opaque,
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
      ),
    );
  }

  /// 构建最小化状态的播放器
  Widget _buildMinimizedPlayer(
    BuildContext context,
    AudioPlayerService audioService,
    MiniPlayerService miniPlayerService,
  ) {
    return const SizedBox(
      height: 0, // 不占用空间，因为我们将使用全局浮动组件
      width: double.infinity,
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    AudioPlayerService audioService,
    MiniPlayerService miniPlayerService,
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
        // 最小化按钮
        IconButton(
          onPressed: () {
            miniPlayerService.minimize();
          },
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: '最小化',
        ),
        // 隐藏按钮
        IconButton(
          onPressed: () {
            miniPlayerService.hide();
          },
          icon: const Icon(Icons.close, size: 18),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          tooltip: '隐藏播放器',
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

    if (audioData != null) {
      // 如果有audioData，说明是通过AudioPlayerService播放的音频
      final isTranscriptionAudio = audioData.lyrics.isNotEmpty;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => UnifiedPlayerPage(
            audioData: audioData,
            isTranscriptionAudio: isTranscriptionAudio,
          ),
        ),
      );
    } else {
      // 如果没有audioData，说明没有正在播放的音频
      debugPrint('没有正在播放的音频数据');
    }
  }

  /// 显示播放列表对话框
  void _showPlaylistDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const PlaylistDialog());
  }
}

/// 向后兼容的别名
typedef MusicBar = MiniPlayer;
