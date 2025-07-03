import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/translation_service.dart';
import '../widgets/custom_toast.dart';
import '../models/translation_practice.dart';
import 'translation_practice_page.dart';

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

  final List<TranslationHistory> _history = [];
  Map<String, String> _languages = {
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
  void initState() {
    super.initState();
    _loadSupportedLanguages();
  }

  Future<void> _loadSupportedLanguages() async {
    try {
      final languages = await TranslationService.getSupportedLanguages();
      setState(() {
        _languages = languages;
      });
    } catch (e) {
      debugPrint('加载语言列表失败: $e');
    }
  }

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
          // 翻译练习区域
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '翻译练习',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // 查看更多练习
                        CustomToast.show(
                          context,
                          message: '更多练习功能开发中',
                          type: ToastType.info,
                        );
                      },
                      child: const Text('查看更多'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:
                        TranslationPracticeService.getAllPractices().length,
                    itemBuilder: (context, index) {
                      final practice =
                          TranslationPracticeService.getAllPractices()[index];
                      return _buildPracticeCard(practice);
                    },
                  ),
                ),
                const SizedBox(height: 16),
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
                                _languages[_sourceLanguage] ?? '未知语言',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  _sourceController.clear();
                                  _targetController.clear();
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
                                _languages[_targetLanguage] ?? '未知语言',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.copy,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  if (_targetController.text.isNotEmpty) {
                                    _copyToClipboard(_targetController.text);
                                  }
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
                    // 功能按钮行
                    Row(
                      children: [
                        Expanded(
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              foregroundColor: Colors.red[700],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.clear_all),
                                SizedBox(width: 8),
                                Text('清除历史'),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPracticeCard(TranslationPractice practice) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    TranslationPracticePage(practice: practice),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      practice.iconPath,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        practice.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  practice.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getPracticeColorFromString(
                          practice.thumbnailColor,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        practice.difficulty,
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPracticeColorFromString(
                            practice.thumbnailColor,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${practice.exercises.length}题',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPracticeColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _translate() async {
    if (_sourceController.text.trim().isEmpty) {
      CustomToast.show(context, message: '请输入要翻译的文本', type: ToastType.error);
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final result = await TranslationService.translate(
        text: _sourceController.text.trim(),
        fromLanguage: _sourceLanguage,
        toLanguage: _targetLanguage,
      );

      if (result.success && result.translation != null) {
        setState(() {
          _targetController.text = result.translation!;

          // 添加到历史记录
          final history = TranslationHistory(
            originalText: _sourceController.text.trim(),
            translatedText: result.translation!,
            fromLanguage: _sourceLanguage,
            toLanguage: _targetLanguage,
            timestamp: DateTime.now(),
          );
          _history.insert(0, history);

          // 限制历史记录数量
          if (_history.length > 100) {
            _history.removeRange(100, _history.length);
          }
        });

        if (mounted) {
          CustomToast.show(context, message: '翻译成功', type: ToastType.success);
        }
      } else {
        if (mounted) {
          CustomToast.show(
            context,
            message: result.message,
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '翻译失败: $e', type: ToastType.error);
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.show(context, message: '已复制到剪贴板', type: ToastType.success);
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除历史记录'),
        content: const Text('确定要清除所有翻译历史记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _history.clear();
              });
              Navigator.of(context).pop();
              CustomToast.show(
                context,
                message: '历史记录已清除',
                type: ToastType.success,
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 8),
            const Text('翻译历史'),
            const Spacer(),
            Text(
              '${_history.length} 条记录',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _history.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        '暂无翻译历史',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          item.originalText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.translatedText,
                              style: const TextStyle(color: Colors.blue),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '${_languages[item.fromLanguage] ?? item.fromLanguage} → ${_languages[item.toLanguage] ?? item.toLanguage}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(item.timestamp),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          _sourceController.text = item.originalText;
                          _targetController.text = item.translatedText;
                          _sourceLanguage = item.fromLanguage;
                          _targetLanguage = item.toLanguage;
                          setState(() {});
                          Navigator.of(context).pop();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _history.removeAt(index);
                            });
                          },
                        ),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }
}
