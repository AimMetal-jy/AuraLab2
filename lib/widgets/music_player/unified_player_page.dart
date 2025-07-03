import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/audio_player_model.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/custom_toast.dart';
import 'player_controls.dart';
import 'lyrics_display.dart';
import 'delayed_lyrics_display.dart';
import 'progress_bar.dart';
import 'player_settings.dart';

/// 统一的音频播放器页面
/// 支持普通音频播放和转录音频播放
class UnifiedPlayerPage extends StatefulWidget {
  /// 音频数据，如果是AudioPlayData类型则支持歌词功能
  final dynamic audioData;

  /// 是否来自转录（决定是否显示转录相关功能）
  final bool isTranscriptionAudio;

  const UnifiedPlayerPage({
    super.key,
    required this.audioData,
    this.isTranscriptionAudio = false,
  });

  @override
  State<UnifiedPlayerPage> createState() => _UnifiedPlayerPageState();
}

class _UnifiedPlayerPageState extends State<UnifiedPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  bool _isInitialized = false;
  bool _showLyrics = false;

  // 转录音频相关
  Timer? _autoScrollTimer;
  bool _autoScrollEnabled = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  Future<void> _initializePlayer() async {
    final playerService = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    );

    try {
      if (widget.isTranscriptionAudio && widget.audioData is AudioPlayData) {
        // 转录音频：加载完整的转录数据
        await playerService.loadAudioData(widget.audioData as AudioPlayData);
        _showLyrics = true;
      } else {
        // 普通音频：只播放文件
        String filePath;
        String? songTitle;
        String? artist;

        if (widget.audioData is Map<String, dynamic>) {
          final data = widget.audioData as Map<String, dynamic>;
          filePath = data['filePath'] ?? data['path'] ?? '';
          songTitle = data['title'] ?? data['songTitle'];
          artist = data['artist'];
        } else if (widget.audioData is String) {
          filePath = widget.audioData as String;
          songTitle = filePath.split('/').last;
        } else {
          throw Exception('不支持的音频数据类型');
        }

        await playerService.playFromFile(
          filePath,
          songTitle: songTitle,
          artist: artist,
        );
        _showLyrics = false;
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _fadeController.forward();
      }
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _showLyrics ? _buildLyricsView() : _buildPlayerView(),
              ),
              PlayerControls(
                isTranscriptionAudio: widget.isTranscriptionAudio,
                audioData: _showLyrics ? widget.audioData : null,
                onSettingsPressed: _showSettings,
                showProgressBar: _showLyrics, // 只在歌词视图时显示进度条
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
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
            child: Consumer<AudioPlayerService>(
              builder: (context, player, child) {
                return Column(
                  children: [
                    Text(
                      _getDisplayTitle(player),
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
                      _getDisplaySubtitle(player),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 切换视图按钮（如果支持歌词）
          if (widget.isTranscriptionAudio && widget.audioData is AudioPlayData)
            IconButton(
              onPressed: _toggleView,
              icon: Icon(
                _showLyrics ? Icons.music_note : Icons.lyrics,
                color: Colors.white,
              ),
              tooltip: _showLyrics ? '切换到播放器' : '切换到歌词',
            ),
          // 延迟歌词开关（如果支持歌词）
          if (widget.isTranscriptionAudio && widget.audioData is AudioPlayData)
            Consumer<AudioPlayerService>(
              builder: (context, player, child) {
                return IconButton(
                  onPressed: () => _toggleDelayedLyrics(player),
                  icon: Icon(
                    player.config.delayedLyricsEnabled
                        ? Icons.schedule
                        : Icons.schedule_outlined,
                    color: player.config.delayedLyricsEnabled
                        ? Colors.amber
                        : Colors.white,
                  ),
                  tooltip: player.config.delayedLyricsEnabled
                      ? '关闭延迟歌词'
                      : '开启延迟歌词',
                );
              },
            ),
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerView() {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return Padding(
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
                      color: Colors.black.withValues(alpha: 0.3),
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
                player.currentSong ?? '未知歌曲',
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
                player.currentArtist ?? '未知艺术家',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // 进度条
              UnifiedProgressBar(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLyricsView() {
    if (widget.audioData is! AudioPlayData) {
      return const Center(
        child: Text(
          '无歌词数据',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        if (player.config.delayedLyricsEnabled) {
          return DelayedLyricsDisplay(
            audioData: widget.audioData as AudioPlayData,
          );
        } else {
          return LyricsDisplay(
            audioData: widget.audioData as AudioPlayData,
            autoScrollEnabled: _autoScrollEnabled,
            onAutoScrollChanged: (enabled) {
              setState(() {
                _autoScrollEnabled = enabled;
              });
            },
          );
        }
      },
    );
  }

  void _toggleView() {
    setState(() {
      _showLyrics = !_showLyrics;
    });
  }

  void _toggleDelayedLyrics(AudioPlayerService player) {
    final newEnabled = !player.config.delayedLyricsEnabled;

    if (newEnabled && !player.hasTimestampData()) {
      // 如果没有时间戳数据，显示toast提示
      CustomToast.show(
        context,
        message: '该音频文件没有时间戳数据，无法使用延迟歌词功能',
        type: ToastType.warning,
      );
      return;
    }

    player.setDelayedLyricsEnabled(newEnabled);
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => PlayerSettingsDialog(
        isTranscriptionAudio: widget.isTranscriptionAudio,
        autoScrollEnabled: _autoScrollEnabled,
        onAutoScrollChanged: (enabled) {
          setState(() {
            _autoScrollEnabled = enabled;
          });
        },
      ),
    );
  }

  String _getDisplayTitle(AudioPlayerService player) {
    if (widget.isTranscriptionAudio && widget.audioData is AudioPlayData) {
      return (widget.audioData as AudioPlayData).filename;
    }
    return player.currentSong ?? '正在播放';
  }

  String _getDisplaySubtitle(AudioPlayerService player) {
    if (widget.isTranscriptionAudio && widget.audioData is AudioPlayData) {
      final data = widget.audioData as AudioPlayData;
      return '${data.language.toUpperCase()} • ${data.speakers.length} 说话人';
    }
    return player.currentArtist ?? '音频播放';
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
