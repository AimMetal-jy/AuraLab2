import 'package:flutter/material.dart';
import 'package:auralab_0701/services/tts_selection_service.dart';
import 'package:auralab_0701/services/tts_service.dart';
import 'package:auralab_0701/services/audio_player_service.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class TtsProcessingPage extends StatefulWidget {
  const TtsProcessingPage({super.key});

  @override
  TtsProcessingPageState createState() => TtsProcessingPageState();
}

class TtsProcessingPageState extends State<TtsProcessingPage>
    with TickerProviderStateMixin {
  final TtsSelectionService _selectionService = TtsSelectionService();
  final TtsService _ttsService = TtsService();
  final TextEditingController _editController = TextEditingController();

  int? _editingIndex;
  late Future<List<String>> _textsFuture;
  late TabController _tabController;

  // TTS设置
  String _selectedMode = 'human';
  TTSVoice? _selectedVoice;
  bool _isGenerating = false;

  // 音频文件列表
  List<File> _audioFiles = [];
  bool _isLoadingFiles = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTexts();
    _loadAudioFiles();
    _initializeVoice();
  }

  void _initializeVoice() {
    final voices = TTSVoices.getVoicesByMode(_selectedMode);
    if (voices.isNotEmpty) {
      _selectedVoice = voices.first;
    }
  }

  void _loadTexts() {
    _textsFuture = _selectionService.selectedTexts;
  }

  Future<void> _loadAudioFiles() async {
    setState(() {
      _isLoadingFiles = true;
    });

    try {
      final files = await _ttsService.getTTSFiles();
      setState(() {
        _audioFiles = files;
        _isLoadingFiles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFiles = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载音频文件失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS音频处理区'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_format), text: '文字处理'),
            Tab(icon: Icon(Icons.audio_file), text: '音频文件'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _selectionService.isEmpty ? null : _showClearDialog,
            icon: const Icon(Icons.delete),
            tooltip: '清空全部',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTextProcessingTab(), _buildAudioFilesTab()],
      ),
    );
  }

  Widget _buildTextProcessingTab() {
    return FutureBuilder<List<String>>(
      future: _textsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('加载失败: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loadTexts();
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final texts = snapshot.data ?? [];

        if (texts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.text_fields, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '待选区为空',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  '请先从AI聊天中添加文字到待选区',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // TTS设置面板
            _buildTTSSettingsPanel(),
            // 文字列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: texts.length,
                itemBuilder: (context, index) {
                  final text = texts[index];
                  final isEditing = _editingIndex == index;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isEditing)
                            TextField(
                              controller: _editController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: '编辑文字内容',
                                border: OutlineInputBorder(),
                              ),
                            )
                          else
                            Text(text, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isEditing) ...[
                                TextButton(
                                  onPressed: _cancelEdit,
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _saveEdit(index),
                                  child: const Text('保存'),
                                ),
                              ] else ...[
                                TextButton(
                                  onPressed: () => _generateSingleTTS(text),
                                  child: const Text('单独生成'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _startEdit(index, text),
                                  child: const Text('编辑'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => _removeText(index),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('删除'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 批量生成按钮
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (texts.isEmpty || _isGenerating)
                      ? null
                      : _uploadToTts,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('正在生成音频...'),
                          ],
                        )
                      : const Text('批量生成TTS音频', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTTSSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TTS设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // 模式选择
          const Text('合成模式:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('大模型'),
                  subtitle: const Text('高质量'),
                  value: 'human',
                  groupValue: _selectedMode,
                  onChanged: _onModeChanged,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('短音频'),
                  subtitle: const Text('快速'),
                  value: 'short',
                  groupValue: _selectedMode,
                  onChanged: _onModeChanged,
                  dense: true,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('长音频'),
                  subtitle: const Text('稳定'),
                  value: 'long',
                  groupValue: _selectedMode,
                  onChanged: _onModeChanged,
                  dense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 音色选择
          const Text('音色选择:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<TTSVoice>(
            value: _selectedVoice,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: TTSVoices.getVoicesByMode(_selectedMode).map((voice) {
              return DropdownMenuItem<TTSVoice>(
                value: voice,
                child: Text(voice.name),
              );
            }).toList(),
            onChanged: (voice) {
              setState(() {
                _selectedVoice = voice;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAudioFilesTab() {
    return RefreshIndicator(
      onRefresh: _loadAudioFiles,
      child: _isLoadingFiles
          ? const Center(child: CircularProgressIndicator())
          : _audioFiles.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audio_file, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无音频文件',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请先生成TTS音频',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _audioFiles.length,
              itemBuilder: (context, index) {
                final file = _audioFiles[index];
                final fileName = file.path.split('/').last;
                final fileSize = file.lengthSync();
                final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);
                final modifiedTime = file.lastModifiedSync();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.audio_file)),
                    title: Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('大小: ${fileSizeKB}KB'),
                        Text('时间: ${_formatDateTime(modifiedTime)}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Consumer<AudioPlayerService>(
                          builder: (context, audioService, child) {
                            final isPlaying =
                                audioService.currentSong == fileName &&
                                audioService.isPlaying;
                            return IconButton(
                              onPressed: () => _playAudio(file, fileName),
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: isPlaying ? '暂停' : '播放',
                            );
                          },
                        ),
                        IconButton(
                          onPressed: () => _deleteAudioFile(file, index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: '删除',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _onModeChanged(String? mode) {
    if (mode != null) {
      setState(() {
        _selectedMode = mode;
        _initializeVoice();
      });
    }
  }

  void _startEdit(int index, String text) {
    setState(() {
      _editingIndex = index;
      _editController.text = text;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _editController.clear();
    });
  }

  Future<void> _saveEdit(int index) async {
    final newText = _editController.text.trim();
    if (newText.isNotEmpty) {
      try {
        await _selectionService.updateTextAt(index, newText);
        setState(() {
          _editingIndex = null;
          _editController.clear();
          _loadTexts();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
        }
      }
    }
  }

  Future<void> _removeText(int index) async {
    try {
      await _selectionService.removeTextAt(index);
      setState(() {
        if (_editingIndex == index) {
          _editingIndex = null;
          _editController.clear();
        } else if (_editingIndex != null && _editingIndex! > index) {
          _editingIndex = _editingIndex! - 1;
        }
        _loadTexts();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有待选文字吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              navigator.pop();
              try {
                await _selectionService.clearAll();
                if (mounted) {
                  setState(() {
                    _editingIndex = null;
                    _editController.clear();
                    _loadTexts();
                  });
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('清空失败: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSingleTTS(String text) async {
    if (_selectedVoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择音色')));
      return;
    }

    try {
      setState(() {
        _isGenerating = true;
      });

      // 显示上传成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('文字上传成功，正在处理...'),
          duration: Duration(seconds: 2),
        ),
      );

      await _ttsService.generateTTS(
        text: text,
        mode: _selectedMode,
        vcn: _selectedVoice!.id,
      );

      // 显示处理成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('音频处理成功！已保存到本地'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 刷新音频文件列表
      await _loadAudioFiles();

      // 切换到音频文件标签页
      if (mounted) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _uploadToTts() async {
    if (_selectedVoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先选择音色')));
      return;
    }

    final texts = await _selectionService.selectedTexts;
    if (texts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有待处理的文字')));
      }
      return;
    }

    try {
      setState(() {
        _isGenerating = true;
      });

      // 显示上传成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${texts.length}条文字上传成功，正在批量处理...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < texts.length; i++) {
        try {
          await _ttsService.generateTTS(
            text: texts[i],
            mode: _selectedMode,
            vcn: _selectedVoice!.id,
          );
          successCount++;
        } catch (e) {
          failCount++;
          debugPrint('第${i + 1}条文字TTS生成失败: $e');
        }
      }

      // 显示批量处理结果
      if (mounted) {
        final message = failCount == 0
            ? '批量处理完成！成功生成$successCount个音频文件'
            : '批量处理完成！成功$successCount个，失败$failCount个';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 刷新音频文件列表
      await _loadAudioFiles();

      // 切换到音频文件标签页
      if (mounted) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('批量TTS生成失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _playAudio(File file, String fileName) async {
    try {
      final audioService = Provider.of<AudioPlayerService>(
        context,
        listen: false,
      );

      // 如果当前正在播放这个文件，则暂停
      if (audioService.currentSong == fileName && audioService.isPlaying) {
        await audioService.pause();
      } else {
        // 播放文件
        await audioService.playFromFile(
          file.path,
          songTitle: fileName,
          artist: '生成音频',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('播放失败: $e')));
      }
    }
  }

  Future<void> _deleteAudioFile(File file, int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 "${file.path.split('/').last}" 吗？'),
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

    if (result == true) {
      try {
        final success = await _ttsService.deleteTTSFile(file.path);
        if (success) {
          setState(() {
            _audioFiles.removeAt(index);
          });
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('文件删除成功')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('文件删除失败')));
          }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _editController.dispose();
    _tabController.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
