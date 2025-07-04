import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/custom_toast.dart';
import 'package:provider/provider.dart';

class VocabularyBookPage extends StatefulWidget {
  const VocabularyBookPage({super.key});

  @override
  State<VocabularyBookPage> createState() => _VocabularyBookPageState();
}

class _VocabularyBookPageState extends State<VocabularyBookPage> {
  final TtsService _ttsService = TtsService();
  final List<Map<String, dynamic>> _vocabulary = [
    {
      'word': 'Example',
      'translation': '例子',
      'sentence': 'This is an example sentence.',
      'phonetic': '/ɪɡˈzɑːmpəl/',
      'isFavorite': false,
      'isMastered': false,
    },
    {
      'word': 'Learning',
      'translation': '学习',
      'sentence': 'I am learning Flutter.',
      'phonetic': '/ˈlɜːrnɪŋ/',
      'isFavorite': false,
      'isMastered': false,
    },
  ];

  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  bool _showMasteredOnly = false;
  bool _isPlayingAudio = false;

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  // 播放单词发音
  Future<void> _playWordPronunciation(String word) async {
    if (_isPlayingAudio) return;

    setState(() {
      _isPlayingAudio = true;
    });

    try {
      // 使用TTS服务生成英文发音
      final audioPath = await _ttsService.generateTTS(
        text: word,
        mode: 'short',
        vcn: 'x2_F82', // 使用英文女声
        addToLibrary: false, // 不添加到音频库
      );

      if (!mounted) return;

      // 使用AudioPlayerService播放生成的音频
      final audioService = Provider.of<AudioPlayerService>(
        context,
        listen: false,
      );
      await audioService.playFromFile(audioPath, songTitle: word);

      if (mounted) {
        CustomToast.show(
          context,
          message: '正在播放: $word',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '播放失败: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredVocabulary {
    var filtered = _vocabulary.where((word) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!word['word'].toString().toLowerCase().contains(query) &&
            !word['translation'].toString().toLowerCase().contains(query)) {
          return false;
        }
      }
      // 收藏过滤
      if (_showFavoritesOnly && !(word['isFavorite'] ?? false)) {
        return false;
      }
      // 已掌握过滤
      if (_showMasteredOnly && !(word['isMastered'] ?? false)) {
        return false;
      }
      return true;
    }).toList();

    return filtered;
  }

  int get _masteredCount =>
      _vocabulary.where((w) => w['isMastered'] ?? false).length;
  int get _favoriteCount =>
      _vocabulary.where((w) => w['isFavorite'] ?? false).length;

  @override
  Widget build(BuildContext context) {
    final filteredVocabulary = _filteredVocabulary;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 搜索栏和过滤器
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // 搜索框
                TextField(
                  decoration: InputDecoration(
                    hintText: '搜索单词或翻译...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // 过滤器按钮
                Row(
                  children: [
                    FilterChip(
                      label: const Text('仅收藏'),
                      selected: _showFavoritesOnly,
                      onSelected: (value) {
                        setState(() {
                          _showFavoritesOnly = value;
                        });
                      },
                      selectedColor: Colors.red[100],
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('已掌握'),
                      selected: _showMasteredOnly,
                      onSelected: (value) {
                        setState(() {
                          _showMasteredOnly = value;
                        });
                      },
                      selectedColor: Colors.green[100],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 顶部统计信息
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.book, color: Colors.blue, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_vocabulary.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '总词汇',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '$_masteredCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '已掌握',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '$_favoriteCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '收藏',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 生词列表
          Expanded(
            child: filteredVocabulary.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty ? '没有找到匹配的单词' : '暂无单词',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredVocabulary.length,
                    itemBuilder: (context, index) {
                      final word = filteredVocabulary[index];
                      final isFavorite = word['isFavorite'] ?? false;
                      final isMastered = word['isMastered'] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isMastered
                                ? Colors.green[100]
                                : Colors.blue[100],
                            child: Text(
                              word['word']![0].toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMastered ? Colors.green : Colors.blue,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                word['word']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isMastered) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word['phonetic']!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                word['translation']!,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                word['sentence']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up,
                                  color: _isPlayingAudio
                                      ? Colors.grey
                                      : Colors.blue,
                                ),
                                onPressed: _isPlayingAudio
                                    ? null
                                    : () =>
                                          _playWordPronunciation(word['word']!),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  // 收藏/取消收藏
                                  setState(() {
                                    word['isFavorite'] = !isFavorite;
                                  });
                                  CustomToast.show(
                                    context,
                                    message: isFavorite ? '已取消收藏' : '已收藏',
                                    type: ToastType.success,
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            // 显示详细信息
                            _showWordDetailDialog(word);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddWordDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showWordDetailDialog(Map<String, dynamic> word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(word['word']!),
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: word['word']!));
                CustomToast.show(
                  context,
                  message: '已复制到剪贴板',
                  type: ToastType.success,
                );
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 音标
              Row(
                children: [
                  Text(
                    word['phonetic']!,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: _isPlayingAudio ? Colors.grey : Colors.blue,
                    ),
                    onPressed: _isPlayingAudio
                        ? null
                        : () => _playWordPronunciation(word['word']!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 翻译
              const Text('翻译：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(word['translation']!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              // 例句
              const Text('例句：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(word['sentence']!, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 20),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        word['isFavorite'] = !(word['isFavorite'] ?? false);
                      });
                      Navigator.of(context).pop();
                      CustomToast.show(
                        context,
                        message: word['isFavorite'] ? '已收藏' : '已取消收藏',
                        type: ToastType.success,
                      );
                    },
                    icon: Icon(
                      (word['isFavorite'] ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                    label: Text((word['isFavorite'] ?? false) ? '已收藏' : '收藏'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        word['isMastered'] = !(word['isMastered'] ?? false);
                      });
                      Navigator.of(context).pop();
                      CustomToast.show(
                        context,
                        message: word['isMastered'] ? '已标记为掌握' : '已取消掌握',
                        type: ToastType.success,
                      );
                    },
                    icon: Icon(
                      (word['isMastered'] ?? false)
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text((word['isMastered'] ?? false) ? '已掌握' : '掌握'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
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

  void _showAddWordDialog() {
    final TextEditingController wordController = TextEditingController();
    final TextEditingController translationController = TextEditingController();
    final TextEditingController sentenceController = TextEditingController();
    final TextEditingController phoneticController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加新单词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: wordController,
                decoration: const InputDecoration(labelText: '单词'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneticController,
                decoration: const InputDecoration(labelText: '音标'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: translationController,
                decoration: const InputDecoration(labelText: '翻译'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sentenceController,
                decoration: const InputDecoration(labelText: '例句'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (wordController.text.isNotEmpty &&
                  translationController.text.isNotEmpty) {
                setState(() {
                  _vocabulary.add({
                    'word': wordController.text,
                    'translation': translationController.text,
                    'sentence': sentenceController.text.isEmpty
                        ? 'No example sentence provided.'
                        : sentenceController.text,
                    'phonetic': phoneticController.text.isEmpty
                        ? '//'
                        : phoneticController.text,
                    'isFavorite': false,
                    'isMastered': false,
                  });
                });
                Navigator.of(context).pop();
                CustomToast.show(
                  context,
                  message: '单词已添加',
                  type: ToastType.success,
                );
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
