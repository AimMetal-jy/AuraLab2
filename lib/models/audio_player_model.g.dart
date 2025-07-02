// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_player_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Speaker _$SpeakerFromJson(Map<String, dynamic> json) => Speaker(
  id: json['id'] as String,
  name: json['name'] as String?,
  color: json['color'] as String,
);

Map<String, dynamic> _$SpeakerToJson(Speaker instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
};

WordTimestamp _$WordTimestampFromJson(Map<String, dynamic> json) =>
    WordTimestamp(
      word: json['word'] as String,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      speaker: json['speaker'] as String?,
    );

Map<String, dynamic> _$WordTimestampToJson(WordTimestamp instance) =>
    <String, dynamic>{
      'word': instance.word,
      'start': instance.start,
      'end': instance.end,
      'confidence': instance.confidence,
      'speaker': instance.speaker,
    };

LyricLine _$LyricLineFromJson(Map<String, dynamic> json) => LyricLine(
  id: (json['id'] as num).toInt(),
  text: json['text'] as String,
  start: (json['start'] as num).toDouble(),
  end: (json['end'] as num).toDouble(),
  speaker: json['speaker'] as String?,
  words: (json['words'] as List<dynamic>)
      .map((e) => WordTimestamp.fromJson(e as Map<String, dynamic>))
      .toList(),
  confidence: (json['confidence'] as num?)?.toDouble(),
);

Map<String, dynamic> _$LyricLineToJson(LyricLine instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'start': instance.start,
  'end': instance.end,
  'speaker': instance.speaker,
  'words': instance.words,
  'confidence': instance.confidence,
};

AudioPlayData _$AudioPlayDataFromJson(Map<String, dynamic> json) =>
    AudioPlayData(
      taskId: json['taskId'] as String,
      filename: json['filename'] as String,
      audioFilePath: json['audioFilePath'] as String,
      language: json['language'] as String,
      lyrics: (json['lyrics'] as List<dynamic>)
          .map((e) => LyricLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      speakers: (json['speakers'] as List<dynamic>)
          .map((e) => Speaker.fromJson(e as Map<String, dynamic>))
          .toList(),
      duration: (json['duration'] as num).toDouble(),
    );

Map<String, dynamic> _$AudioPlayDataToJson(AudioPlayData instance) =>
    <String, dynamic>{
      'taskId': instance.taskId,
      'filename': instance.filename,
      'audioFilePath': instance.audioFilePath,
      'language': instance.language,
      'lyrics': instance.lyrics,
      'speakers': instance.speakers,
      'duration': instance.duration,
    };

PlayerConfig _$PlayerConfigFromJson(Map<String, dynamic> json) => PlayerConfig(
  loopEnabled: json['loopEnabled'] as bool? ?? true,
  playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
  volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
  showWordHighlight: json['showWordHighlight'] as bool? ?? true,
  showSpeakerLabels: json['showSpeakerLabels'] as bool? ?? true,
);

Map<String, dynamic> _$PlayerConfigToJson(PlayerConfig instance) =>
    <String, dynamic>{
      'loopEnabled': instance.loopEnabled,
      'playbackSpeed': instance.playbackSpeed,
      'volume': instance.volume,
      'showWordHighlight': instance.showWordHighlight,
      'showSpeakerLabels': instance.showSpeakerLabels,
    };
