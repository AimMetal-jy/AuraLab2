import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audio_player_model.dart';
import '../services/audio_player_service.dart';

class AudioLyricsPlayerPage extends StatefulWidget {
  final AudioPlayData audioData;

  const AudioLyricsPlayerPage({super.key, required this.audioData});

  @override
  State<AudioLyricsPlayerPage> createState() => _AudioLyricsPlayerPageState();
}

class _AudioLyricsPlayerPageState extends State<AudioLyricsPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _lyricsAnimationController;
  late ScrollController _lyricsScrollController;
  bool _isInitialized = false;

  // 添加：自动滚动相关状态变量
  int? _previousActiveLyricId; // 跟踪上一个活跃歌词行ID
  bool _isUserScrolling = false; // 跟踪用户是否正在手动滚动
  Timer? _autoScrollTimer; // 自动滚动定时器
  bool _autoScrollEnabled = true; // 控制自动滚动是否启用
  bool _isUserClickedLyric = false; // 跟踪用户是否刚刚点击了歌词
  Timer? _userClickTimer; // 用户点击后的定时器
  final Map<int, GlobalKey> _lyricKeys = {}; // 为每个歌词行创建GlobalKey

  @override
  void initState() {
    super.initState();
    _lyricsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _lyricsScrollController = ScrollController();

    // 添加：监听用户滚动事件
    _lyricsScrollController.addListener(_onUserScroll);

    // 使用 WidgetsBinding 来确保 Provider 已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  // 添加：处理用户滚动事件
  void _onUserScroll() {
    if (_lyricsScrollController.position.isScrollingNotifier.value) {
      _isUserScrolling = true;
      // 用户滚动3秒后恢复自动滚动
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _isUserScrolling = false;
        }
      });
    }
  }

  // 添加：自动滚动到当前歌词行
  void _scrollToCurrentLyric(int lyricIndex) {
    if (!_autoScrollEnabled || _isUserScrolling || _isUserClickedLyric) {
      return;
    }

    final key = _lyricKeys[lyricIndex];
    if (key?.currentContext != null) {
      // 使用Flutter的ensureVisible方法，确保widget在屏幕中央可见
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // 0.5表示居中对齐
      );
    }
  }

  // 添加：强制滚动到指定歌词行（用于用户点击）
  void _forceScrollToLyric(int lyricIndex) {
    final key = _lyricKeys[lyricIndex];
    if (key?.currentContext != null) {
      // 使用Flutter的ensureVisible方法，确保widget在屏幕中央可见
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.5, // 0.5表示居中对齐
      );
    }
  }

  // 添加：处理用户点击歌词的逻辑
  void _onUserClickLyric(LyricLine lyricLine, AudioPlayerService player) {
    // 立即更新状态以防止自动滚动冲突
    _previousActiveLyricId = lyricLine.id;
    _isUserClickedLyric = true;

    // 取消之前的定时器
    _userClickTimer?.cancel();

    // 立即滚动到用户点击的歌词行（使用强制滚动）
    _forceScrollToLyric(lyricLine.id);

    // 播放器跳转到对应时间
    player.seekToLyricLine(lyricLine);

    // 1.5秒后恢复自动滚动（给播放器足够时间更新状态）
    _userClickTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _isUserClickedLyric = false;
      }
    });
  }

  Future<void> _initializePlayer() async {
    final playerService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );
    try {
      await playerService.loadAudioData(widget.audioData);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
      if (mounted) {
        // 可以选择显示错误信息或直接关闭页面
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(flex: 3, child: _buildLyricsArea()),
            _buildPlayerControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.audioData.filename,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.audioData.language.toUpperCase()} • ${widget.audioData.speakers.length} 说话人',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Consumer<AudioPlayerService>(
            builder: (context, player, child) {
              return IconButton(
                onPressed: () => _showSettingsDialog(),
                icon: const Icon(Icons.settings, color: Colors.white),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsArea() {
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

        // 添加：检查当前歌词行是否发生变化，如果是则自动滚动
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
            controller: _lyricsScrollController,
            physics: const BouncingScrollPhysics(), // 改进：使用更平滑的滚动物理效果
            itemCount: lyrics.length,
            itemBuilder: (context, index) {
              final lyricLine = lyrics[index];
              final isActive = player.currentLyricLine?.id == lyricLine.id;
              final speaker = widget.audioData.getSpeakerById(
                lyricLine.speaker ?? '',
              );

              // 为每个歌词行创建或获取GlobalKey
              _lyricKeys[lyricLine.id] ??= GlobalKey();

              return GestureDetector(
                key: _lyricKeys[lyricLine.id],
                onTap: () => _onUserClickLyric(lyricLine, player),
                child: AnimatedContainer(
                  // 改进：添加动画效果
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.15) // 稍微增加活跃行的背景色
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isActive
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2, // 增加边框宽度以突出当前行
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

  Widget _buildPlayerControls() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 进度条
              _buildProgressBar(player),
              const SizedBox(height: 24),
              // 播放控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 播放速度
                  GestureDetector(
                    onTap: () => _showSpeedDialog(player),
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
                  ),
                  // 上一句
                  IconButton(
                    onPressed: () => _seekToPreviousLine(player),
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
                  // 下一句
                  IconButton(
                    onPressed: () => _seekToNextLine(player),
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  // 循环播放
                  IconButton(
                    onPressed: () =>
                        player.setLoopEnabled(!player.config.loopEnabled),
                    icon: Icon(
                      Icons.repeat,
                      color: player.config.loopEnabled
                          ? Colors.white
                          : Colors.white54,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(AudioPlayerService player) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: player.progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * player.totalDuration.inMilliseconds)
                    .round(),
              );
              player.seekTo(position);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                player.currentTimeString,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                player.totalTimeString,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _togglePlayPause(AudioPlayerService player) {
    if (player.playerState == PlayerState.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seekToPreviousLine(AudioPlayerService player) {
    final lyrics = widget.audioData.lyrics;
    if (lyrics.isEmpty) return;

    final currentIndex = player.currentLyricLine?.id ?? 0;
    if (currentIndex > 0) {
      final targetLyric = lyrics[currentIndex - 1];
      _onUserClickLyric(targetLyric, player);
    }
  }

  void _seekToNextLine(AudioPlayerService player) {
    final lyrics = widget.audioData.lyrics;
    if (lyrics.isEmpty) return;

    final currentIndex = player.currentLyricLine?.id ?? -1;
    if (currentIndex < lyrics.length - 1) {
      final targetLyric = lyrics[currentIndex + 1];
      _onUserClickLyric(targetLyric, player);
    }
  }

  void _showSpeedDialog(AudioPlayerService player) {
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<AudioPlayerService>(
        builder: (context, player, child) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text(
                  '播放设置',
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text(
                        '单词高亮',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: player.config.showWordHighlight,
                      onChanged: player.setWordHighlight,
                      activeColor: Colors.white,
                    ),
                    SwitchListTile(
                      title: const Text(
                        '说话人标签',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: player.config.showSpeakerLabels,
                      onChanged: player.setSpeakerLabels,
                      activeColor: Colors.white,
                    ),
                    SwitchListTile(
                      title: const Text(
                        '循环播放',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: player.config.loopEnabled,
                      onChanged: player.setLoopEnabled,
                      activeColor: Colors.white,
                    ),
                    // 添加：自动滚动开关
                    SwitchListTile(
                      title: const Text(
                        '歌词自动滚动',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        '跟随播放进度自动滚动到中央',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: _autoScrollEnabled,
                      onChanged: (value) {
                        setDialogState(() {
                          _autoScrollEnabled = value;
                        });
                        setState(() {
                          _autoScrollEnabled = value;
                        });
                      },
                      activeColor: Colors.white,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '关闭',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          );
        },
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

  @override
  void dispose() {
    _autoScrollTimer?.cancel(); // 添加：清理定时器
    _userClickTimer?.cancel(); // 添加：清理用户点击定时器
    _lyricsScrollController.removeListener(_onUserScroll); // 添加：移除监听器
    _lyricKeys.clear(); // 清理歌词Key缓存
    _lyricsAnimationController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }
}
