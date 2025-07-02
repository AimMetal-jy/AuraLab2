import 'package:json_annotation/json_annotation.dart';

part 'transcription_model.g.dart';

/// 转录模型类型枚举
enum TranscriptionModel {
  @JsonValue('bluelm')
  bluelm,
  @JsonValue('whisperx')
  whisperx,
}

/// 转录任务状态枚举
enum TranscriptionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

/// 转录任务提交响应
@JsonSerializable()
class TranscriptionSubmitResponse {
  @JsonKey(name: 'task_id')
  final String taskId;
  final String? status;
  final String? message;

  TranscriptionSubmitResponse({
    required this.taskId,
    this.status,
    this.message,
  });

  factory TranscriptionSubmitResponse.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionSubmitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionSubmitResponseToJson(this);
}

/// 转录任务状态查询响应
@JsonSerializable()
class TranscriptionStatusResponse {
  @JsonKey(name: 'task_id')
  final String taskId;
  final TranscriptionStatus status;
  final String? message;
  @JsonKey(name: 'created_at', fromJson: _timestampToString)
  final String? createdAt;
  @JsonKey(name: 'completed_at', fromJson: _timestampToString)
  final String? completedAt;
  final String? filename;
  @JsonKey(name: 'result_file')
  final String? resultFile;

  TranscriptionStatusResponse({
    required this.taskId,
    required this.status,
    this.message,
    this.createdAt,
    this.completedAt,
    this.filename,
    this.resultFile,
  });

  // 时间戳转换函数：支持double和String类型
  static String? _timestampToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) {
      // 将Unix时间戳转换为可读字符串
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).toInt(),
      );
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    }
    return value.toString();
  }

  factory TranscriptionStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionStatusResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionStatusResponseToJson(this);
}

/// 转录任务列表响应
@JsonSerializable()
class TranscriptionTaskListResponse {
  final List<TranscriptionStatusResponse> tasks;
  final int total;

  TranscriptionTaskListResponse({required this.tasks, required this.total});

  factory TranscriptionTaskListResponse.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionTaskListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionTaskListResponseToJson(this);
}

/// 转录结果数据
@JsonSerializable()
class TranscriptionResult {
  final String text;
  final String? language;
  final double? confidence;
  final List<TranscriptionSegment>? segments;
  final List<TranscriptionWord>? words;

  TranscriptionResult({
    required this.text,
    this.language,
    this.confidence,
    this.segments,
    this.words,
  });

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionResultFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionResultToJson(this);
}

/// 转录分段信息
@JsonSerializable()
class TranscriptionSegment {
  final int id;
  final double start;
  final double end;
  final String text;
  final double? confidence;

  TranscriptionSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
    this.confidence,
  });

  factory TranscriptionSegment.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionSegmentToJson(this);
}

/// 转录词汇信息
@JsonSerializable()
class TranscriptionWord {
  final String word;
  final double start;
  final double end;
  final double? confidence;

  TranscriptionWord({
    required this.word,
    required this.start,
    required this.end,
    this.confidence,
  });

  factory TranscriptionWord.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionWordFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptionWordToJson(this);
}
