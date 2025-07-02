import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/audio_library_service.dart';

class MusicBar extends StatelessWidget {
  final VoidCallback? onTap;

  const MusicBar({super.key, this.onTap});

  // 显示播放列表对话框
  void _showPlaylistDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const PlaylistDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        // 如果没有正在播放的音乐，不显示MusicBar
        if (audioService.currentSong == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.1),
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
                          (audioService.duration.inMilliseconds * value)
                              .round(),
                    );
                    audioService.seek(newPosition);
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
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // 专辑封面占位符
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 歌曲信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                audioService.currentSong ?? 'Unknown Song',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                audioService.currentArtist ?? 'Unknown Artist',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // 播放控制按钮
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 播放/暂停按钮
                            IconButton(
                              onPressed: () {
                                audioService.togglePlayPause();
                              },
                              icon: Icon(
                                audioService.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 28,
                              ),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                            // 播放列表按钮
                            IconButton(
                              onPressed: () {
                                _showPlaylistDialog(context);
                              },
                              icon: const Icon(Icons.queue_music, size: 20),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
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
}

// 播放列表对话框
class PlaylistDialog extends StatelessWidget {
  const PlaylistDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [Icon(Icons.queue_music), SizedBox(width: 8), Text('当前播放列表')],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Consumer<AudioLibraryService>(
          builder: (context, audioLibraryService, child) {
            final audioItems = audioLibraryService.audioItems;

            if (audioItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '播放列表为空',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '请先在主页添加音频文件',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: audioItems.length,
              itemBuilder: (context, index) {
                final audioItem = audioItems[index];
                return Consumer<AudioPlayerService>(
                  builder: (context, audioService, child) {
                    final isCurrentlyPlaying =
                        audioService.currentSong == audioItem.title;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          audioItem.isTTS
                              ? Icons.record_voice_over
                              : Icons.music_note,
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        audioItem.title,
                        style: TextStyle(
                          fontWeight: isCurrentlyPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        audioItem.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrentlyPlaying
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      trailing: isCurrentlyPlaying
                          ? Icon(
                              audioService.isPlaying
                                  ? Icons.volume_up
                                  : Icons.pause,
                              color: Theme.of(context).primaryColor,
                            )
                          : const Icon(Icons.play_arrow, color: Colors.grey),
                      onTap: () {
                        // 播放选中的音频
                        audioService.playFromFile(
                          audioItem.filePath,
                          songTitle: audioItem.title,
                          artist: audioItem.artist,
                        );
                        Navigator.of(context).pop(); // 关闭对话框
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

// 可点击的进度条组件
class ClickableProgressBar extends StatefulWidget {
  final double progress;
  final ValueChanged<double>? onSeek;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;

  const ClickableProgressBar({
    super.key,
    required this.progress,
    this.onSeek,
    this.backgroundColor,
    this.valueColor,
    this.height = 4.0,
  });

  @override
  State<ClickableProgressBar> createState() => _ClickableProgressBarState();
}

class _ClickableProgressBarState extends State<ClickableProgressBar> {
  bool _isDragging = false;
  double? _dragProgress;

  void _handleSeek(Offset localPosition, double width) {
    if (widget.onSeek != null) {
      final double seekPosition = (localPosition.dx / width).clamp(0.0, 1.0);
      widget.onSeek!(seekPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayProgress = _isDragging
        ? (_dragProgress ?? widget.progress)
        : widget.progress;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        _handleSeek(details.localPosition, box.size.width);
      },
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final double seekPosition = (details.localPosition.dx / box.size.width)
            .clamp(0.0, 1.0);
        setState(() {
          _dragProgress = seekPosition;
        });
      },
      onPanEnd: (details) {
        if (_dragProgress != null && widget.onSeek != null) {
          widget.onSeek!(_dragProgress!);
        }
        setState(() {
          _isDragging = false;
          _dragProgress = null;
        });
      },
      child: Container(
        height: widget.height + 16, // 增加触摸区域
        alignment: Alignment.topCenter, // 顶部对齐
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.grey[300],
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  // 进度条背景
                  Container(
                    width: double.infinity,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ?? Colors.grey[300],
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                  // 进度条前景
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: displayProgress.clamp(0.0, 1.0),
                    child: Container(
                      height: widget.height,
                      decoration: BoxDecoration(
                        color:
                            widget.valueColor ?? Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                  // 拖拽指示器 - 已禁用
                  // Positioned(
                  //   left: (displayProgress.clamp(0.0, 1.0) * constraints.maxWidth - 12).clamp(0.0, constraints.maxWidth - 24),
                  //   top: (widget.height - 24) / 2,
                  //   child: Container(
                  //     width: 24,
                  //     height: 24,
                  //     decoration: BoxDecoration(
                  //       color: widget.valueColor ?? Theme.of(context).primaryColor,
                  //       shape: BoxShape.circle,
                  //       border: Border.all(
                  //         color: Colors.white,
                  //         width: 3,
                  //       ),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: const Color.fromRGBO(0, 0, 0, 0.4),
                  //           blurRadius: 8,
                  //           offset: const Offset(0, 3),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
