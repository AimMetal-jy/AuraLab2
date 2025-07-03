import 'package:json_annotation/json_annotation.dart';

part 'audio_player_model.g.dart';

/// 说话人信息
@JsonSerializable()
class Speaker {
  final String id;
  final String? name;
  final String color; // 用于UI显示的颜色

  Speaker({required this.id, this.name, required this.color});

  factory Speaker.fromJson(Map<String, dynamic> json) =>
      _$SpeakerFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakerToJson(this);
}

/// 单词级时间戳信息
@JsonSerializable()
class WordTimestamp {
  final String word;
  final double start;
  final double end;
  final double? confidence;
  final String? speaker;

  WordTimestamp({
    required this.word,
    required this.start,
    required this.end,
    this.confidence,
    this.speaker,
  });

  factory WordTimestamp.fromJson(Map<String, dynamic> json) =>
      _$WordTimestampFromJson(json);

  Map<String, dynamic> toJson() => _$WordTimestampToJson(this);
}

/// 歌词行（句子级别）
@JsonSerializable()
class LyricLine {
  final int id;
  final String text;
  final double start;
  final double end;
  final String? speaker;
  final List<WordTimestamp> words;
  final double? confidence;

  LyricLine({
    required this.id,
    required this.text,
    required this.start,
    required this.end,
    this.speaker,
    required this.words,
    this.confidence,
  });

  factory LyricLine.fromJson(Map<String, dynamic> json) =>
      _$LyricLineFromJson(json);

  Map<String, dynamic> toJson() => _$LyricLineToJson(this);

  /// 检查当前时间是否在这一行的时间范围内
  bool isActiveAtTime(double currentTime) {
    return currentTime >= start && currentTime <= end;
  }

  /// 获取当前时间应该高亮的单词索引
  int? getActiveWordIndex(double currentTime) {
    for (int i = 0; i < words.length; i++) {
      if (currentTime >= words[i].start && currentTime <= words[i].end) {
        return i;
      }
    }
    return null;
  }
}

/// 音频播放数据
@JsonSerializable()
class AudioPlayData {
  final String taskId;
  final String filename;
  final String audioFilePath;
  final String language;
  final List<LyricLine> lyrics;
  final List<Speaker> speakers;
  final double duration;

  AudioPlayData({
    required this.taskId,
    required this.filename,
    required this.audioFilePath,
    required this.language,
    required this.lyrics,
    required this.speakers,
    required this.duration,
  });

  factory AudioPlayData.fromJson(Map<String, dynamic> json) =>
      _$AudioPlayDataFromJson(json);

  Map<String, dynamic> toJson() => _$AudioPlayDataToJson(this);

  /// 根据时间获取当前应该显示的歌词行
  LyricLine? getCurrentLyricLine(double currentTime) {
    for (final line in lyrics) {
      if (line.isActiveAtTime(currentTime)) {
        return line;
      }
    }
    return null;
  }

  /// 根据说话人ID获取说话人信息
  Speaker? getSpeakerById(String speakerId) {
    try {
      return speakers.firstWhere((speaker) => speaker.id == speakerId);
    } catch (e) {
      return null;
    }
  }

  /// 创建测试数据
  static AudioPlayData createTestData() {
    return AudioPlayData(
      taskId: 'test_task',
      filename: 'test_audio.wav',
      audioFilePath: '/test/path/audio.wav',
      language: 'zh',
      duration: 120.0,
      speakers: [
        Speaker(id: 'SPEAKER_00', name: '说话人1', color: '#FF6B6B'),
        Speaker(id: 'SPEAKER_01', name: '说话人2', color: '#4ECDC4'),
      ],
      lyrics: [
        LyricLine(
          id: 0,
          text: '欢迎使用AuraLab音频转文字功能',
          start: 0.0,
          end: 3.0,
          speaker: 'SPEAKER_00',
          confidence: 0.95,
          words: [
            WordTimestamp(
              word: '欢迎',
              start: 0.0,
              end: 0.5,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: '使用',
              start: 0.5,
              end: 1.0,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: 'AuraLab',
              start: 1.0,
              end: 1.8,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: '音频',
              start: 1.8,
              end: 2.2,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: '转',
              start: 2.2,
              end: 2.4,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: '文字',
              start: 2.4,
              end: 2.8,
              speaker: 'SPEAKER_00',
            ),
            WordTimestamp(
              word: '功能',
              start: 2.8,
              end: 3.0,
              speaker: 'SPEAKER_00',
            ),
          ],
        ),
      ],
    );
  }
}

/// 播放器状态
enum PlayerState { stopped, playing, paused, loading, error }

/// 播放器配置
@JsonSerializable()
class PlayerConfig {
  final bool loopEnabled;
  final double playbackSpeed;
  final double volume;
  final bool showWordHighlight;
  final bool showSpeakerLabels;
  final bool delayedLyricsEnabled;
  final double delayedLyricsDelay;

  PlayerConfig({
    this.loopEnabled = true,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.showWordHighlight = true,
    this.showSpeakerLabels = true,
    this.delayedLyricsEnabled = false,
    this.delayedLyricsDelay = 3.0,
  });

  factory PlayerConfig.fromJson(Map<String, dynamic> json) =>
      _$PlayerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerConfigToJson(this);

  PlayerConfig copyWith({
    bool? loopEnabled,
    double? playbackSpeed,
    double? volume,
    bool? showWordHighlight,
    bool? showSpeakerLabels,
    bool? delayedLyricsEnabled,
    double? delayedLyricsDelay,
  }) {
    return PlayerConfig(
      loopEnabled: loopEnabled ?? this.loopEnabled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      showWordHighlight: showWordHighlight ?? this.showWordHighlight,
      showSpeakerLabels: showSpeakerLabels ?? this.showSpeakerLabels,
      delayedLyricsEnabled: delayedLyricsEnabled ?? this.delayedLyricsEnabled,
      delayedLyricsDelay: delayedLyricsDelay ?? this.delayedLyricsDelay,
    );
  }
}
