import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'transcription_service.dart';
import 'audio_library_service.dart';
import '../models/transcription_model.dart';
import '../widgets/custom_toast.dart';

/// 后台任务管理服务
/// 负责管理ASR和TTS的长时间运行任务，确保任务可以在后台继续执行
class BackgroundTaskService extends ChangeNotifier {
  static final BackgroundTaskService _instance =
      BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  final TranscriptionService _transcriptionService = TranscriptionService();
  final AudioLibraryService _audioLibraryService = AudioLibraryService();

  // 任务状态管理
  final Map<String, BackgroundTask> _tasks = {};
  Timer? _globalTimer;

  // Toast通知相关
  BuildContext? _context;

  // 获取所有任务
  List<BackgroundTask> get tasks => _tasks.values.toList();

  // 获取进行中的任务
  List<BackgroundTask> get activeTasks =>
      _tasks.values.where((task) => task.isActive).toList();

  // 获取特定任务
  BackgroundTask? getTask(String taskId) => _tasks[taskId];

  /// 设置用于显示Toast的Context
  void setContext(BuildContext context) {
    _context = context;
  }

  /// 显示完成通知
  void _showCompletionToast(BackgroundTask task) {
    if (_context == null) return;

    String message;
    ToastType type;

    if (task.status == TaskStatus.completed) {
      switch (task.type) {
        case TaskType.asr:
          message = '音频转录完成：${task.fileName ?? '未知文件'}';
          break;
        case TaskType.tts:
          message = 'TTS语音生成完成';
          break;
      }
      type = ToastType.success;
    } else if (task.status == TaskStatus.failed) {
      switch (task.type) {
        case TaskType.asr:
          message = '音频转录失败：${task.fileName ?? '未知文件'}';
          break;
        case TaskType.tts:
          message = 'TTS语音生成失败';
          break;
      }
      type = ToastType.error;
    } else if (task.status == TaskStatus.timeout) {
      message = '任务超时：${task.title}';
      type = ToastType.warning;
    } else {
      return;
    }

    try {
      CustomToast.show(
        _context!,
        message: message,
        type: type,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('显示Toast失败: $e');
    }
  }

  /// 添加ASR转录任务
  Future<String> addAsrTask({
    required String audioFilePath,
    required String fileName,
    required TranscriptionModel model,
    required String taskId,
    String? language,
    String? computeType,
    bool enableWordTimestamps = true,
    bool enableSpeakerDiarization = false,
    String modelName = 'small',
  }) async {
    final task = BackgroundTask(
      id: taskId,
      type: TaskType.asr,
      title: '转录音频: $fileName',
      description:
          '正在使用${model == TranscriptionModel.whisperx ? 'WhisperX' : 'BlueLM'}进行转录...',
      audioFilePath: audioFilePath,
      fileName: fileName,
      model: model,
      language: language,
      computeType: computeType,
      enableWordTimestamps: enableWordTimestamps,
      enableSpeakerDiarization: enableSpeakerDiarization,
      modelName: modelName,
    );

    _tasks[taskId] = task;
    notifyListeners();

    _startGlobalTimer();
    return taskId;
  }

  /// 添加TTS生成任务
  Future<String> addTtsTask({
    required String text,
    required String voiceName,
    required String mode,
  }) async {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = BackgroundTask(
      id: taskId,
      type: TaskType.tts,
      title:
          'TTS生成: ${text.length > 20 ? '${text.substring(0, 20)}...' : text}',
      description: '正在使用$voiceName生成语音...',
      text: text,
      voiceName: voiceName,
      mode: mode,
    );

    _tasks[taskId] = task;
    notifyListeners();

    _startGlobalTimer();
    return taskId;
  }

  /// 开始全局定时器
  void _startGlobalTimer() {
    if (_globalTimer != null && _globalTimer!.isActive) return;

    _globalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAllTasks();
    });
  }

  /// 检查所有任务状态
  Future<void> _checkAllTasks() async {
    final activeTasks = _tasks.values.where((task) => task.isActive).toList();

    if (activeTasks.isEmpty) {
      _globalTimer?.cancel();
      _globalTimer = null;
      return;
    }

    for (final task in activeTasks) {
      try {
        await _checkTaskStatus(task);
      } catch (e) {
        debugPrint('检查任务${task.id}状态失败: $e');
        task.errorCount++;
        if (task.errorCount >= 3) {
          task.status = TaskStatus.failed;
          task.description = '任务失败: $e';
          _showCompletionToast(task);
          notifyListeners();
        }
      }
    }
  }

  /// 检查单个任务状态
  Future<void> _checkTaskStatus(BackgroundTask task) async {
    task.pollAttempts++;

    if (task.type == TaskType.asr) {
      await _checkAsrTask(task);
    } else if (task.type == TaskType.tts) {
      await _checkTtsTask(task);
    }

    // 检查超时
    if (task.pollAttempts >= 300) {
      // 5分钟超时
      task.status = TaskStatus.timeout;
      task.description = '任务超时';
      _showCompletionToast(task);
      notifyListeners();
    }
  }

  /// 检查ASR任务
  Future<void> _checkAsrTask(BackgroundTask task) async {
    final statusResponse = await _transcriptionService.getTaskStatus(
      task.id,
      task.model!,
    );

    task.status = _convertTranscriptionStatus(statusResponse.status);
    task.description =
        statusResponse.message ?? _getStatusText(statusResponse.status);

    if (statusResponse.status == TranscriptionStatus.completed) {
      await _completeAsrTask(task);
    } else if (statusResponse.status == TranscriptionStatus.failed) {
      task.status = TaskStatus.failed;
      _showCompletionToast(task);
    }

    notifyListeners();
  }

  /// 检查TTS任务
  Future<void> _checkTtsTask(BackgroundTask task) async {
    // TTS任务的逻辑会根据具体的TTS服务实现
    // 这里是示例实现
    task.description = '正在生成语音文件...';

    // 模拟TTS处理完成
    if (task.pollAttempts > 5) {
      task.status = TaskStatus.completed;
      task.description = '语音生成完成';
      _showCompletionToast(task);
      notifyListeners();
    }
  }

  /// 完成ASR任务
  Future<void> _completeAsrTask(BackgroundTask task) async {
    try {
      final result = await _transcriptionService.downloadTranscriptionResult(
        task.id,
        task.model!,
      );

      // 保存到音频库
      await _saveAsrToAudioLibrary(task, result);

      task.status = TaskStatus.completed;
      task.description = '转录完成并已保存到音频库';
      task.result = result;

      // 显示完成通知
      _showCompletionToast(task);
    } catch (e) {
      task.status = TaskStatus.failed;
      task.description = '保存转录结果失败: $e';

      // 显示失败通知
      _showCompletionToast(task);
    }
  }

  /// 保存ASR结果到音频库
  Future<void> _saveAsrToAudioLibrary(
    BackgroundTask task,
    String transcriptionResult,
  ) async {
    String modelName = task.model == TranscriptionModel.whisperx
        ? 'WhisperX-${task.modelName}'
        : 'BlueLM';

    String playerDataJson = transcriptionResult;

    // 对于WhisperX，尝试获取完整的播放器数据
    if (task.model == TranscriptionModel.whisperx) {
      try {
        final playerData = await _transcriptionService.getWhisperXPlayerData(
          task.id,
        );
        if (playerData != null) {
          playerDataJson = json.encode({
            'type': 'whisperx_player_data',
            'taskId': task.id,
            'filename': task.fileName ?? 'audio.wav',
            'modelName': modelName,
            'playerData': playerData,
          });
        }
      } catch (e) {
        debugPrint('获取WhisperX播放器数据失败: $e');
      }
    }

    await _audioLibraryService.addASRAudio(
      task.audioFilePath!,
      playerDataJson,
      modelName: modelName,
    );
  }

  /// 移除任务
  void removeTask(String taskId) {
    _tasks.remove(taskId);
    notifyListeners();
  }

  /// 清空所有已完成的任务
  void clearCompletedTasks() {
    _tasks.removeWhere(
      (key, task) =>
          task.status == TaskStatus.completed ||
          task.status == TaskStatus.failed ||
          task.status == TaskStatus.timeout,
    );
    notifyListeners();
  }

  /// 转换转录状态
  TaskStatus _convertTranscriptionStatus(TranscriptionStatus status) {
    switch (status) {
      case TranscriptionStatus.pending:
        return TaskStatus.pending;
      case TranscriptionStatus.processing:
        return TaskStatus.processing;
      case TranscriptionStatus.completed:
        return TaskStatus.completed;
      case TranscriptionStatus.failed:
        return TaskStatus.failed;
    }
  }

  /// 获取状态文本
  String _getStatusText(TranscriptionStatus status) {
    switch (status) {
      case TranscriptionStatus.pending:
        return '任务等待中...';
      case TranscriptionStatus.processing:
        return '正在处理中...';
      case TranscriptionStatus.completed:
        return '任务完成';
      case TranscriptionStatus.failed:
        return '任务失败';
    }
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    super.dispose();
  }
}

