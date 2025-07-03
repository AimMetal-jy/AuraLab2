import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_player_model.dart';
import '../../services/audio_player_service.dart';

/// 歌词显示组件
class LyricsDisplay extends StatefulWidget {
  final AudioPlayData audioData;
  final bool autoScrollEnabled;
  final ValueChanged<bool>? onAutoScrollChanged;

  const LyricsDisplay({
    super.key,
    required this.audioData,
    this.autoScrollEnabled = true,
    this.onAutoScrollChanged,
  });

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;
  Timer? _userClickTimer;

  bool _isUserScrolling = false;
  bool _isUserClickedLyric = false;
  int? _previousActiveLyricId;

  final Map<int, GlobalKey> _lyricKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onUserScroll);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _userClickTimer?.cancel();
    _scrollController.removeListener(_onUserScroll);
    _scrollController.dispose();
    _lyricKeys.clear();
    super.dispose();
  }

  void _onUserScroll() {
    if (_scrollController.position.isScrollingNotifier.value) {
      _isUserScrolling = true;
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isUserScrolling = false;
          });
        }
      });
    }
  }

  void _scrollToCurrentLyric(int lyricIndex) {
    if (!widget.autoScrollEnabled || _isUserScrolling || _isUserClickedLyric) {
      return;
    }

    final key = _lyricKeys[lyricIndex];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _forceScrollToLyric(int lyricIndex) {
    final key = _lyricKeys[lyricIndex];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    }
  }

  void _onUserClickLyric(LyricLine lyricLine, AudioPlayerService player) {
    _previousActiveLyricId = lyricLine.id;
    _isUserClickedLyric = true;

    _userClickTimer?.cancel();
    _forceScrollToLyric(lyricLine.id);
    player.seekToLyricLine(lyricLine);

    _userClickTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isUserClickedLyric = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        final lyrics = widget.audioData.lyrics;

        if (lyrics.isEmpty) {
          return const Center(
            child: Text(
              '暂无歌词',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
          );
        }

        // 检查当前歌词行是否发生变化
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentActiveLyric = player.currentLyricLine;
          if (currentActiveLyric != null &&
              currentActiveLyric.id != _previousActiveLyricId &&
              !_isUserClickedLyric) {
            _previousActiveLyricId = currentActiveLyric.id;
            _scrollToCurrentLyric(currentActiveLyric.id);
          }
        });

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            itemCount: lyrics.length,
            itemBuilder: (context, index) {
              final lyricLine = lyrics[index];
              final isActive = player.currentLyricLine?.id == lyricLine.id;
              final speaker = widget.audioData.getSpeakerById(
                lyricLine.speaker ?? '',
              );

              _lyricKeys[lyricLine.id] ??= GlobalKey();

              return GestureDetector(
                key: _lyricKeys[lyricLine.id],
                onTap: () => _onUserClickLyric(lyricLine, player),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          )
                        : null,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 说话人标签
                      if (speaker != null && player.config.showSpeakerLabels)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
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
                                  color: _parseColor(speaker.color),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // 歌词文本
                      _buildLyricText(lyricLine, player, isActive),
                      // 时间戳
                      const SizedBox(height: 4),
                      Text(
                        '${_formatTime(lyricLine.start)} - ${_formatTime(lyricLine.end)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLyricText(
    LyricLine lyricLine,
    AudioPlayerService player,
    bool isActive,
  ) {
    if (!player.config.showWordHighlight || !isActive) {
      return Text(
        lyricLine.text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: isActive ? 20 : 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          height: 1.5,
        ),
      );
    }

    // 单词级高亮
    return RichText(
      text: TextSpan(
        children: lyricLine.words.asMap().entries.map((entry) {
          final index = entry.key;
          final word = entry.value;
          final isHighlighted = player.currentWordIndex == index;

          return TextSpan(
            text: '${word.word} ',
            style: TextStyle(
              color: isHighlighted ? Colors.yellow : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              backgroundColor: isHighlighted
                  ? Colors.yellow.withValues(alpha: 0.2)
                  : null,
              height: 1.5,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _parseColor(String colorString) {
    final hexColor = colorString.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
