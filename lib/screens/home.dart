import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_player_service.dart';
import '../services/audio_library_service.dart';
import '../config/performance_config.dart';
import '../models/audio_player_model.dart';
import 'dart:io';
import 'dart:convert';
import '../widgets/custom_toast.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AudioType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 切换tab时刷新UI
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 顶部标题和搜索栏
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "文枢工坊音频库",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Consumer<AudioLibraryService>(
                          builder: (context, library, child) {
                            return Text(
                              '共 ${library.totalCount} 个音频 · ${library.ttsCount} 个TTS生成 · ${library.asrCount} 个ASR转录',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // TTS快速入口
                        // TextButton.icon(
                        //   onPressed: () => context.push('/tts-processing'),
                        //   icon: const Icon(Icons.record_voice_over),
                        //   label: const Text('TTS处理'),
                        // ),
                        const SizedBox(width: 8),
                        // 刷新按钮
                        IconButton(
                          onPressed: () {
                            _refreshAudioLibrary();
                          },
                          icon: const Icon(Icons.refresh),
                          tooltip: '刷新音频库',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 搜索栏
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索音频...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ],
            ),
          ),
          // 标签栏
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '全部'),
                Tab(text: 'TTS生成'),
                Tab(text: 'ASR转录'),
                Tab(text: '本地音频'),
              ],
              onTap: (index) {
                setState(() {
                  switch (index) {
                    case 0:
                      _filterType = null;
                      break;
                    case 1:
                      _filterType = AudioType.tts;
                      break;
                    case 2:
                      _filterType = AudioType.asr;
                      break;
                    case 3:
                      _filterType = AudioType.local;
                      break;
                  }
                });
              },
            ),
          ),
          // 音频列表
          Expanded(
            child: Consumer<AudioLibraryService>(
              builder: (context, library, child) {
                if (library.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 获取过滤后的音频列表
                List<AudioItem> items = library.audioItems;

                // 应用搜索
                if (_searchQuery.isNotEmpty) {
                  items = library.search(_searchQuery);
                }

                // 应用类型过滤
                if (_filterType != null) {
                  items = items
                      .where((item) => item.type == _filterType)
                      .toList();
                }

                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filterType == AudioType.tts
                              ? Icons.record_voice_over
                              : _filterType == AudioType.asr
                              ? Icons.transcribe
                              : Icons.music_note,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? '没有找到匹配的音频'
                              : _filterType == AudioType.tts
                              ? '暂无TTS生成的音频'
                              : _filterType == AudioType.asr
                              ? '暂无ASR转录的音频'
                              : '暂无音频文件',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_filterType == AudioType.tts) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.push('/tts-processing'),
                            child: const Text('去生成TTS音频'),
                          ),
                        ],
                        if (_filterType == AudioType.asr) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.push('/asr'),
                            child: const Text('去转录音频'),
                          ),
                        ],
                        if (_filterType == AudioType.local ||
                            _filterType == null) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _pickAndAddAudioFiles,
                            icon: const Icon(Icons.add),
                            label: const Text('添加音频文件'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return _buildAudioList(items);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndAddAudioFiles,
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: '添加音频文件',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAudioList(List<AudioItem> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          '这里空空如也\n点击右下角按钮添加音频',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      // 使用高性能滚动物理效果
      physics: PerformanceConfig.optimizedScrollPhysics,
      itemCount: items.length,
      // 添加缓存范围以提高滚动性能
      cacheExtent: 500,
      itemBuilder: (context, index) {
        final item = items[index];
        return AudioListItem(
          item: item,
          onLongPress: () => _deleteAudioItem(item),
        );
      },
    );
  }

  void _deleteAudioItem(AudioItem audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${audio.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 先关闭对话框
              await _performDeleteAudio(audio);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAudio(AudioItem audio) async {
    try {
      final audioService = Provider.of<AudioPlayerService>(
        context,
        listen: false,
      );
      final audioLibraryService = context.read<AudioLibraryService>();

      // 检查是否正在播放要删除的音频
      bool wasPlayingDeletedAudio = false;
      if (audioService.currentSong == audio.title) {
        wasPlayingDeletedAudio = true;
        // 完全清除播放器状态和音频数据
        await audioService.clearAudioData();
        debugPrint('已停止播放被删除的音频: ${audio.title}');
      }

      // 从库中删除音频
      await audioLibraryService.removeAudio(audio.id);

      if (mounted) {
        String message = wasPlayingDeletedAudio ? '音频已删除并停止播放' : '音频已删除';
        _showSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('删除失败: $e', isError: true);
      }
    }
  }

  /// 选择并添加音频文件
  Future<void> _pickAndAddAudioFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true, // 允许选择多个文件
      );

      if (result != null && mounted) {
        // 过滤出有效的文件路径
        List<String> validFilePaths = [];
        List<String> validFileNames = [];
        List<String> invalidFiles = [];

        for (PlatformFile file in result.files) {
          if (file.path != null && File(file.path!).existsSync()) {
            validFilePaths.add(file.path!);
            validFileNames.add(file.name);
          } else {
            invalidFiles.add(file.name);
          }
        }

        if (invalidFiles.isNotEmpty && mounted) {
          _showSnackBar('以下文件无法访问: ${invalidFiles.join(', ')}');
        }

        if (validFilePaths.isEmpty) {
          if (mounted) {
            _showSnackBar('没有有效的音频文件可以添加');
          }
          return;
        }

        // 显示加载对话框
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text('正在添加 ${validFilePaths.length} 个音频文件...'),
              ],
            ),
          ),
        );

        if (mounted) {
          final audioLibraryService = context.read<AudioLibraryService>();

          if (validFilePaths.length == 1) {
            // 单个文件
            await audioLibraryService.addLocalAudio(validFilePaths.first);
          } else {
            // 多个文件
            await audioLibraryService.addLocalAudioBatch(validFilePaths);
          }

          if (mounted) {
            Navigator.of(context).pop(); // 关闭加载对话框

            String message = validFilePaths.length == 1
                ? '音频文件 "${validFileNames.first}" 已添加'
                : '成功添加 ${validFilePaths.length} 个音频文件';

            _showSnackBar(message);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // 确保关闭加载对话框
        try {
          Navigator.of(context).pop();
        } catch (_) {
          // 忽略关闭对话框的错误
        }

        _showSnackBar('添加音频文件失败: $e', isError: true);
      }
    }
  }

  // 显示通知的辅助函数
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    CustomToast.show(
      context,
      message: message,
      type: isError ? ToastType.error : ToastType.success,
    );
  }

  // 刷新音频库
  Future<void> _refreshAudioLibrary() async {
    final audioLibrary = Provider.of<AudioLibraryService>(
      context,
      listen: false,
    );
    await audioLibrary.refreshLibrary();
    _showSnackBar('音频库已刷新');
  }
}

