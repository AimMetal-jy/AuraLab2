import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_player_model.dart';
import '../../services/audio_player_service.dart';

/// 延迟歌词显示组件
class DelayedLyricsDisplay extends StatefulWidget {
  final AudioPlayData audioData;

  const DelayedLyricsDisplay({super.key, required this.audioData});

  @override
  State<DelayedLyricsDisplay> createState() => _DelayedLyricsDisplayState();
}

class _DelayedLyricsDisplayState extends State<DelayedLyricsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  LyricLine? _currentDisplayedLyric;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLyricChange(LyricLine? newLyric) {
    if (newLyric != _currentDisplayedLyric) {
      _currentDisplayedLyric = newLyric;

      if (newLyric != null) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        final delayedLyric = player.delayedLyricLine;

        // 处理歌词变化
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleLyricChange(delayedLyric);
        });

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 延迟时间提示
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '延迟 ${player.config.delayedLyricsDelay.toStringAsFixed(1)}s (防重叠优化)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // 歌词显示区域
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: _buildLyricContent(delayedLyric, player),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricContent(LyricLine? lyric, AudioPlayerService player) {
    if (lyric == null) {
      // 找到下一个即将显示的歌词
      final nextLyric = _getNextDelayedLyric(player);
      if (nextLyric != null) {
        final timeToShow = _getTimeUntilNextLyric(player, nextLyric);
        if (timeToShow > 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '等待歌词显示...',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '下一句预告:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"${nextLyric.text}"',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${timeToShow.toStringAsFixed(1)}秒后显示',
                      style: TextStyle(
                        color: Colors.amber.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      }

      return Text(
        '等待歌词显示...',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      );
    }

    final speaker = widget.audioData.getSpeakerById(lyric.speaker ?? '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 说话人标签
        if (speaker != null && player.config.showSpeakerLabels) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(speaker.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  speaker.name ?? speaker.id,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 歌词文本
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            lyric.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // 置信度指示器
        if (lyric.confidence != null && lyric.confidence! < 0.8)
          Container(
            margin: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.orange.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  '识别置信度: ${(lyric.confidence! * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.orange.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      final hexColor = colorString.replaceFirst('#', '');
      return Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// 获取下一个即将显示的延迟歌词
  LyricLine? _getNextDelayedLyric(AudioPlayerService player) {
    final nextLyricInfo = player.getNextDelayedLyricInfo();
    return nextLyricInfo?['lyric'] as LyricLine?;
  }

  /// 计算距离下一句歌词显示还有多长时间
  double _getTimeUntilNextLyric(
    AudioPlayerService player,
    LyricLine nextLyric,
  ) {
    final nextLyricInfo = player.getNextDelayedLyricInfo();
    if (nextLyricInfo != null) {
      final currentTime = player.currentTimeInSeconds;
      final adjustedStartTime = nextLyricInfo['adjustedStartTime'] as double;
      return adjustedStartTime - currentTime;
    }

    // 备用计算方式（不应该执行到这里）
    final currentTime = player.currentTimeInSeconds;
    final delayedStartTime = nextLyric.end + player.config.delayedLyricsDelay;
    return delayedStartTime - currentTime;
  }
}