/// 后台任务模型
class BackgroundTask {
  final String id;
  final TaskType type;
  final String title;
  final DateTime createdAt;

  String description;
  TaskStatus status;
  int pollAttempts;
  int errorCount;
  String? result;

  // ASR相关字段
  final String? audioFilePath;
  final String? fileName;
  final TranscriptionModel? model;
  final String? language;
  final String? computeType;
  final bool? enableWordTimestamps;
  final bool? enableSpeakerDiarization;
  final String? modelName;

  // TTS相关字段
  final String? text;
  final String? voiceName;
  final String? mode;

  BackgroundTask({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.status = TaskStatus.pending,
    this.pollAttempts = 0,
    this.errorCount = 0,
    this.audioFilePath,
    this.fileName,
    this.model,
    this.language,
    this.computeType,
    this.enableWordTimestamps,
    this.enableSpeakerDiarization,
    this.modelName,
    this.text,
    this.voiceName,
    this.mode,
  }) : createdAt = DateTime.now();

  bool get isActive =>
      status == TaskStatus.pending || status == TaskStatus.processing;

  bool get isCompleted =>
      status == TaskStatus.completed ||
      status == TaskStatus.failed ||
      status == TaskStatus.timeout;

  IconData get icon {
    switch (type) {
      case TaskType.asr:
        return Icons.record_voice_over;
      case TaskType.tts:
        return Icons.volume_up;
    }
  }

  Color get statusColor {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.processing:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.failed:
        return Colors.red;
      case TaskStatus.timeout:
        return Colors.grey;
    }
  }
}

/// 任务类型
enum TaskType { asr, tts }

/// 任务状态
enum TaskStatus { pending, processing, completed, failed, timeout }
