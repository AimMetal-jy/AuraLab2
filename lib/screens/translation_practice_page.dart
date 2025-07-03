import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/translation_practice.dart';
import '../widgets/custom_toast.dart';
import '../services/ai_translation_evaluation_service.dart';

class TranslationPracticePage extends StatefulWidget {
  final TranslationPractice practice;

  const TranslationPracticePage({super.key, required this.practice});

  @override
  State<TranslationPracticePage> createState() =>
      _TranslationPracticePageState();
}

class _TranslationPracticePageState extends State<TranslationPracticePage> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isReversed = false; // 是否反向练习（中文->英文）
  final Map<int, TextEditingController> _answerControllers = {};
  final Map<int, bool> _showHints = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // 初始化控制器
    for (int i = 0; i < widget.practice.exercises.length; i++) {
      _answerControllers[i] = TextEditingController();
      _showHints[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.practice.title),
        backgroundColor: _getColorFromString(widget.practice.thumbnailColor),
        foregroundColor: Colors.white,
        actions: [
          // 反向练习开关
          IconButton(
            icon: Icon(
              _isReversed ? Icons.swap_horizontal_circle : Icons.swap_horiz,
            ),
            tooltip: _isReversed ? '切换为英文->中文' : '切换为中文->英文',
            onPressed: () {
              setState(() {
                _isReversed = !_isReversed;
                _showAnswer = false;
                // 清空当前输入
                _answerControllers[_currentIndex]?.clear();
              });
              CustomToast.show(
                context,
                message: _isReversed ? '已切换为中文->英文练习' : '已切换为英文->中文练习',
                type: ToastType.info,
              );
            },
          ),
          // 重置按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置练习',
            onPressed: _resetPractice,
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度指示器
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '进度: ${_currentIndex + 1}/${widget.practice.exercises.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '难度: ${widget.practice.difficulty}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.practice.exercises.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorFromString(widget.practice.thumbnailColor),
                  ),
                ),
              ],
            ),
          ),

          // 练习内容
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _showAnswer = false;
                });
              },
              itemCount: widget.practice.exercises.length,
              itemBuilder: (context, index) {
                return _buildExerciseCard(
                  widget.practice.exercises[index],
                  index,
                );
              },
            ),
          ),

          // 底部控制栏
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                // 上一题
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentIndex > 0 ? _previousExercise : null,
                    icon: const Icon(Icons.navigate_before),
                    label: const Text('上一题'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 查看答案/隐藏答案
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAnswer = !_showAnswer;
                      });
                    },
                    icon: Icon(
                      _showAnswer ? Icons.visibility_off : Icons.visibility,
                    ),
                    label: Text(_showAnswer ? '隐藏答案' : '查看答案'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showAnswer
                          ? Colors.red[100]
                          : Colors.blue[100],
                      foregroundColor: _showAnswer
                          ? Colors.red[700]
                          : Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // 下一题
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _currentIndex < widget.practice.exercises.length - 1
                        ? _nextExercise
                        : null,
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('下一题'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getColorFromString(
                        widget.practice.thumbnailColor,
                      ),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(TranslationExercise exercise, int index) {
    final sourceText = _isReversed ? exercise.targetText : exercise.sourceText;
    final targetText = _isReversed ? exercise.sourceText : exercise.targetText;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 上下文信息
          if (exercise.context != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '场景: ${exercise.context}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 原文区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                      Icons.text_fields,
                      color: _getColorFromString(
                        widget.practice.thumbnailColor,
                      ),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isReversed ? '中文原文' : '英文原文',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getColorFromString(
                          widget.practice.thumbnailColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      onPressed: () => _copyToClipboard(sourceText),
                      tooltip: '复制原文',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sourceText,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 答案输入区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                    const Icon(Icons.edit, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isReversed ? '请输入英文翻译' : '请输入中文翻译',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _answerControllers[index]?.clear();
                      },
                      tooltip: '清空输入',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _answerControllers[index],
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: '在此输入您的翻译...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _getColorFromString(
                          widget.practice.thumbnailColor,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 提示和答案区域
          if (_showAnswer || (_showHints[index] ?? false))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
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
                  // 标准答案
                  if (_showAnswer) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '标准答案',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.grey),
                          onPressed: () => _copyToClipboard(targetText),
                          tooltip: '复制答案',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Text(
                        targetText,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ],

                  // 提示信息
                  if ((_showHints[index] ?? false) &&
                      exercise.hints != null) ...[
                    if (_showAnswer) const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '提示',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...exercise.hints!.map(
                      (hint) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.blue),
                            ),
                            Expanded(
                              child: Text(
                                hint,
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // 解释说明
                  if (_showAnswer && exercise.explanation != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.school,
                          color: Colors.purple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '解释说明',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Text(
                        exercise.explanation!,
                        style: TextStyle(
                          color: Colors.purple[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              // 显示/隐藏提示
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: exercise.hints != null
                      ? () {
                          setState(() {
                            _showHints[index] = !(_showHints[index] ?? false);
                          });
                        }
                      : null,
                  icon: Icon(
                    _showHints[index] ?? false
                        ? Icons.lightbulb
                        : Icons.lightbulb_outline,
                  ),
                  label: Text(_showHints[index] ?? false ? '隐藏提示' : '显示提示'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_showHints[index] ?? false)
                        ? Colors.blue[100]
                        : Colors.grey[200],
                    foregroundColor: (_showHints[index] ?? false)
                        ? Colors.blue[700]
                        : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 检查答案按钮
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _checkAnswer(index, targetText),
                  icon: const Icon(Icons.check),
                  label: const Text('检查答案'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _checkAnswer(int index, String correctAnswer) async {
    final userAnswer = _answerControllers[index]?.text.trim() ?? '';

    if (userAnswer.isEmpty) {
      CustomToast.show(context, message: '请先输入您的翻译', type: ToastType.warning);
      return;
    }

    // 显示加载提示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI正在评估您的翻译，请稍等...'),
          ],
        ),
      ),
    );

    try {
      final exercise = widget.practice.exercises[index];

      // 使用AI评估服务
      final evaluation =
          await AITranslationEvaluationService.evaluateTranslation(
            originalText: _isReversed
                ? exercise.targetText
                : exercise.sourceText,
            userTranslation: userAnswer,
            standardAnswer: correctAnswer,
            sourceLanguage: _isReversed ? 'Chinese' : 'English',
            targetLanguage: _isReversed ? 'English' : 'Chinese',
            context: widget.practice.description,
          );

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      // 显示评估结果
      if (mounted) _showEvaluationResult(evaluation);

      // 自动显示答案以供对比
      setState(() {
        _showAnswer = true;
      });
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      // AI评估失败，显示错误信息
      if (mounted) {
        CustomToast.show(
          context,
          message: 'AI评估服务暂时不可用，请检查网络连接或稍后再试',
          type: ToastType.error,
        );
      }
    }
  }

  /// 显示AI评估结果对话框
  void _showEvaluationResult(AITranslationEvaluationResult evaluation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getScoreIcon(evaluation.score),
              color: _getScoreColor(evaluation.score),
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '翻译评估结果',
                style: TextStyle(
                  color: _getScoreColor(evaluation.score),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 评分和评级
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      evaluation.score,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '综合得分',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${evaluation.score.toInt()}分',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(evaluation.score),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(evaluation.score),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          evaluation.level,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 总体反馈
                Text(
                  '总体反馈',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    evaluation.feedback,
                    style: const TextStyle(height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // AI详细评分
                Text(
                  'AI详细评分',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildScoreRow(
                        '语法正确性',
                        evaluation.aiEvaluation.grammarScore,
                      ),
                      const Divider(),
                      _buildScoreRow(
                        '意思准确性',
                        evaluation.aiEvaluation.accuracyScore,
                      ),
                      const Divider(),
                      _buildScoreRow(
                        '表达流畅性',
                        evaluation.aiEvaluation.fluencyScore,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 优点
                if (evaluation.strengths.isNotEmpty) ...[
                  Text(
                    '✅ 优点',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...evaluation.strengths.map(
                    (strength) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              strength,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 改进建议
                if (evaluation.improvements.isNotEmpty) ...[
                  Text(
                    '💡 改进建议',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...evaluation.improvements.map(
                    (improvement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: Colors.orange[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              improvement,
                              style: TextStyle(color: Colors.orange[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 相似度信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '相似度分析',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(evaluation.similarity.score * 100).toInt()}% (${evaluation.similarity.method})',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        evaluation.similarity.explanation,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建评分行
  Widget _buildScoreRow(String label, double score) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(score)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${score.toInt()}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _getScoreColor(score),
          ),
        ),
      ],
    );
  }

  /// 获取评分对应的图标
  IconData _getScoreIcon(double score) {
    if (score >= 90) return Icons.emoji_events;
    if (score >= 80) return Icons.thumb_up;
    if (score >= 60) return Icons.check_circle;
    return Icons.error_outline;
  }

  /// 获取评分对应的颜色
  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.amber;
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    return Colors.red;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.show(context, message: '已复制到剪贴板', type: ToastType.success);
  }

  void _previousExercise() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextExercise() {
    if (_currentIndex < widget.practice.exercises.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetPractice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置练习'),
        content: const Text('确定要重置所有练习进度吗？这将清空您的所有输入。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 清空所有输入
              for (final controller in _answerControllers.values) {
                controller.clear();
              }
              // 重置所有状态
              setState(() {
                _currentIndex = 0;
                _showAnswer = false;
                _showHints.clear();
              });
              // 跳转到第一题
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              Navigator.of(context).pop();
              CustomToast.show(
                context,
                message: '练习已重置',
                type: ToastType.success,
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
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

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
