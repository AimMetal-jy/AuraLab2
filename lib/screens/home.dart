import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_player_service.dart';
import '../services/audio_library_service.dart';
import 'dart:io';

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
    _tabController = TabController(length: 3, vsync: this);
    // 刷新音频库
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioLibraryService>().refresh();
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
                              '共 ${library.totalCount} 个音频 · ${library.ttsCount} 个TTS生成',
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
                        TextButton.icon(
                          onPressed: () => context.push('/tts-processing'),
                          icon: const Icon(Icons.record_voice_over),
                          label: const Text('TTS处理'),
                        ),
                        const SizedBox(width: 8),
                        // 刷新按钮
                        IconButton(
                          onPressed: () {
                            context.read<AudioLibraryService>().refresh();
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final audio = items[index];
                    return _buildAudioItem(audio);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndAddAudioFiles,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: '添加音频文件',
      ),
    );
  }

  Widget _buildAudioItem(AudioItem audio) {
    final audioService = Provider.of<AudioPlayerService>(context, listen: true);
    final isPlaying =
        audioService.currentSong == audio.title && audioService.isPlaying;
    final isCurrent = audioService.currentSong == audio.title;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _playAudio(audio),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrent
                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                : null,
          ),
          child: Row(
            children: [
              // 播放按钮
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: () => _playAudio(audio),
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isCurrent ? Colors.white : Colors.grey[700],
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
                      audio.title,
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
                        if (audio.isTTS) ...[
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
                        Expanded(
                          child: Text(
                            audio.artist,
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
                          _formatDateTime(audio.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (audio.fileSize != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.storage,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFileSize(audio.fileSize!),
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
              // 更多操作
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'delete':
                      _deleteAudio(audio);
                      break;
                    case 'info':
                      _showAudioInfo(audio);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text('详细信息'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _playAudio(AudioItem audio) async {
    try {
      final audioService = Provider.of<AudioPlayerService>(
        context,
        listen: false,
      );

      // 如果当前正在播放这个音频，则暂停
      if (audioService.currentSong == audio.title && audioService.isPlaying) {
        await audioService.pause();
      } else {
        // 检查音频文件是否存在
        if (!File(audio.filePath).existsSync()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('音频文件不存在: ${audio.title}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // 播放音频
        await audioService.playFromFile(
          audio.filePath,
          songTitle: audio.title,
          artist: audio.artist,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAudio(AudioItem audio) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除音频 "${audio.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final audioService = Provider.of<AudioPlayerService>(
          context,
          listen: false,
        );

        // 检查是否正在播放要删除的音频
        bool wasPlayingDeletedAudio = false;
        if (audioService.currentSong == audio.title) {
          wasPlayingDeletedAudio = true;
          // 完全清除播放器状态和音频数据
          await audioService.clearAudioData();
          debugPrint('已停止播放被删除的音频: ${audio.title}');
        }

        // 从库中删除音频
        await context.read<AudioLibraryService>().removeAudio(audio.id);

        if (mounted) {
          String message = wasPlayingDeletedAudio ? '音频已删除并停止播放' : '音频已删除';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  void _showAudioInfo(AudioItem audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(audio.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('类型', audio.isTTS ? 'TTS生成' : '本地音频'),
            _buildInfoRow('艺术家', audio.artist),
            _buildInfoRow('创建时间', _formatDateTime(audio.createdAt)),
            if (audio.fileSize != null)
              _buildInfoRow('文件大小', _formatFileSize(audio.fileSize!)),
            _buildInfoRow('文件路径', audio.filePath, wrap: true),
          ],
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

  Widget _buildInfoRow(String label, String value, {bool wrap = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
              maxLines: wrap ? null : 1,
              overflow: wrap ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('以下文件无法访问: ${invalidFiles.join(', ')}'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        if (validFilePaths.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('没有有效的音频文件可以添加'),
                backgroundColor: Colors.red,
              ),
            );
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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加音频文件失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
