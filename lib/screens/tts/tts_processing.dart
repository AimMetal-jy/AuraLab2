import 'package:flutter/material.dart';
import 'package:auralab_0701/services/tts_selection_service.dart';

class TtsProcessingPage extends StatefulWidget {
  const TtsProcessingPage({super.key});

  @override
  TtsProcessingPageState createState() => TtsProcessingPageState();
}

class TtsProcessingPageState extends State<TtsProcessingPage> {
  final TtsSelectionService _selectionService = TtsSelectionService();
  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;
  late Future<List<String>> _textsFuture;

  @override
  void initState() {
    super.initState();
    _loadTexts();
  }

  void _loadTexts() {
    _textsFuture = _selectionService.selectedTexts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS音频处理区'),
        actions: [
          IconButton(
            onPressed: _selectionService.isEmpty ? null : _showClearDialog,
            icon: const Icon(Icons.delete),
            tooltip: '清空全部',
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
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
                  Icon(
                    Icons.text_fields,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '待选区为空',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '请先从AI聊天中添加文字到待选区',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
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
                              Text(
                                text,
                                style: const TextStyle(fontSize: 16),
                              ),
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
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: texts.isEmpty ? null : _uploadToTts,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      '上传至后端进行TTS处理',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
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

  void _uploadToTts() {
    // TODO: 实现TTS上传功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('TTS处理功能待实现'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }
}