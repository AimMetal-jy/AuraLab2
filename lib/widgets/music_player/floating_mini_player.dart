import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/mini_player_service.dart';
import 'unified_player_page.dart';

/// 全局悬浮播放器
/// 当Mini Player被最小化时显示的悬浮球
class FloatingMiniPlayer extends StatelessWidget {
  const FloatingMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioPlayerService, MiniPlayerService>(
      builder: (context, audioService, miniPlayerService, child) {
        // 只有在播放音乐且被最小化时才显示
        if (audioService.currentSong == null ||
            !miniPlayerService.isVisible ||
            !miniPlayerService.isMinimized) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 100, // 留出底部导航栏的空间
          left: 16, // 改为左下角，避免与FloatingActionButton冲突
          child: Tooltip(
            message: '单击: 播放/暂停\n双击: 打开播放器\n长按: 恢复播放条',
            child: GestureDetector(
              onTap: () => _onTap(context, audioService),
              onDoubleTap: () => _openFullPlayer(context, audioService),
              onLongPress: () => miniPlayerService.restore(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center, // 确保所有子组件居中对齐
                  children: [
                    // 圆形进度条 - 使用SizedBox确保大小一致
                    SizedBox(
                      width: 48, // 比容器稍小，留出边距
                      height: 48,
                      child: CircularProgressIndicator(
                        value: audioService.progress,
                        strokeWidth: 2,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    // 播放/暂停按钮
                    Icon(
                      audioService.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, AudioPlayerService audioService) {
    // 如果正在播放，暂停；如果暂停，播放
    audioService.togglePlayPause();
  }

  /// 打开全屏播放器
  void _openFullPlayer(BuildContext context, AudioPlayerService audioService) {
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
}

/// 恢复Mini Player的悬浮按钮
/// 当Mini Player被隐藏时显示
class RestoreMiniPlayerButton extends StatelessWidget {
  const RestoreMiniPlayerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AudioPlayerService, MiniPlayerService>(
      builder: (context, audioService, miniPlayerService, child) {
        // 只有在播放音乐且Mini Player被隐藏（而不是最小化）时才显示
        if (audioService.currentSong == null || miniPlayerService.isVisible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          bottom: 160, // 比悬浮播放器更高一些
          left: 16, // 改为左下角，与悬浮球在同一侧
          child: FloatingActionButton.small(
            onPressed: () => miniPlayerService.show(),
            backgroundColor: Theme.of(
              context,
            ).primaryColor.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
            tooltip: '显示播放器',
            child: const Icon(Icons.music_note, size: 20),
          ),
        );
      },
    );
  }
}
