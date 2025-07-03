import 'package:flutter/material.dart';

class VocabularyBookPage extends StatefulWidget {
  const VocabularyBookPage({super.key});

  @override
  State<VocabularyBookPage> createState() => _VocabularyBookPageState();
}

class _VocabularyBookPageState extends State<VocabularyBookPage> {
  final List<Map<String, String>> _vocabulary = [
    {
      'word': 'Example',
      'translation': '例子',
      'sentence': 'This is an example sentence.',
      'phonetic': '/ɪɡˈzɑːmpəl/',
    },
    {
      'word': 'Learning',
      'translation': '学习',
      'sentence': 'I am learning Flutter.',
      'phonetic': '/ˈlɜːrnɪŋ/',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
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
                    const Text(
                      '0',
                      style: TextStyle(
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
                    const Icon(Icons.schedule, color: Colors.green, size: 24),
                    const SizedBox(height: 4),
                    const Text(
                      '0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      '今日学习',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 生词列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _vocabulary.length,
              itemBuilder: (context, index) {
                final word = _vocabulary[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        word['word']![0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      word['word']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                          icon: const Icon(Icons.volume_up, color: Colors.blue),
                          onPressed: () {
                            // TODO: 播放发音
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            // TODO: 收藏/取消收藏
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // TODO: 显示详细信息
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
          // TODO: 添加新单词
          _showAddWordDialog();
        },
        child: const Icon(Icons.add),
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
        content: Column(
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
                    'sentence': sentenceController.text,
                    'phonetic': phoneticController.text,
                  });
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
