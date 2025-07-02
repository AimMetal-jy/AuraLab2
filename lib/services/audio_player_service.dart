import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializePlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  // 播放状态
  bool _isPlaying = false;
  bool _isPaused = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentSong;
  String? _currentArtist;
  String? _currentAlbum;
  double _volume = 1.0;
  bool _isShuffle = false;
  bool _isRepeat = false;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentSong => _currentSong;
  String? get currentArtist => _currentArtist;
  String? get currentAlbum => _currentAlbum;
  double get volume => _volume;
  bool get isShuffle => _isShuffle;
  bool get isRepeat => _isRepeat;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  void _initializePlayer() {
    // 监听播放状态变化
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      _isPlaying = state == PlayerState.playing;
      _isPaused = state == PlayerState.paused;
      notifyListeners();
    });

    // 监听播放进度
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      notifyListeners();
    });

    // 监听音频时长
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });

    // 监听播放完成
    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      _isPaused = false;
      _position = Duration.zero;
      if (_isRepeat) {
        play(
          _currentSong!,
          songName: _currentSong,
          artist: _currentArtist,
          album: _currentAlbum,
        );
      } else {
        _isPlaying = false;
        _isPaused = false;
      }
      notifyListeners();
    });
  }

  // 播放音频
  Future<void> play(
    String audioPath, {
    String? songName,
    String? artist,
    String? album,
  }) async {
    try {
      await _audioPlayer.play(AssetSource(audioPath));
      _currentSong = songName ?? 'Unknown Song';
      _currentArtist = artist ?? 'Unknown Artist';
      _currentAlbum = album ?? 'Unknown Album';
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  // 播放本地文件
  Future<void> playFromFile(
    String filePath, {
    String? songTitle,
    String? artist,
    String? album,
  }) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
      _currentSong = songTitle ?? 'Unknown Song';
      _currentArtist = artist ?? 'Unknown Artist';
      _currentAlbum = album ?? 'Unknown Album';
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing file: $e');
      rethrow;
    }
  }

  // 暂停播放
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
  }

  // 恢复播放
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
  }

  // 停止播放
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
      _currentArtist = null;
      _currentAlbum = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  // 跳转到指定位置
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio: $e');
    }
  }

  // 设置音量
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  // 切换随机播放
  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  // 切换重复播放
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    notifyListeners();
  }

  // 播放/暂停切换
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else if (_isPaused) {
      await resume();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
