import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/transcription_model.dart';
import '../services/bluelm_config_service.dart';

class TranscriptionService {
  static const String baseUrl = 'http://127.0.0.1:8888';
  late final Dio _dio;

  TranscriptionService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10), // 转录可能需要更长时间
        headers: {'Accept': 'application/json'},
        followRedirects: true,
        maxRedirects: 3,
        validateStatus: (status) => status! < 400, // 接受所有小于400的状态码
      ),
    );

    // 添加请求和响应拦截器用于调试
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false, // 文件上传时不记录请求体
        responseBody: false,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  /// 提交蓝心大模型转录任务
  /// [audioFile] 音频文件
  Future<TranscriptionSubmitResponse> submitBlueLMTask(File audioFile) async {
    try {
      debugPrint('提交蓝心大模型转录任务: ${audioFile.path}');

      // 获取蓝心大模型配置
      final blueLMConfig = await BlueLMConfigService.getConfig();
      final appId = blueLMConfig['app_id'];
      final appKey = blueLMConfig['app_key'];

      // 创建表单数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        // 添加蓝心大模型配置（如果有的话）
        if (appId != null) 'app_id': appId,
        if (appKey != null) 'app_key': appKey,
      });

      // 发送POST请求
      final response = await _dio.post('/bluelm/transcription', data: formData);

      debugPrint('蓝心大模型提交响应: ${response.data}');

      if (response.statusCode == 200) {
        return TranscriptionSubmitResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '提交任务失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('蓝心大模型提交任务异常: ${e.message}');
      if (e.response != null) {
        debugPrint('错误响应: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      debugPrint('蓝心大模型提交任务未知错误: $e');
      rethrow;
    }
  }

  /// 提交WhisperX转录任务
  /// [audioFile] 音频文件
  /// [language] 语言代码（可选）
  /// [computeType] 计算类型（可选）
  /// [enableWordTimestamps] 是否生成单词级时间戳（可选）
  /// [enableSpeakerDiarization] 是否进行说话人识别（可选）
  /// [huggingFaceToken] HuggingFace Token（可选，说话人识别需要）
  /// [modelName] 模型名称（可选，默认为small）
  Future<TranscriptionSubmitResponse> submitWhisperXTask(
    File audioFile, {
    String? language,
    String? computeType,
    bool? enableWordTimestamps,
    bool? enableSpeakerDiarization,
    String? huggingFaceToken,
    String? modelName,
  }) async {
    try {
      debugPrint('提交WhisperX转录任务: ${audioFile.path}');

      // 创建表单数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFile.path,
          filename: audioFile.path.split('/').last,
        ),
        if (language != null) 'language': language,
        if (computeType != null) 'compute_type': computeType,
        if (enableWordTimestamps != null)
          'enable_word_timestamps': enableWordTimestamps.toString(),
        if (enableSpeakerDiarization != null)
          'enable_speaker_diarization': enableSpeakerDiarization.toString(),
        if (huggingFaceToken != null) 'huggingface_token': huggingFaceToken,
        if (modelName != null) 'model_name': modelName,
      });

      // 发送POST请求到统一接口
      final response = await _dio.post(
        '/model',
        queryParameters: {'model': 'whisperx', 'action': 'submit'},
        data: formData,
      );

      debugPrint('WhisperX提交响应: ${response.data}');

      if (response.statusCode == 200) {
        return TranscriptionSubmitResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '提交任务失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('WhisperX提交任务异常: ${e.message}');
      if (e.response != null) {
        debugPrint('错误响应: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      debugPrint('WhisperX提交任务未知错误: $e');
      rethrow;
    }
  }

  /// 查询蓝心大模型任务状态
  /// [taskId] 任务ID
  Future<TranscriptionStatusResponse> getBlueLMTaskStatus(String taskId) async {
    try {
      final response = await _dio.get('/bluelm/transcription/status/$taskId');

      if (response.statusCode == 200) {
        return TranscriptionStatusResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '查询状态失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('查询蓝心大模型任务状态异常: ${e.message}');
      rethrow;
    }
  }

  /// 查询WhisperX任务状态
  /// [taskId] 任务ID
  Future<TranscriptionStatusResponse> getWhisperXTaskStatus(
    String taskId,
  ) async {
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await _dio.get(
          '/model',
          queryParameters: {
            'model': 'whisperx',
            'action': 'status',
            'task_id': taskId,
          },
        );

        if (response.statusCode == 200) {
          //debugPrint('WhisperX状态查询响应: ${response.data}');

          // WhisperX返回的数据格式需要转换
          Map<String, dynamic> data = response.data;

          // 转换WhisperX的状态到标准格式
          String whisperxStatus = data['status'] ?? 'unknown';
          String standardStatus = _mapWhisperXStatus(whisperxStatus);

          Map<String, dynamic> standardizedData = {
            'task_id': data['task_id'] ?? taskId,
            'status': standardStatus,
            'message': data['message'] ?? _getStatusMessage(whisperxStatus),
            'created_at': data['created_at'],
            'filename': data['filename'],
          };

          //debugPrint('WhisperX原始状态: $whisperxStatus -> 标准状态: $standardStatus');
          //debugPrint('标准化后的数据: $standardizedData');
          return TranscriptionStatusResponse.fromJson(standardizedData);
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: '查询状态失败，状态码: ${response.statusCode}',
          );
        }
      } on DioException catch (e) {
        retryCount++;
        debugPrint('查询WhisperX任务状态异常 (第$retryCount次): ${e.message}');

        if (retryCount >= maxRetries) {
          rethrow;
        }

        // 重试前等待一段时间
        await Future.delayed(Duration(seconds: retryCount));
      } catch (e) {
        retryCount++;
        debugPrint('查询WhisperX任务状态未知错误 (第$retryCount次): $e');

        if (retryCount >= maxRetries) {
          rethrow;
        }

        // 重试前等待一段时间
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    // 如果所有重试都失败了，抛出最后一个异常
    throw Exception('查询WhisperX任务状态失败，已重试$maxRetries次');
  }

  /// 下载蓝心大模型转录结果
  /// [taskId] 任务ID
  Future<String> downloadBlueLMResult(String taskId) async {
    try {
      final response = await _dio.get(
        '/bluelm/transcription/download/$taskId',
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '下载结果失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('下载蓝心大模型结果异常: ${e.message}');
      rethrow;
    }
  }

  /// 下载WhisperX转录结果
  /// [taskId] 任务ID
  /// [fileType] 文件类型（transcription, wordstamps, diarization, speaker）
  Future<String> downloadWhisperXResult(
    String taskId, {
    String fileType = 'transcription',
  }) async {
    try {
      final response = await _dio.get(
        '/model',
        queryParameters: {
          'model': 'whisperx',
          'action': 'download',
          'task_id': taskId,
          'file_name': fileType,
        },
        options: Options(responseType: ResponseType.plain),
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '下载结果失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('下载WhisperX结果异常: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('下载WhisperX结果未知错误: $e');
      rethrow;
    }
  }

  /// 获取蓝心大模型任务列表
  /// [status] 状态过滤（可选）
  /// [limit] 数量限制（可选）
  Future<TranscriptionTaskListResponse> getBlueLMTaskList({
    String? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _dio.get(
        '/bluelm/transcription/tasks',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return TranscriptionTaskListResponse.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取任务列表失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('获取蓝心大模型任务列表异常: ${e.message}');
      rethrow;
    }
  }

  /// 统一提交转录任务接口
  /// [audioFile] 音频文件
  /// [model] 转录模型
  /// [language] 语言代码（仅WhisperX使用）
  /// [computeType] 计算类型（仅WhisperX使用）
  /// [enableWordTimestamps] 是否生成单词级时间戳（仅WhisperX使用）
  /// [enableSpeakerDiarization] 是否进行说话人识别（仅WhisperX使用）
  /// [huggingFaceToken] HuggingFace Token（仅WhisperX说话人识别使用）
  /// [modelName] 模型名称（仅WhisperX使用）
  Future<TranscriptionSubmitResponse> submitTranscriptionTask(
    File audioFile,
    TranscriptionModel model, {
    String? language,
    String? computeType,
    bool? enableWordTimestamps,
    bool? enableSpeakerDiarization,
    String? huggingFaceToken,
    String? modelName,
  }) async {
    switch (model) {
      case TranscriptionModel.bluelm:
        return await submitBlueLMTask(audioFile);
      case TranscriptionModel.whisperx:
        return await submitWhisperXTask(
          audioFile,
          language: language,
          computeType: computeType,
          enableWordTimestamps: enableWordTimestamps,
          enableSpeakerDiarization: enableSpeakerDiarization,
          huggingFaceToken: huggingFaceToken,
          modelName: modelName,
        );
    }
  }

  /// 统一查询任务状态接口
  /// [taskId] 任务ID
  /// [model] 转录模型
  Future<TranscriptionStatusResponse> getTaskStatus(
    String taskId,
    TranscriptionModel model,
  ) async {
    switch (model) {
      case TranscriptionModel.bluelm:
        return await getBlueLMTaskStatus(taskId);
      case TranscriptionModel.whisperx:
        return await getWhisperXTaskStatus(taskId);
    }
  }

  /// 统一下载转录结果接口
  /// [taskId] 任务ID
  /// [model] 转录模型
  /// [fileType] 文件类型（仅WhisperX使用）
  Future<String> downloadTranscriptionResult(
    String taskId,
    TranscriptionModel model, {
    String fileType = 'transcription',
  }) async {
    switch (model) {
      case TranscriptionModel.bluelm:
        return await downloadBlueLMResult(taskId);
      case TranscriptionModel.whisperx:
        return await downloadWhisperXResult(taskId, fileType: fileType);
    }
  }

  /// 获取WhisperX任务的详细状态（包含可用文件和数据）
  Future<Map<String, dynamic>> getWhisperXDetailedStatus(String taskId) async {
    try {
      // 使用统一的/model接口查询状态
      final response = await _dio.get(
        '/model',
        queryParameters: {
          'model': 'whisperx',
          'action': 'status',
          'task_id': taskId,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取详细状态失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('获取WhisperX详细状态异常: ${e.message}');
      rethrow;
    }
  }

  /// 下载WhisperX JSON格式结果
  Future<Map<String, dynamic>> downloadWhisperXJson(
    String taskId,
    String fileType,
  ) async {
    try {
      // 使用统一的/model接口下载文件
      final response = await _dio.get(
        '/model',
        queryParameters: {
          'model': 'whisperx',
          'action': 'download',
          'task_id': taskId,
          'file_name': fileType,
        },
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200) {
        // 如果返回的是字符串，尝试解析为JSON
        if (response.data is String) {
          return jsonDecode(response.data);
        }
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '下载JSON结果失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('下载WhisperX JSON结果异常: ${e.message}');
      rethrow;
    }
  }

  /// 检查WhisperX文件是否可用
  Future<bool> isWhisperXFileAvailable(String taskId, String fileType) async {
    try {
      final status = await getWhisperXDetailedStatus(taskId);
      final availableFiles = status['available_files'] as List? ?? [];
      return availableFiles.contains(fileType);
    } catch (e) {
      debugPrint('检查文件可用性失败: $e');
      return false;
    }
  }

  /// 获取WhisperX模型信息
  Future<Map<String, dynamic>> getWhisperXModelInfo() async {
    try {
      final response = await _dio.get(
        '/model',
        queryParameters: {'model': 'whisperx', 'action': 'models'},
        options: Options(responseType: ResponseType.json),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取模型信息失败，状态码: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      debugPrint('获取模型信息异常: ${e.message}');
      rethrow;
    }
  }

  /// 映射WhisperX状态到标准状态
  String _mapWhisperXStatus(String whisperxStatus) {
    switch (whisperxStatus.toLowerCase()) {
      case 'queued':
        return 'pending';
      case 'processing':
      case 'transcription_processing':
      case 'transcription_completed':
      case 'alignment_processing':
      case 'alignment_completed':
      case 'diarization_processing':
        return 'processing';
      case 'completed':
        return 'completed';
      case 'failed':
        return 'failed';
      default:
        debugPrint('未知的WhisperX状态: $whisperxStatus');
        return 'pending';
    }
  }

  /// 获取状态消息
  String _getStatusMessage(String whisperxStatus) {
    switch (whisperxStatus.toLowerCase()) {
      case 'queued':
        return '任务已排队，等待处理';
      case 'processing':
        return '正在处理音频文件...';
      case 'transcription_processing':
        return '正在进行基础转录...';
      case 'transcription_completed':
        return '基础转录已完成';
      case 'alignment_processing':
        return '正在进行单词级对齐...';
      case 'alignment_completed':
        return '单词级对齐已完成';
      case 'diarization_processing':
        return '正在进行说话人分离...';
      case 'completed':
        return '所有处理步骤已完成';
      case 'failed':
        return '处理失败';
      default:
        return '状态未知';
    }
  }

  /// 获取WhisperX的转录和单词级时间戳数据（用于播放器）
  Future<Map<String, dynamic>?> getWhisperXPlayerData(String taskId) async {
    try {
      // 检查是否至少有基础转录和单词级时间戳
      final transcriptionAvailable = await isWhisperXFileAvailable(
        taskId,
        'transcription',
      );
      final wordstampsAvailable = await isWhisperXFileAvailable(
        taskId,
        'wordstamps',
      );

      if (!transcriptionAvailable || !wordstampsAvailable) {
        return null;
      }

      // 下载转录数据和单词级时间戳
      final transcriptionData = await downloadWhisperXJson(
        taskId,
        'transcription',
      );
      final wordstampsData = await downloadWhisperXJson(taskId, 'wordstamps');

      // 尝试下载说话人数据（如果可用）
      Map<String, dynamic>? speakerData;
      final speakerAvailable = await isWhisperXFileAvailable(
        taskId,
        'speaker_segments',
      );
      if (speakerAvailable) {
        try {
          speakerData = await downloadWhisperXJson(taskId, 'speaker_segments');
        } catch (e) {
          debugPrint('下载说话人数据失败: $e');
        }
      }

      return {
        'transcription': transcriptionData,
        'wordstamps': wordstampsData,
        'speaker_segments': speakerData,
      };
    } catch (e) {
      debugPrint('获取WhisperX播放器数据失败: $e');
      rethrow;
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}
