import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:auralab_0701/services/bluelm_config_service.dart';

/// AI翻译评估结果
class AITranslationEvaluationResult {
  final double score; // 综合评分 (0-100)
  final String level; // 评级：优秀/良好/及格/不及格
  final String feedback; // 总体反馈
  final List<String> improvements; // 改进建议
  final List<String> strengths; // 优点
  final SimilarityResult similarity; // 相似度结果
  final AIEvaluationDetail aiEvaluation; // AI详细评估

  AITranslationEvaluationResult({
    required this.score,
    required this.level,
    required this.feedback,
    required this.improvements,
    required this.strengths,
    required this.similarity,
    required this.aiEvaluation,
  });

  factory AITranslationEvaluationResult.fromJson(Map<String, dynamic> json) {
    return AITranslationEvaluationResult(
      score: json['data']['score']?.toDouble() ?? 0.0,
      level: json['data']['level'] ?? '未评级',
      feedback: json['data']['feedback'] ?? '',
      improvements: List<String>.from(json['data']['improvements'] ?? []),
      strengths: List<String>.from(json['data']['strengths'] ?? []),
      similarity: SimilarityResult.fromJson(json['similarity'] ?? {}),
      aiEvaluation: AIEvaluationDetail.fromJson(json['ai_evaluation'] ?? {}),
    );
  }
}

/// 相似度结果
class SimilarityResult {
  final double score; // 相似度分数 (0-1)
  final String method; // 使用的方法
  final String explanation; // 相似度解释

  SimilarityResult({
    required this.score,
    required this.method,
    required this.explanation,
  });

  factory SimilarityResult.fromJson(Map<String, dynamic> json) {
    return SimilarityResult(
      score: json['score']?.toDouble() ?? 0.0,
      method: json['method'] ?? 'Unknown',
      explanation: json['explanation'] ?? '',
    );
  }
}

/// AI详细评估
class AIEvaluationDetail {
  final String summary; // AI总结
  final double grammarScore; // 语法评分
  final double accuracyScore; // 准确性评分
  final double fluencyScore; // 流畅性评分
  final List<String> detailedAdvice; // 详细建议

  AIEvaluationDetail({
    required this.summary,
    required this.grammarScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.detailedAdvice,
  });

  factory AIEvaluationDetail.fromJson(Map<String, dynamic> json) {
    return AIEvaluationDetail(
      summary: json['summary'] ?? '',
      grammarScore: json['grammar_score']?.toDouble() ?? 0.0,
      accuracyScore: json['accuracy_score']?.toDouble() ?? 0.0,
      fluencyScore: json['fluency_score']?.toDouble() ?? 0.0,
      detailedAdvice: List<String>.from(json['detailed_advice'] ?? []),
    );
  }
}

/// AI翻译评估服务
class AITranslationEvaluationService {
  static const String baseUrl = 'http://localhost:8888';
  static const String evaluationEndpoint = '/translate/evaluate';

  /// 评估翻译质量
  /// [originalText] 原文
  /// [userTranslation] 用户翻译
  /// [standardAnswer] 标准答案
  /// [sourceLanguage] 源语言
  /// [targetLanguage] 目标语言
  /// [context] 上下文
  static Future<AITranslationEvaluationResult> evaluateTranslation({
    required String originalText,
    required String userTranslation,
    required String standardAnswer,
    String sourceLanguage = 'English',
    String targetLanguage = 'Chinese',
    String? context,
  }) async {
    try {
      // 获取蓝心大模型配置
      final blueLmConfig = await BlueLMConfigService.getConfig();

      final requestBody = {
        'original_text': originalText,
        'user_translation': userTranslation,
        'standard_answer': standardAnswer,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
        if (context != null && context.isNotEmpty) 'context': context,
        if (blueLmConfig['app_id'] != null) 'app_id': blueLmConfig['app_id'],
        if (blueLmConfig['app_key'] != null) 'app_key': blueLmConfig['app_key'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl$evaluationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return AITranslationEvaluationResult.fromJson(responseData);
        } else {
          throw Exception('AI评估失败: ${responseData['message']}');
        }
      } else {
        throw Exception('AI评估请求失败: ${response.statusCode}');
      }
    } catch (e) {
      // 强制使用AI机制，如果失败则抛出异常
      throw Exception('AI评估服务不可用，请检查网络连接和配置: $e');
    }
  }

  /// 检查AI评估服务是否可用
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/bluelm/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
