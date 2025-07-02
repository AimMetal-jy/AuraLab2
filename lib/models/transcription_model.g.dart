// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TranscriptionSubmitResponse _$TranscriptionSubmitResponseFromJson(
  Map<String, dynamic> json,
) => TranscriptionSubmitResponse(
  taskId: json['task_id'] as String,
  status: json['status'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$TranscriptionSubmitResponseToJson(
  TranscriptionSubmitResponse instance,
) => <String, dynamic>{
  'task_id': instance.taskId,
  'status': instance.status,
  'message': instance.message,
};

TranscriptionStatusResponse _$TranscriptionStatusResponseFromJson(
  Map<String, dynamic> json,
) => TranscriptionStatusResponse(
  taskId: json['task_id'] as String,
  status: $enumDecode(_$TranscriptionStatusEnumMap, json['status']),
  message: json['message'] as String?,
  createdAt: TranscriptionStatusResponse._timestampToString(json['created_at']),
  completedAt: TranscriptionStatusResponse._timestampToString(
    json['completed_at'],
  ),
  filename: json['filename'] as String?,
  resultFile: json['result_file'] as String?,
);

Map<String, dynamic> _$TranscriptionStatusResponseToJson(
  TranscriptionStatusResponse instance,
) => <String, dynamic>{
  'task_id': instance.taskId,
  'status': _$TranscriptionStatusEnumMap[instance.status]!,
  'message': instance.message,
  'created_at': instance.createdAt,
  'completed_at': instance.completedAt,
  'filename': instance.filename,
  'result_file': instance.resultFile,
};

const _$TranscriptionStatusEnumMap = {
  TranscriptionStatus.pending: 'pending',
  TranscriptionStatus.processing: 'processing',
  TranscriptionStatus.completed: 'completed',
  TranscriptionStatus.failed: 'failed',
};

TranscriptionTaskListResponse _$TranscriptionTaskListResponseFromJson(
  Map<String, dynamic> json,
) => TranscriptionTaskListResponse(
  tasks: (json['tasks'] as List<dynamic>)
      .map(
        (e) => TranscriptionStatusResponse.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$TranscriptionTaskListResponseToJson(
  TranscriptionTaskListResponse instance,
) => <String, dynamic>{'tasks': instance.tasks, 'total': instance.total};

TranscriptionResult _$TranscriptionResultFromJson(Map<String, dynamic> json) =>
    TranscriptionResult(
      text: json['text'] as String,
      language: json['language'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      segments: (json['segments'] as List<dynamic>?)
          ?.map((e) => TranscriptionSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      words: (json['words'] as List<dynamic>?)
          ?.map((e) => TranscriptionWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TranscriptionResultToJson(
  TranscriptionResult instance,
) => <String, dynamic>{
  'text': instance.text,
  'language': instance.language,
  'confidence': instance.confidence,
  'segments': instance.segments,
  'words': instance.words,
};

TranscriptionSegment _$TranscriptionSegmentFromJson(
  Map<String, dynamic> json,
) => TranscriptionSegment(
  id: (json['id'] as num).toInt(),
  start: (json['start'] as num).toDouble(),
  end: (json['end'] as num).toDouble(),
  text: json['text'] as String,
  confidence: (json['confidence'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TranscriptionSegmentToJson(
  TranscriptionSegment instance,
) => <String, dynamic>{
  'id': instance.id,
  'start': instance.start,
  'end': instance.end,
  'text': instance.text,
  'confidence': instance.confidence,
};

TranscriptionWord _$TranscriptionWordFromJson(Map<String, dynamic> json) =>
    TranscriptionWord(
      word: json['word'] as String,
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TranscriptionWordToJson(TranscriptionWord instance) =>
    <String, dynamic>{
      'word': instance.word,
      'start': instance.start,
      'end': instance.end,
      'confidence': instance.confidence,
    };
