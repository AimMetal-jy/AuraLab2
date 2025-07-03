import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  static const String _baseUrl = 'http://localhost:8888';

  // 翻译结果模型
  static const Duration _timeout = Duration(seconds: 30);

  /// 获取支持的语言列表
  static Future<Map<String, String>> getSupportedLanguages() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/translate/languages'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Map<String, String>.from(data['languages']);
        } else {
          throw Exception('获取语言列表失败: ${data['message']}');
        }
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取语言列表错误: $e');
      // 返回默认语言列表
      return {
        'zh': '中文',
        'en': '英语',
        'ja': '日语',
        'ko': '韩语',
        'fr': '法语',
        'de': '德语',
        'es': '西班牙语',
        'it': '意大利语',
        'ru': '俄语',
        'ar': '阿拉伯语',
      };
    }
  }

  /// 翻译文本
  static Future<TranslationResult> translate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    try {
      final requestBody = {
        'from': fromLanguage,
        'to': toLanguage,
        'text': text,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/translate'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TranslationResult.fromJson(data);
      } else {
        throw Exception('HTTP请求失败: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('网络连接失败，请检查网络设置');
    } on HttpException {
      throw Exception('HTTP请求异常');
    } on FormatException {
      throw Exception('响应格式错误');
    } catch (e) {
      debugPrint('翻译请求错误: $e');
      throw Exception('翻译失败: $e');
    }
  }
}

/// 翻译结果模型
class TranslationResult {
  final bool success;
  final String? translation;
  final String message;
  final String? from;
  final String? to;
  final String? originalText;

  TranslationResult({
    required this.success,
    this.translation,
    required this.message,
    this.from,
    this.to,
    this.originalText,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      success: json['success'] ?? false,
      translation: json['translation'],
      message: json['message'] ?? '未知错误',
      from: json['from'],
      to: json['to'],
      originalText: json['original_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'translation': translation,
      'message': message,
      'from': from,
      'to': to,
      'original_text': originalText,
    };
  }
}

/// 翻译历史记录模型
class TranslationHistory {
  final String originalText;
  final String translatedText;
  final String fromLanguage;
  final String toLanguage;
  final DateTime timestamp;

  TranslationHistory({
    required this.originalText,
    required this.translatedText,
    required this.fromLanguage,
    required this.toLanguage,
    required this.timestamp,
  });

  factory TranslationHistory.fromJson(Map<String, dynamic> json) {
    return TranslationHistory(
      originalText: json['original_text'],
      translatedText: json['translated_text'],
      fromLanguage: json['from_language'],
      toLanguage: json['to_language'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_text': originalText,
      'translated_text': translatedText,
      'from_language': fromLanguage,
      'to_language': toLanguage,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
