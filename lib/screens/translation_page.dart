import 'package:flutter/material.dart';

class TranslationPage extends StatefulWidget {
  const TranslationPage({super.key});

  @override
  State<TranslationPage> createState() => _TranslationPageState();
}

class _TranslationPageState extends State<TranslationPage> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _sourceLanguage = 'en';
  String _targetLanguage = 'zh';
  bool _isTranslating = false;

  final List<Map<String, String>> _history = [];

  final Map<String, String> _languages = {
    'en': '英语',
    'zh': '中文',
    'ja': '日语',
    'ko': '韩语',
    'fr': '法语',
    'de': '德语',
    'es': '西班牙语',
    'it': '意大利语',
    'ru': '俄语',
    'ar': '阿拉伯语',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 语言选择区域
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
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
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _sourceLanguage,
                    isExpanded: true,
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _sourceLanguage = newValue!;
                      });
                    },
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      String temp = _sourceLanguage;
                      _sourceLanguage = _targetLanguage;
                      _targetLanguage = temp;

                      String tempText = _sourceController.text;
                      _sourceController.text = _targetController.text;
                      _targetController.text = tempText;
                    });
                  },
                ),
                Expanded(
                  child: DropdownButton<String>(
                    value: _targetLanguage,
                    isExpanded: true,
                    underline: Container(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _targetLanguage = newValue!;
                      });
                    },
                    items: _languages.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // 翻译输入区域
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // 源语言输入框
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _languages[_sourceLanguage]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  // TODO: 播放源语言发音
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _sourceController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: '请输入要翻译的文本...',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 翻译按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTranslating ? null : _translate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isTranslating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('翻译中...'),
                                ],
                              )
                            : const Text('翻译', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 翻译结果区域
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _languages[_targetLanguage]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_up,
                                  color: Colors.green,
                                ),
                                onPressed: () {
                                  // TODO: 播放翻译结果发音
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  // TODO: 复制翻译结果
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 120,
                            child: TextField(
                              controller: _targetController,
                              maxLines: null,
                              readOnly: true,
                              decoration: const InputDecoration(
                                hintText: '翻译结果将显示在这里...',
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 历史记录按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showHistoryDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history),
                            SizedBox(width: 8),
                            Text('翻译历史'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _translate() async {
    if (_sourceController.text.isEmpty) return;

    setState(() {
      _isTranslating = true;
    });

    // 模拟翻译过程
    await Future.delayed(const Duration(seconds: 2));

    // 这里应该调用实际的翻译API
    String translatedText = _mockTranslate(
      _sourceController.text,
      _sourceLanguage,
      _targetLanguage,
    );

    setState(() {
      _targetController.text = translatedText;
      _isTranslating = false;

      // 添加到历史记录
      _history.insert(0, {
        'source': _sourceController.text,
        'target': translatedText,
        'sourceLang': _sourceLanguage,
        'targetLang': _targetLanguage,
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  String _mockTranslate(String text, String from, String to) {
    // 这是一个模拟翻译函数，实际应该调用翻译API
    if (from == 'en' && to == 'zh') {
      return '这是一个模拟翻译结果：$text';
    } else if (from == 'zh' && to == 'en') {
      return 'This is a mock translation result: $text';
    } else {
      return '[翻译结果] $text';
    }
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('翻译历史'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _history.isEmpty
              ? const Center(child: Text('暂无翻译历史'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['source']!),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item['target']!,
                              style: const TextStyle(color: Colors.blue),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_languages[item['sourceLang']!]} → ${_languages[item['targetLang']!]}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _sourceController.text = item['source']!;
                          _targetController.text = item['target']!;
                          _sourceLanguage = item['sourceLang']!;
                          _targetLanguage = item['targetLang']!;
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
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

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }
}
