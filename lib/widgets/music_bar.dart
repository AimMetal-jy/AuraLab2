import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class MusicBar extends StatelessWidget {
  final VoidCallback? onTap;
  
  const MusicBar({super.key, this.onTap});

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
                      milliseconds: (audioService.duration.inMilliseconds * value).round(),
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
                            // 关闭按钮
                            IconButton(
                              onPressed: () {
                                audioService.stop();
                              },
                              icon: const Icon(
                                Icons.close,
                                size: 20,
                              ),
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
    final displayProgress = _isDragging ? (_dragProgress ?? widget.progress) : widget.progress;
    
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
        final double seekPosition = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
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
        height: widget.height + 8, // 适度增加触摸区域
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
                        color: widget.valueColor ?? Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(widget.height / 2),
                      ),
                    ),
                  ),
                  // 拖拽指示器
                  if (_isDragging)
                    Positioned(
                      left: (displayProgress.clamp(0.0, 1.0) * constraints.maxWidth - 6).clamp(0.0, constraints.maxWidth - 12),
                      top: (widget.height - 12) / 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: widget.valueColor ?? Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromRGBO(0, 0, 0, 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}