class AudioListItem extends StatelessWidget {
  final AudioItem item;
  final VoidCallback? onLongPress;

  const AudioListItem({super.key, required this.item, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final audioLibraryService = Provider.of<AudioLibraryService>(
      context,
      listen: false,
    );

    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        final isPlaying =
            audioService.isPlaying &&
            audioService.audioData?.audioFilePath == item.filePath;
        final isCurrent =
            audioService.audioData?.audioFilePath == item.filePath;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // 点击卡片进入字幕界面
                if (item.isASR && item.transcriptionResult != null) {
                  // ASR音频：创建AudioPlayData并显示转录结果
                  final audioData = _createAudioPlayDataForASR(item);
                  context.push(
                    '/music-player',
                    extra: {
                      'audioData': audioData,
                      'isTranscriptionAudio': true,
                    },
                  );
                } else {
                  // 普通音频：只传递文件路径
                  context.push(
                    '/music-player',
                    extra: {
                      'filePath': item.filePath,
                      'title': item.title,
                      'artist': item.artist,
                    },
                  );
                }
              },
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 播放按钮
                    GestureDetector(
                      onTap: () async {
                        // 增加播放次数
                        if (item.id != null) {
                          audioLibraryService.incrementPlayCount(item.id!);
                        }

                        if (isCurrent) {
                          audioService.togglePlayPause();
                        } else {
                          try {
                            await audioService.playFromFile(
                              item.filePath,
                              songTitle: item.title,
                              artist: item.artist,
                            );
                          } catch (e) {
                            // 使用 Home 页面上下文中定义的辅助函数
                            (context as Element)
                                .findAncestorStateOfType<HomePageState>()
                                ?._showSnackBar(
                                  '播放失败: ${e.toString().replaceFirst('Exception: ', '')}',
                                  isError: true,
                                );
                          }
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isCurrent ? Colors.white : Colors.grey[700],
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 音频信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isCurrent
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (item.isTTS) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TTS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (item.isASR) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ASR',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  item.artist,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(item.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (item.fileSize != null) ...[
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.storage,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatFileSize(item.fileSize!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 收藏按钮
                    IconButton(
                      icon: Icon(
                        item.isFavorite ? Icons.star : Icons.star_border,
                        color: item.isFavorite ? Colors.amber : Colors.grey,
                      ),
                      onPressed: () {
                        if (item.id != null) {
                          audioLibraryService.toggleFavorite(item.id!);
                        }
                      },
                    ),
                    // 播放状态指示器
                    // if (isCurrent)
                    //   Icon(
                    //     isPlaying ? Icons.volume_up : Icons.volume_off,
                    //     color: Theme.of(context).primaryColor,
                    //     size: 24,
                    //   ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 为ASR音频创建AudioPlayData
  AudioPlayData _createAudioPlayDataForASR(AudioItem item) {
    try {
      // 解析转录结果JSON
      final transcriptionData = json.decode(item.transcriptionResult!);

      // 检查是否是新的完整播放器数据格式
      if (transcriptionData.containsKey('type') &&
          transcriptionData['type'] == 'whisperx_player_data') {
        // 使用AudioPlayerUtils创建，与ASR页面预览保持一致
        final playerData =
            transcriptionData['playerData'] as Map<String, dynamic>;
        return AudioPlayerUtils.createFromWhisperXData(
          taskId: transcriptionData['taskId'] ?? 'asr_${item.id}',
          filename: transcriptionData['filename'] ?? item.title,
          audioFilePath: item.filePath,
          transcriptionData: playerData['transcription'],
          wordstampsData: playerData['wordstamps'],
          speakerData: playerData['speaker_segments'],
        );
      }

      List<LyricLine> lyrics = [];
      List<Speaker> speakers = [];

      // 检查是否是WhisperX格式（包含segments）
      if (transcriptionData.containsKey('segments')) {
        final segments = transcriptionData['segments'] as List;

        for (int i = 0; i < segments.length; i++) {
          final segment = segments[i];

          // 处理说话人信息
          String? speakerId = segment['speaker']?.toString();
          if (speakerId != null && !speakers.any((s) => s.id == speakerId)) {
            speakers.add(
              Speaker(
                id: speakerId,
                name: '说话人 ${speakers.length + 1}',
                color: _getSpeakerColor(speakers.length),
              ),
            );
          }

          // 创建词级时间戳
          List<WordTimestamp> words = [];
          if (segment.containsKey('words')) {
            final wordList = segment['words'] as List;
            for (final word in wordList) {
              words.add(
                WordTimestamp(
                  word: word['word']?.toString() ?? '',
                  start: (word['start'] ?? 0.0).toDouble(),
                  end: (word['end'] ?? 0.0).toDouble(),
                  confidence: word['confidence']?.toDouble(),
                  speaker: speakerId,
                ),
              );
            }
          }

          // 创建歌词行
          lyrics.add(
            LyricLine(
              id: i,
              text: segment['text']?.toString() ?? '',
              start: (segment['start'] ?? 0.0).toDouble(),
              end: (segment['end'] ?? 0.0).toDouble(),
              speaker: speakerId,
              confidence: segment['confidence']?.toDouble(),
              words: words,
            ),
          );
        }
      } else {
        // 简单文本格式，创建单个歌词行
        lyrics.add(
          LyricLine(
            id: 0,
            text: item.transcriptionResult!,
            start: 0.0,
            end: 60.0, // 默认时长
            words: [],
          ),
        );
      }

      return AudioPlayData(
        taskId: 'asr_${item.id}',
        filename: item.title,
        audioFilePath: item.filePath,
        language: 'auto',
        lyrics: lyrics,
        speakers: speakers,
        duration: 0.0, // 实际播放时会获取
      );
    } catch (e) {
      debugPrint('解析ASR转录结果失败: $e');
      // 创建简单的AudioPlayData
      return AudioPlayData(
        taskId: 'asr_${item.id}',
        filename: item.title,
        audioFilePath: item.filePath,
        language: 'auto',
        lyrics: [
          LyricLine(
            id: 0,
            text: item.transcriptionResult ?? '转录结果解析失败',
            start: 0.0,
            end: 60.0,
            words: [],
          ),
        ],
        speakers: [],
        duration: 0.0,
      );
    }
  }

  /// 获取说话人颜色
  String _getSpeakerColor(int index) {
    final colors = [
      '#FF6B6B',
      '#4ECDC4',
      '#45B7D1',
      '#F9CA24',
      '#F0932B',
      '#EB4D4B',
      '#6C5CE7',
      '#A29BFE',
    ];
    return colors[index % colors.length];
  }
}
