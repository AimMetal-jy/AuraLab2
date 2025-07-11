import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import '../models/audio_player_model.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializePlayer();
  }

  late ap.AudioPlayer _audioPlayer;

  // 播放状态
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // 播放数据
  AudioPlayData? _audioData;
  PlayerConfig _config = PlayerConfig();

  // 当前歌词状态
  LyricLine? _currentLyricLine;
  int? _currentWordIndex;

  // 延迟歌词状态
  LyricLine? _delayedLyricLine;
  Timer? _delayedLyricsTimer;

  // 流订阅
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<ap.PlayerState>? _stateSubscription;

  // Getters
  PlayerState get playerState => _playerState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  AudioPlayData? get audioData => _audioData;
  PlayerConfig get config => _config;
  LyricLine? get currentLyricLine => _currentLyricLine;
  int? get currentWordIndex => _currentWordIndex;
  LyricLine? get delayedLyricLine => _delayedLyricLine;

  double get currentTimeInSeconds => _currentPosition.inMilliseconds / 1000.0;
  double get totalTimeInSeconds => _totalDuration.inMilliseconds / 1000.0;
  double get progress => _totalDuration.inMilliseconds > 0
      ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
      : 0.0;

  // 向后兼容的接口
  String? get currentSong => _audioData?.filename;
  String? get currentArtist => _audioData?.language.toUpperCase();
  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _totalDuration;
  Duration get position => _currentPosition;
  double get volume => _config.volume;
  bool get isShuffle => false; // 不支持随机播放
  bool get isRepeat => _config.loopEnabled;

  void _initializePlayer() {
    _audioPlayer = ap.AudioPlayer();

    // 监听播放位置
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      _updateLyricSync();
      notifyListeners();
    });

    // 监听总时长
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    // 监听播放状态
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case ap.PlayerState.stopped:
          _playerState = PlayerState.stopped;
          break;
        case ap.PlayerState.playing:
          _playerState = PlayerState.playing;
          break;
        case ap.PlayerState.paused:
          _playerState = PlayerState.paused;
          break;
        case ap.PlayerState.completed:
          _onPlayCompleted();
          break;
        case ap.PlayerState.disposed:
          _playerState = PlayerState.stopped;
          break;
      }
      notifyListeners();
    });
  }

  /// 加载音频数据
  Future<void> loadAudioData(AudioPlayData audioData) async {
    try {
      _playerState = PlayerState.loading;
      notifyListeners();

      _audioData = audioData;

      // 检查音频文件是否存在
      if (!File(audioData.audioFilePath).existsSync()) {
        throw Exception('音频文件不存在: ${audioData.audioFilePath}');
      }

      // 加载音频文件
      await _audioPlayer.setSource(
        ap.DeviceFileSource(audioData.audioFilePath),
      );

      _playerState = PlayerState.stopped;
      _currentPosition = Duration.zero;
      _currentLyricLine = null;
      _currentWordIndex = null;

      notifyListeners();
    } catch (e) {
      _playerState = PlayerState.error;
      notifyListeners();
      debugPrint('加载音频失败: $e');
      rethrow;
    }
  }

  /// 播放
  Future<void> play() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('播放失败: $e');
      _playerState = PlayerState.error;
      notifyListeners();
    }
  }

  /// 暂停
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('暂停失败: $e');
    }
  }

  /// 停止
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentPosition = Duration.zero;
      _currentLyricLine = null;
      _currentWordIndex = null;
      notifyListeners();
    } catch (e) {
      debugPrint('停止失败: $e');
    }
  }

  /// 完全清除音频数据和播放状态
  Future<void> clearAudioData() async {
    try {
      await _audioPlayer.stop();
      _playerState = PlayerState.stopped;
      _currentPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _audioData = null;
      _currentLyricLine = null;
      _currentWordIndex = null;
      notifyListeners();
    } catch (e) {
      debugPrint('清除音频数据失败: $e');
    }
  }

  /// 检查当前音频文件是否仍然有效
  bool isCurrentAudioValid() {
    if (_audioData == null) return false;
    return File(_audioData!.audioFilePath).existsSync();
  }

  /// 验证并处理无效的音频文件
  Future<void> validateCurrentAudio() async {
    if (_audioData != null && !isCurrentAudioValid()) {
      debugPrint('当前音频文件已无效，清除播放器状态: ${_audioData!.audioFilePath}');
      await clearAudioData();
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _updateLyricSync();
    } catch (e) {
      debugPrint('跳转失败: $e');
    }
  }

  /// 跳转到指定时间（秒）
  Future<void> seekToSeconds(double seconds) async {
    final position = Duration(milliseconds: (seconds * 1000).round());
    await seekTo(position);
  }

  /// 跳转到指定歌词行
  Future<void> seekToLyricLine(LyricLine lyricLine) async {
    final position = Duration(milliseconds: (lyricLine.start * 1000).round());
    await seekTo(position);
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setPlaybackRate(speed);
      _config = _config.copyWith(playbackSpeed: speed);
      notifyListeners();
    } catch (e) {
      debugPrint('设置播放速度失败: $e');
    }
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      _config = _config.copyWith(volume: volume);
      notifyListeners();
    } catch (e) {
      debugPrint('设置音量失败: $e');
    }
  }

  /// 设置循环播放
  void setLoopEnabled(bool enabled) {
    _config = _config.copyWith(loopEnabled: enabled);
    notifyListeners();
  }

  /// 设置单词高亮显示
  void setWordHighlight(bool enabled) {
    _config = _config.copyWith(showWordHighlight: enabled);
    notifyListeners();
  }

  /// 设置说话人标签显示
  void setSpeakerLabels(bool enabled) {
    _config = _config.copyWith(showSpeakerLabels: enabled);
    notifyListeners();
  }

  /// 设置延迟歌词开关
  void setDelayedLyricsEnabled(bool enabled) {
    _config = _config.copyWith(delayedLyricsEnabled: enabled);
    if (enabled) {
      if (!hasTimestampData()) {
        // 如果没有时间戳数据，关闭功能
        _config = _config.copyWith(delayedLyricsEnabled: false);
        debugPrint('该音频文件没有时间戳数据，无法使用延迟歌词功能');
      } else {
        _updateDelayedLyricSync();
      }
    } else {
      _delayedLyricLine = null;
      _delayedLyricsTimer?.cancel();
    }
    notifyListeners();
  }

  /// 设置延迟歌词延迟时间
  void setDelayedLyricsDelay(double delay) {
    _config = _config.copyWith(delayedLyricsDelay: delay);
    if (_config.delayedLyricsEnabled) {
      _updateDelayedLyricSync();
    }
    notifyListeners();
  }

  /// 检查是否有时间戳数据
  bool hasTimestampData() {
    return _audioData != null &&
        _audioData!.lyrics.isNotEmpty &&
        _audioData!.lyrics.any((line) => line.words.isNotEmpty);
  }

  /// 播放完成处理
  void _onPlayCompleted() {
    if (_config.loopEnabled) {
      // 循环播放
      seekTo(Duration.zero);
      play();
    } else {
      _playerState = PlayerState.stopped;
      _currentPosition = Duration.zero;
      _currentLyricLine = null;
      _currentWordIndex = null;
    }
  }

  /// 更新歌词同步
  void _updateLyricSync() {
    if (_audioData == null) return;

    final currentTimeSeconds = currentTimeInSeconds;

    // 更新当前歌词行
    final newLyricLine = _audioData!.getCurrentLyricLine(currentTimeSeconds);
    if (newLyricLine != _currentLyricLine) {
      _currentLyricLine = newLyricLine;
    }

    // 更新当前高亮单词
    if (_currentLyricLine != null && _config.showWordHighlight) {
      final newWordIndex = _currentLyricLine!.getActiveWordIndex(
        currentTimeSeconds,
      );
      if (newWordIndex != _currentWordIndex) {
        _currentWordIndex = newWordIndex;
      }
    }

    // 更新延迟歌词
    if (_config.delayedLyricsEnabled) {
      _updateDelayedLyricSync();
    }
  }

  /// 更新延迟歌词同步
  void _updateDelayedLyricSync() {
    if (_audioData == null) return;

    final currentTimeSeconds = currentTimeInSeconds;

    // 计算所有歌词的调整后显示时间，避免重叠
    final adjustedLyrics = _calculateAdjustedDelayedLyrics();

    // 找到当前应该显示的延迟歌词
    LyricLine? candidateLyric;
    for (final lyricInfo in adjustedLyrics) {
      // 检查当前时间是否在调整后的显示时间范围内
      if (currentTimeSeconds >= lyricInfo['adjustedStartTime'] &&
          currentTimeSeconds < lyricInfo['adjustedEndTime']) {
        candidateLyric = lyricInfo['lyric'] as LyricLine;
        break; // 找到当前应该显示的歌词，直接退出循环
      }
    }

    // 更新延迟歌词
    if (candidateLyric != _delayedLyricLine) {
      _delayedLyricLine = candidateLyric;
    }

    // 如果音频已经播放完毕，检查是否还有未显示的歌词
    if (_playerState == PlayerState.stopped) {
      _scheduleRemainingLyrics();
    }
  }

  /// 计算调整后的延迟歌词显示时间，避免重叠
  List<Map<String, dynamic>> _calculateAdjustedDelayedLyrics() {
    if (_audioData == null) return [];

    final lyrics = _audioData!.lyrics;
    final adjustedLyrics = <Map<String, dynamic>>[];
    double lastEndTime = 0.0;

    for (final line in lyrics) {
      // 计算原始的延迟显示时间
      final originalDelayedStartTime = line.end + _config.delayedLyricsDelay;
      final originalDisplayDuration = line.end - line.start;

      // 避免与前一句重叠，确保至少间隔0.5秒
      final adjustedStartTime = originalDelayedStartTime > lastEndTime + 0.5
          ? originalDelayedStartTime
          : lastEndTime + 0.5;

      // 保持原始显示时长，但至少显示2秒
      final minDisplayDuration = 2.0;
      final displayDuration = originalDisplayDuration > minDisplayDuration
          ? originalDisplayDuration
          : minDisplayDuration;

      final adjustedEndTime = adjustedStartTime + displayDuration;

      adjustedLyrics.add({
        'lyric': line,
        'originalDelayedStartTime': originalDelayedStartTime,
        'adjustedStartTime': adjustedStartTime,
        'adjustedEndTime': adjustedEndTime,
        'displayDuration': displayDuration,
      });

      lastEndTime = adjustedEndTime;
    }

    return adjustedLyrics;
  }

  /// 调度剩余歌词显示（音频播放完后继续显示歌词）
  void _scheduleRemainingLyrics() {
    if (_audioData == null || !_config.delayedLyricsEnabled) return;

    final currentTimeSeconds = currentTimeInSeconds;
    final adjustedLyrics = _calculateAdjustedDelayedLyrics();

    // 找到下一个应该显示的歌词行
    Map<String, dynamic>? nextLyricInfo;

    for (final lyricInfo in adjustedLyrics) {
      final lyric = lyricInfo['lyric'] as LyricLine;
      final adjustedStartTime = lyricInfo['adjustedStartTime'] as double;

      // 如果这个句子还没到显示时间，且还没被显示过
      if (adjustedStartTime > currentTimeSeconds &&
          (_delayedLyricLine == null || lyric.id > _delayedLyricLine!.id)) {
        nextLyricInfo = lyricInfo;
        break;
      }
    }

    if (nextLyricInfo != null) {
      final nextLyricLine = nextLyricInfo['lyric'] as LyricLine;
      final nextShowTime = nextLyricInfo['adjustedStartTime'] as double;
      final displayDuration = nextLyricInfo['displayDuration'] as double;

      final delayToShow = nextShowTime - currentTimeSeconds;
      _delayedLyricsTimer?.cancel();

      // 调度显示下一句歌词
      _delayedLyricsTimer = Timer(
        Duration(milliseconds: (delayToShow * 1000).round()),
        () {
          _delayedLyricLine = nextLyricLine;
          notifyListeners();

          // 调度隐藏当前歌词（在调整后的显示时长结束后）
          Timer(Duration(milliseconds: (displayDuration * 1000).round()), () {
            if (_delayedLyricLine == nextLyricLine) {
              _delayedLyricLine = null;
              notifyListeners();
            }
            _scheduleRemainingLyrics(); // 递归调度下一行
          });
        },
      );
    }
  }

  /// 获取播放时间的格式化字符串
  String getFormattedTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 获取当前播放时间的格式化字符串
  String get currentTimeString => getFormattedTime(_currentPosition);

  /// 获取总时长的格式化字符串
  String get totalTimeString => getFormattedTime(_totalDuration);

  /// 获取进度字符串
  String get progressString => '$currentTimeString / $totalTimeString';

  /// 获取调整后的延迟歌词信息（供外部使用）
  List<Map<String, dynamic>> get adjustedDelayedLyrics =>
      _calculateAdjustedDelayedLyrics();

  /// 获取下一个即将显示的延迟歌词信息
  Map<String, dynamic>? getNextDelayedLyricInfo() {
    if (_audioData == null || !_config.delayedLyricsEnabled) return null;

    final currentTimeSeconds = currentTimeInSeconds;
    final adjustedLyrics = _calculateAdjustedDelayedLyrics();

    for (final lyricInfo in adjustedLyrics) {
      final adjustedStartTime = lyricInfo['adjustedStartTime'] as double;
      final lyric = lyricInfo['lyric'] as LyricLine;

      if (adjustedStartTime > currentTimeSeconds &&
          (_delayedLyricLine == null || lyric.id > _delayedLyricLine!.id)) {
        return lyricInfo;
      }
    }
    return null;
  }

  // 向后兼容的方法

  /// 播放指定路径的音频文件（兼容旧版API）
  Future<void> playFromFile(
    String filePath, {
    String? songTitle,
    String? artist,
  }) async {
    try {
      // 检查文件是否存在
      if (!File(filePath).existsSync()) {
        throw Exception('音频文件不存在: $filePath');
      }

      // 创建简单的音频数据
      final audioData = AudioPlayData(
        taskId: 'compat_${DateTime.now().millisecondsSinceEpoch}',
        filename: songTitle ?? 'Unknown',
        audioFilePath: filePath,
        language: artist ?? 'Unknown',
        lyrics: [],
        speakers: [],
        duration: 0.0, // 将在加载时更新
      );

      await loadAudioData(audioData);
      await play();
    } catch (e) {
      debugPrint('播放文件失败: $e');
      // 如果播放失败，清除可能的错误状态
      _playerState = PlayerState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// 兼容旧版的play方法（重载版本）
  Future<void> playFile(
    String filePath, {
    String? songName,
    String? artist,
  }) async {
    await playFromFile(filePath, songTitle: songName, artist: artist);
  }

  /// 跳转到指定位置（兼容旧版API）
  Future<void> seek(Duration position) async {
    await seekTo(position);
  }

  /// 切换播放/暂停状态
  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// 切换随机播放（空实现，保持兼容性）
  void toggleShuffle() {
    // 空实现，不支持随机播放
    debugPrint('随机播放功能未实现');
  }

  /// 切换重复播放
  void toggleRepeat() {
    setLoopEnabled(!_config.loopEnabled);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _delayedLyricsTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// 音频播放器工具类
class AudioPlayerUtils {
  /// 从WhisperX数据创建AudioPlayData
  static AudioPlayData createFromWhisperXData({
    required String taskId,
    required String filename,
    required String audioFilePath,
    required Map<String, dynamic> transcriptionData,
    required Map<String, dynamic> wordstampsData,
    Map<String, dynamic>? speakerData,
  }) {
    final language = transcriptionData['language'] ?? 'unknown';

    // 解析歌词行
    final segments = wordstampsData['segments'] as List? ?? [];
    final lyrics = <LyricLine>[];
    final speakersSet = <String>{};

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final words = <WordTimestamp>[];

      // 解析单词级时间戳
      final wordsList = segment['words'] as List? ?? [];
      for (final wordData in wordsList) {
        final word = WordTimestamp(
          word: wordData['word'] ?? '',
          start: (wordData['start'] ?? 0.0).toDouble(),
          end: (wordData['end'] ?? 0.0).toDouble(),
          confidence: (wordData['score'] ?? wordData['confidence'])?.toDouble(),
          speaker: wordData['speaker'],
        );
        words.add(word);

        if (word.speaker != null) {
          speakersSet.add(word.speaker!);
        }
      }

      final lyricLine = LyricLine(
        id: i,
        text: segment['text'] ?? '',
        start: (segment['start'] ?? 0.0).toDouble(),
        end: (segment['end'] ?? 0.0).toDouble(),
        speaker: segment['speaker'],
        words: words,
        confidence: (segment['score'] ?? segment['confidence'])?.toDouble(),
      );

      lyrics.add(lyricLine);

      if (lyricLine.speaker != null) {
        speakersSet.add(lyricLine.speaker!);
      }
    }

    // 创建说话人列表
    final speakers = <Speaker>[];
    final colors = [
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#96CEB4',
      '#FFEAA7',
      '#DDA0DD',
      '#98D8C8',
      '#F7DC6F',
      '#BB8FCE',
      '#85C1E9',
    ];

    int colorIndex = 0;
    for (final speakerId in speakersSet) {
      speakers.add(
        Speaker(
          id: speakerId,
          name: speakerId,
          color: colors[colorIndex % colors.length],
        ),
      );
      colorIndex++;
    }

    return AudioPlayData(
      taskId: taskId,
      filename: filename,
      audioFilePath: audioFilePath,
      language: language,
      lyrics: lyrics,
      speakers: speakers,
      duration: _estimateAudioDuration(lyrics),
    );
  }

  /// 估算音频时长
  static double _estimateAudioDuration(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return 0.0;
    return lyrics.map((line) => line.end).reduce((a, b) => a > b ? a : b);
  }
}
