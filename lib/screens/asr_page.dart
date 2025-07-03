import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/transcription_service.dart';
import '../services/audio_player_service.dart';
import '../services/huggingface_token_service.dart';
import '../services/background_task_service.dart';
import '../models/transcription_model.dart';
import '../widgets/music_player/music_player.dart';
import '../widgets/background_task_panel.dart';

import '../widgets/custom_toast.dart';

class AsrPage extends StatefulWidget {
  const AsrPage({super.key});

  @override
  State<AsrPage> createState() => _AsrPageState();
}

class _AsrPageState extends State<AsrPage> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  final BackgroundTaskService _backgroundTaskService = BackgroundTaskService();

  // 选择的音频文件
  File? _selectedAudioFile;
  String? _selectedFileName;

  // 转录模型选择
  TranscriptionModel _selectedModel = TranscriptionModel.bluelm;

  // WhisperX 选项
  String? _selectedLanguage;
  String? _selectedComputeType;
  bool _enableWordTimestamps = true; // 是否生成单词级时间戳
  bool _enableSpeakerDiarization = false; // 是否进行说话人识别
  String _selectedModelName = 'small'; // 选择的模型名称
  Map<String, dynamic>? _modelInfo; // 模型信息

  // 任务状态
  String? _currentTaskId;
  TranscriptionStatus? _taskStatus;
  String? _statusMessage;
  bool _isProcessing = false;

  // WhisperX专用状态
  List<String> _availableFiles = [];
  Map<String, dynamic>? _whisperxDetailedStatus;

  // 转录结果
  String? _transcriptionResult;

  // 任务历史
  List<TranscriptionStatusResponse> _taskHistory = [];

  @override
  void initState() {
    super.initState();
    _loadTaskHistory();
    _loadModelInfo();
  }

  @override
  void dispose() {
    _transcriptionService.dispose();
    super.dispose();
  }

  /// 加载模型信息
  Future<void> _loadModelInfo() async {
    try {
      final modelInfo = await _transcriptionService.getWhisperXModelInfo();
      setState(() {
        _modelInfo = modelInfo;
      });
    } catch (e) {
      debugPrint('加载模型信息失败: $e');
    }
  }

  /// 显示模型信息对话框
  void _showModelInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('WhisperX 模型信息'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '选择适合您需求的模型：',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_modelInfo != null && _modelInfo!['data'] != null) ...[
                  ..._buildModelInfoCards(),
                ] else ...[
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 16),
                  const Text('正在加载模型信息...'),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建模型信息卡片
  List<Widget> _buildModelInfoCards() {
    final supportedModels =
        _modelInfo!['data']['supported_models'] as Map<String, dynamic>? ?? {};

    return supportedModels.entries.map((entry) {
      final modelName = entry.key;
      final modelInfo = entry.value as Map<String, dynamic>;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    modelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(modelInfo['parameters'] ?? ''),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                modelInfo['description'] ?? '',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.memory, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '显存需求: ${modelInfo['vram'] ?? '未知'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.speed, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '速度: ${modelInfo['relative_speed'] ?? '未知'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.recommend,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '推荐用途: ${modelInfo['recommended_for'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 构建模型下拉选项（展开时显示详细信息）
  List<DropdownMenuItem<String>> _buildModelDropdownItems() {
    if (_modelInfo == null || _modelInfo!['data'] == null) {
      // 如果模型信息未加载，返回基本选项
      return [
        const DropdownMenuItem(value: 'tiny', child: Text('tiny - 最快速度，最低精度')),
        const DropdownMenuItem(value: 'base', child: Text('base - 平衡选择')),
        const DropdownMenuItem(value: 'small', child: Text('small - 推荐选择')),
        const DropdownMenuItem(value: 'medium', child: Text('medium - 高精度')),
        const DropdownMenuItem(value: 'large', child: Text('large - 最高精度')),
        const DropdownMenuItem(value: 'turbo', child: Text('turbo - 高速高质量')),
      ];
    }

    final supportedModels =
        _modelInfo!['data']['supported_models'] as Map<String, dynamic>? ?? {};

    return supportedModels.entries.map((entry) {
      final modelName = entry.key;
      final modelInfo = entry.value as Map<String, dynamic>;
      final description = modelInfo['description'] ?? '';
      final parameters = modelInfo['parameters'] ?? '';

      return DropdownMenuItem<String>(
        value: modelName,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$modelName ($parameters)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 构建选中项的简洁显示（未展开时显示）
  List<Widget> _buildSelectedItemWidgets() {
    if (_modelInfo == null || _modelInfo!['data'] == null) {
      // 如果模型信息未加载，返回基本显示
      return ['tiny', 'base', 'small', 'medium', 'large', 'turbo'].map((
        modelName,
      ) {
        return Text(modelName, style: const TextStyle(fontSize: 14));
      }).toList();
    }

    final supportedModels =
        _modelInfo!['data']['supported_models'] as Map<String, dynamic>? ?? {};

    return supportedModels.entries.map((entry) {
      final modelName = entry.key;

      return Text(modelName, style: const TextStyle(fontSize: 14));
    }).toList();
  }

  /// 选择音频文件
  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'mp3', 'flac', 'm4a', 'ogg', 'aac'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
          // 清除之前的结果
          _transcriptionResult = null;
          _currentTaskId = null;
          _taskStatus = null;
          _statusMessage = null;
        });

        if (mounted) {
          _showStatusSnackBar('已选择文件: $_selectedFileName');
        }
      }
    } catch (e) {
      if (mounted) {
        _showStatusSnackBar('选择文件失败: $e', isError: true);
      }
    }
  }

  /// 提交转录任务
  Future<void> _submitTranscriptionTask() async {
    if (_selectedAudioFile == null) {
      _showStatusSnackBar('请先选择音频文件', isError: true);
      return;
    }

    // 检查说话人识别功能是否需要HuggingFace Token
    if (_selectedModel == TranscriptionModel.whisperx &&
        _enableSpeakerDiarization) {
      final hasToken = await HuggingFaceTokenService.hasToken();
      if (!hasToken) {
        _showSpeakerDiarizationTokenDialog();
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _transcriptionResult = null;
      _taskStatus = null;
      _statusMessage = '正在提交任务...';
    });

    try {
      // 获取HuggingFace Token（如果需要说话人识别）
      String? huggingFaceToken;
      if (_selectedModel == TranscriptionModel.whisperx &&
          _enableSpeakerDiarization) {
        huggingFaceToken = await HuggingFaceTokenService.getToken();
      }

      TranscriptionSubmitResponse response = await _transcriptionService
          .submitTranscriptionTask(
            _selectedAudioFile!,
            _selectedModel,
            language: _selectedLanguage,
            computeType: _selectedComputeType,
            enableWordTimestamps: _selectedModel == TranscriptionModel.whisperx
                ? _enableWordTimestamps
                : null,
            enableSpeakerDiarization:
                _selectedModel == TranscriptionModel.whisperx
                ? _enableSpeakerDiarization
                : null,
            huggingFaceToken: huggingFaceToken,
            modelName: _selectedModel == TranscriptionModel.whisperx
                ? _selectedModelName
                : null,
          );

      setState(() {
        _currentTaskId = response.taskId;
        _taskStatus = TranscriptionStatus.processing;
        _statusMessage = response.message ?? '任务已提交，正在处理中...';
        _isProcessing = false; // 任务已提交到后台，界面不再处理中
      });

      if (mounted) {
        _showStatusSnackBar('任务提交成功！任务已转入后台处理');
      }

      // 添加任务到后台任务管理器
      await _backgroundTaskService.addAsrTask(
        audioFilePath: _selectedAudioFile!.path,
        fileName: _selectedFileName ?? 'audio.wav',
        model: _selectedModel,
        taskId: response.taskId,
        language: _selectedLanguage,
        computeType: _selectedComputeType,
        enableWordTimestamps: _enableWordTimestamps,
        enableSpeakerDiarization: _enableSpeakerDiarization,
        modelName: _selectedModelName,
      );

      // 更新任务历史
      _loadTaskHistory();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = '提交任务失败: $e';
      });

      if (mounted) {
        _showStatusSnackBar(_statusMessage!, isError: true);
      }
    }
  }

  /// 加载任务历史（仅蓝心大模型支持）
  Future<void> _loadTaskHistory() async {
    if (_selectedModel != TranscriptionModel.bluelm) return;

    try {
      TranscriptionTaskListResponse response = await _transcriptionService
          .getBlueLMTaskList();
      setState(() {
        _taskHistory = response.tasks;
      });
    } catch (e) {
      debugPrint('加载任务历史失败: $e');
    }
  }

  /// 刷新当前任务状态
  Future<void> _refreshTaskStatus() async {
    if (_currentTaskId == null) return;

    try {
      debugPrint('开始刷新任务状态，任务ID: $_currentTaskId, 模型: $_selectedModel');

      TranscriptionStatusResponse statusResponse = await _transcriptionService
          .getTaskStatus(_currentTaskId!, _selectedModel);

      debugPrint(
        '状态查询成功: ${statusResponse.status}, 消息: ${statusResponse.message}',
      );

      setState(() {
        _taskStatus = statusResponse.status;
        _statusMessage =
            statusResponse.message ?? _getStatusText(statusResponse.status);
      });

      // 对于WhisperX，获取详细状态信息
      if (_selectedModel == TranscriptionModel.whisperx) {
        try {
          debugPrint('正在获取WhisperX详细状态...');
          _whisperxDetailedStatus = await _transcriptionService
              .getWhisperXDetailedStatus(_currentTaskId!);

          if (_whisperxDetailedStatus != null) {
            debugPrint('WhisperX详细状态: $_whisperxDetailedStatus');
            final availableFiles =
                _whisperxDetailedStatus!['available_files'] as List?;
            setState(() {
              _availableFiles = availableFiles?.cast<String>() ?? [];
            });

            // 更新状态消息显示可用文件
            if (_availableFiles.isNotEmpty) {
              setState(() {
                _statusMessage =
                    '${_getStatusText(_taskStatus!)} • 可用文件: ${_availableFiles.join(', ')}';
              });
              debugPrint('可用文件更新: $_availableFiles');
            }
          } else {
            debugPrint('WhisperX详细状态为null');
          }
        } catch (e) {
          debugPrint('获取WhisperX详细状态失败: $e');
          // 详细状态获取失败不影响主要状态刷新
        }
      }

      // 如果任务已完成，显示完成信息
      if (statusResponse.status == TranscriptionStatus.completed) {
        debugPrint('任务已完成，结果已由后台服务处理');
      }

      if (mounted) {
        _showStatusSnackBar('状态已刷新');
      }
    } catch (e) {
      debugPrint('刷新状态失败，详细错误: $e');
      if (mounted) {
        String errorMessage = '刷新状态失败';
        if (e.toString().contains('404')) {
          errorMessage = '任务不存在或已过期';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('connection')) {
          errorMessage = '网络连接超时，请检查网络';
        } else if (e.toString().contains('500')) {
          errorMessage = '服务器内部错误，请稍后重试';
        }
        _showStatusSnackBar('$errorMessage: $e', isError: true);
      }
    }
  }

  /// 获取状态文本
  String _getStatusText(TranscriptionStatus status) {
    switch (status) {
      case TranscriptionStatus.pending:
        return '等待处理';
      case TranscriptionStatus.processing:
        return '正在处理中...';
      case TranscriptionStatus.completed:
        return '处理完成';
      case TranscriptionStatus.failed:
        return '处理失败';
    }
  }

  /// 获取状态颜色
  Color _getStatusColor(TranscriptionStatus status) {
    switch (status) {
      case TranscriptionStatus.pending:
        return Colors.orange;
      case TranscriptionStatus.processing:
        return Colors.blue;
      case TranscriptionStatus.completed:
        return Colors.green;
      case TranscriptionStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("音频转字"),
        automaticallyImplyLeading: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 后台任务面板
            Consumer<BackgroundTaskService>(
              builder: (context, taskService, child) {
                final asrTasks = taskService.tasks
                    .where((task) => task.type == TaskType.asr)
                    .toList();

                if (asrTasks.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    const BackgroundTaskPanel(),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            // 文件选择区域
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. 选择音频文件',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedFileName ?? '未选择文件',
                            style: TextStyle(
                              color: _selectedFileName != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _pickAudioFile,
                          icon: const Icon(Icons.audio_file),
                          label: const Text('选择文件'),
                        ),
                      ],
                    ),
                    if (_selectedFileName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '支持格式: WAV',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 模型选择区域
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. 选择转录模型',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<TranscriptionModel>(
                            title: const Text('蓝心小V'),
                            subtitle: const Text('快速转录'),
                            value: TranscriptionModel.bluelm,
                            groupValue: _selectedModel,
                            onChanged: _isProcessing
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedModel = value!;
                                    });
                                    _loadTaskHistory();
                                  },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<TranscriptionModel>(
                            title: const Text('WhisperX'),
                            subtitle: const Text('多语言支持'),
                            value: TranscriptionModel.whisperx,
                            groupValue: _selectedModel,
                            onChanged: _isProcessing
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedModel = value!;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),

                    // WhisperX 选项
                    if (_selectedModel == TranscriptionModel.whisperx) ...[
                      const Divider(),
                      const Text(
                        'WhisperX 选项:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: '语言',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedLanguage,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedLanguage = value;
                                      });
                                    },
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('自动检测'),
                                ),
                                DropdownMenuItem(
                                  value: 'zh',
                                  child: Text('中文'),
                                ),
                                DropdownMenuItem(
                                  value: 'en',
                                  child: Text('英文'),
                                ),
                                DropdownMenuItem(
                                  value: 'ja',
                                  child: Text('日文'),
                                ),
                                DropdownMenuItem(
                                  value: 'ko',
                                  child: Text('韩文'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: '计算类型',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedComputeType,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedComputeType = value;
                                      });
                                    },
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('默认'),
                                ),
                                DropdownMenuItem(
                                  value: 'float16',
                                  child: Text('精确'),
                                ),
                                DropdownMenuItem(
                                  value: 'int8',
                                  child: Text('快速'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 模型选择
                      const Text(
                        '模型选择:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: '选择模型',
                                border: OutlineInputBorder(),
                                helperText: '不同模型在速度、精度和资源需求方面有所不同',
                              ),
                              value: _selectedModelName,
                              onChanged: _isProcessing
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _selectedModelName = value ?? 'small';
                                      });
                                    },
                              items: _buildModelDropdownItems(),
                              selectedItemBuilder: (BuildContext context) {
                                return _buildSelectedItemWidgets();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _showModelInfoDialog,
                            icon: const Icon(Icons.info_outline),
                            tooltip: '查看模型详细信息',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // WhisperX 处理选项
                      const Text(
                        '处理选项:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      CheckboxListTile(
                        title: const Text('生成单词级时间戳'),
                        subtitle: const Text('用于音频播放时的歌词同步'),
                        value: _enableWordTimestamps,
                        onChanged: _isProcessing
                            ? null
                            : (bool? value) {
                                setState(() {
                                  _enableWordTimestamps = value ?? true;
                                  // 如果关闭单词级时间戳，也关闭说话人识别（因为说话人识别依赖于单词级对齐）
                                  if (!_enableWordTimestamps) {
                                    _enableSpeakerDiarization = false;
                                  }
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      CheckboxListTile(
                        title: const Text('进行说话人识别'),
                        subtitle: const Text('识别音频中的不同说话人，需要更长处理时间'),
                        value: _enableSpeakerDiarization,
                        onChanged: (_isProcessing || !_enableWordTimestamps)
                            ? null
                            : (bool? value) {
                                setState(() {
                                  _enableSpeakerDiarization = value ?? false;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedAudioFile != null && !_isProcessing)
                    ? _submitTranscriptionTask
                    : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProcessing ? '处理中...' : '开始转录'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 状态显示区域
            if (_currentTaskId != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '转录状态',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _refreshTaskStatus,
                            icon: const Icon(Icons.refresh),
                            tooltip: '刷新状态',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            _taskStatus == TranscriptionStatus.completed
                                ? Icons.check_circle
                                : _taskStatus == TranscriptionStatus.failed
                                ? Icons.error
                                : Icons.hourglass_empty,
                            color: _taskStatus != null
                                ? _getStatusColor(_taskStatus!)
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage ?? '未知状态',
                              style: TextStyle(
                                color: _taskStatus != null
                                    ? _getStatusColor(_taskStatus!)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '任务ID: $_currentTaskId',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),

                      // 显示选择的处理选项（仅WhisperX）
                      if (_selectedModel == TranscriptionModel.whisperx) ...[
                        const SizedBox(height: 8),
                        Text(
                          '处理选项:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '• 单词级时间戳: ${_enableWordTimestamps ? "启用" : "禁用"}\n'
                          '• 说话人识别: ${_enableSpeakerDiarization ? "启用" : "禁用"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],

                      // WhisperX可用文件显示
                      if (_selectedModel == TranscriptionModel.whisperx &&
                          _availableFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          '可用文件:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getFilteredAvailableFiles().map((file) {
                            IconData icon;
                            String label;
                            Color color;

                            switch (file) {
                              case 'transcription':
                                icon = Icons.text_fields;
                                label = '转录文本';
                                color = Colors.blue;
                                break;
                              case 'wordstamps':
                                icon = Icons.access_time;
                                label = '单词时间戳';
                                color = Colors.green;
                                break;
                              case 'speaker_segments':
                              case 'diarization':
                                icon = Icons.people;
                                label = '说话人识别';
                                color = Colors.orange;
                                break;
                              default:
                                icon = Icons.file_present;
                                label = file;
                                color = Colors.grey;
                            }

                            return Chip(
                              avatar: Icon(icon, size: 16, color: color),
                              label: Text(
                                label,
                                style: TextStyle(fontSize: 12, color: color),
                              ),
                              backgroundColor: color.withValues(alpha: 0.1),
                              side: BorderSide(
                                color: color.withValues(alpha: 0.3),
                              ),
                            );
                          }).toList(),
                        ),

                        // 批量下载按钮
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _downloadAllAvailableFiles,
                                icon: const Icon(Icons.download),
                                label: const Text('下载所有文件'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _viewWhisperXResults,
                              icon: const Icon(Icons.visibility),
                              label: const Text('查看结果'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // WhisperX播放器按钮
                      if (_selectedModel == TranscriptionModel.whisperx &&
                          (_taskStatus == TranscriptionStatus.completed ||
                              _canOpenPlayer())) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openAudioPlayer,
                            icon: const Icon(Icons.music_note),
                            label: Text(
                              _taskStatus == TranscriptionStatus.completed
                                  ? '打开音频播放器'
                                  : '打开音频播放器（预览）',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 转录结果显示区域
            if (_transcriptionResult != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '转录结果',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              // 复制到剪贴板
                              // Clipboard.setData(ClipboardData(text: _transcriptionResult!));
                              _showStatusSnackBar('结果已复制到剪贴板');
                            },
                            icon: const Icon(Icons.copy),
                            tooltip: '复制结果',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _formatTranscriptionResult(_transcriptionResult!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 任务历史区域（仅蓝心大模型）
            if (_selectedModel == TranscriptionModel.bluelm &&
                _taskHistory.isNotEmpty) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '转录历史',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              final currentContext = context;
                              await _loadTaskHistory();
                              if (mounted && currentContext.mounted) {
                                CustomToast.show(
                                  currentContext,
                                  message: '任务历史已刷新',
                                  type: ToastType.info,
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('刷新'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _taskHistory.length > 5
                            ? 5
                            : _taskHistory.length, // 最多显示5个
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final task = _taskHistory[index];
                          return ListTile(
                            leading: Icon(
                              task.status == TranscriptionStatus.completed
                                  ? Icons.check_circle
                                  : task.status == TranscriptionStatus.failed
                                  ? Icons.error
                                  : Icons.hourglass_empty,
                              color: _getStatusColor(task.status),
                            ),
                            title: Text(task.filename ?? '未知文件'),
                            subtitle: Text(
                              '${_getStatusText(task.status)} • ${task.createdAt ?? ''}',
                            ),
                            trailing:
                                task.status == TranscriptionStatus.completed
                                ? IconButton(
                                    onPressed: () async {
                                      final currentContext = context;
                                      try {
                                        String result =
                                            await _transcriptionService
                                                .downloadBlueLMResult(
                                                  task.taskId,
                                                );
                                        if (mounted && currentContext.mounted) {
                                          showDialog(
                                            context: currentContext,
                                            builder: (dialogContext) =>
                                                AlertDialog(
                                                  title: const Text('转录结果'),
                                                  content: SingleChildScrollView(
                                                    child: Text(
                                                      _formatTranscriptionResult(
                                                        result,
                                                      ),
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            dialogContext,
                                                          ),
                                                      child: const Text('关闭'),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted && currentContext.mounted) {
                                          CustomToast.show(
                                            currentContext,
                                            message: '下载结果失败: $e',
                                            type: ToastType.error,
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.download),
                                    tooltip: '查看结果',
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 格式化转录结果显示
  String _formatTranscriptionResult(String result) {
    try {
      // 尝试解析JSON
      final jsonData = jsonDecode(result);
      if (jsonData is Map<String, dynamic>) {
        // 如果是JSON格式，尝试提取文本内容
        if (jsonData.containsKey('text')) {
          return jsonData['text'].toString();
        } else if (jsonData.containsKey('segments')) {
          // WhisperX格式
          final segments = jsonData['segments'] as List?;
          if (segments != null) {
            return segments.map((seg) => seg['text'] ?? '').join(' ');
          }
        }
      }
      return jsonEncode(jsonData); // 格式化显示JSON
    } catch (e) {
      // 如果不是JSON，直接返回原文本
      return result;
    }
  }

  /// 检查是否可以打开播放器（基于用户选择的选项）
  bool _canOpenPlayer() {
    if (_currentTaskId == null || _taskStatus == TranscriptionStatus.failed) {
      return false;
    }

    // 对于WhisperX，根据用户选择的选项检查所需文件
    if (_selectedModel == TranscriptionModel.whisperx) {
      bool hasTranscription = _availableFiles.contains('transcription');

      // 如果用户启用了单词级时间戳，需要等待wordstamps文件
      if (_enableWordTimestamps) {
        return hasTranscription && _availableFiles.contains('wordstamps');
      }

      // 如果用户没有启用单词级时间戳，只需要基础转录即可
      return hasTranscription;
    }

    // 对于其他模型，只有完成状态才能打开
    return _taskStatus == TranscriptionStatus.completed;
  }

  /// 打开音频播放器
  Future<void> _openAudioPlayer() async {
    if (_currentTaskId == null || _selectedAudioFile == null) {
      _showStatusSnackBar('缺少必要的任务信息或音频文件', isError: true);
      return;
    }

    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在加载播放器数据...'),
            ],
          ),
        ),
      );

      // 获取WhisperX播放器数据
      final playerData = await _transcriptionService.getWhisperXPlayerData(
        _currentTaskId!,
      );

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }

      if (playerData == null) {
        if (mounted) {
          _showStatusSnackBar('播放器数据尚未准备就绪，请稍后重试', isError: true);
        }
        return;
      }

      // 创建AudioPlayData
      final audioPlayData = AudioPlayerUtils.createFromWhisperXData(
        taskId: _currentTaskId!,
        filename: _selectedFileName ?? 'audio.wav',
        audioFilePath: _selectedAudioFile!.path,
        transcriptionData: playerData['transcription'],
        wordstampsData: playerData['wordstamps'],
        speakerData: playerData['speaker_segments'],
      );

      if (mounted) {
        // 打开全屏播放器
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UnifiedPlayerPage(
              audioData: audioPlayData,
              isTranscriptionAudio: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
        _showStatusSnackBar('打开播放器失败: $e', isError: true);
      }
      debugPrint('打开播放器失败: $e');
    }
  }

  /// 下载所有可用的WhisperX文件
  Future<void> _downloadAllAvailableFiles() async {
    if (_currentTaskId == null || _availableFiles.isEmpty) {
      _showStatusSnackBar('没有可下载的文件', isError: true);
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在下载文件...'),
            ],
          ),
        ),
      );

      Map<String, String> downloadedFiles = {};

      for (String fileType in _availableFiles) {
        try {
          String result = await _transcriptionService.downloadWhisperXResult(
            _currentTaskId!,
            fileType: fileType,
          );
          downloadedFiles[fileType] = result;
        } catch (e) {
          debugPrint('下载文件 $fileType 失败: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框

        if (downloadedFiles.isNotEmpty) {
          _showStatusSnackBar('成功下载 ${downloadedFiles.length} 个文件');

          // 显示下载结果
          _showDownloadResults(downloadedFiles);
        } else {
          _showStatusSnackBar('没有成功下载任何文件', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showStatusSnackBar('下载文件失败: $e', isError: true);
      }
    }
  }

  /// 查看WhisperX结果
  Future<void> _viewWhisperXResults() async {
    if (_currentTaskId == null || _availableFiles.isEmpty) {
      _showStatusSnackBar('没有可查看的结果', isError: true);
      return;
    }

    try {
      // 优先显示转录结果
      String fileType = _availableFiles.contains('transcription')
          ? 'transcription'
          : _availableFiles.first;

      String result = await _transcriptionService.downloadWhisperXResult(
        _currentTaskId!,
        fileType: fileType,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${_getFileDisplayName(fileType)} 结果'),
            content: SingleChildScrollView(
              child: SelectableText(
                _formatTranscriptionResult(result),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: 实现复制到剪贴板功能
                  Navigator.pop(context);
                  _showStatusSnackBar('已复制到剪贴板');
                },
                child: const Text('复制'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showStatusSnackBar('查看结果失败: $e', isError: true);
      }
    }
  }

  /// 显示下载结果
  void _showDownloadResults(Map<String, String> downloadedFiles) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('下载结果'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: DefaultTabController(
            length: downloadedFiles.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: downloadedFiles.keys
                      .map(
                        (fileType) => Tab(text: _getFileDisplayName(fileType)),
                      )
                      .toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: downloadedFiles.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _formatTranscriptionResult(entry.value),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 获取文件类型的显示名称
  String _getFileDisplayName(String fileType) {
    switch (fileType) {
      case 'transcription':
        return '转录文本';
      case 'wordstamps':
        return '单词时间戳';
      case 'speaker_segments':
      case 'diarization':
        return '说话人分离';
      default:
        return fileType;
    }
  }

  // 显示状态通知的辅助函数
  void _showStatusSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  /// 获取过滤后的可用文件列表
  /// speaker_segments 和 diarization 成对出现时只显示一个
  List<String> _getFilteredAvailableFiles() {
    List<String> filteredFiles = List.from(_availableFiles);

    // 如果同时存在 speaker_segments 和 diarization，只保留 diarization
    if (filteredFiles.contains('speaker_segments') &&
        filteredFiles.contains('diarization')) {
      filteredFiles.remove('speaker_segments');
    }

    return filteredFiles;
  }

  /// 显示说话人识别需要Token的对话框
  void _showSpeakerDiarizationTokenDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('需要配置 Token'),
          ],
        ),
        content: const Text(
          '说话人识别功能需要 HuggingFace Token 才能使用。\n\n'
          '请前往主页左侧菜单的"系统设置"页面配置您的 HuggingFace Token，'
          '并确保已获取 pyannote 模型的使用许可。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }
}
