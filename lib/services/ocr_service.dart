import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'bluelm_config_service.dart';

class OCRService {
  static const String _baseUrl = 'http://localhost:8888';

  // OCR模式常量
  static const int ocrModeOnly = 0; // 仅返回文字信息
  static const int ocrModePos = 1; // 提供文字信息和坐标信息
  static const int ocrModeAll = 2; // 混合模式

  /// 识别图片中的文字
  /// [imageBytes] 图片字节数据
  /// [mode] OCR模式，默认为0（仅返回文字）
  /// [appId] vivo AI AppID
  /// [appKey] vivo AI AppKey
  static Future<String> recognizeText(
    Uint8List imageBytes, {
    int mode = ocrModeOnly,
    String? appId,
    String? appKey,
  }) async {
    try {
      // 将图片转换为base64
      String base64Image = base64Encode(imageBytes);

      // 准备请求数据
      Map<String, dynamic> requestData = {'image': base64Image, 'mode': mode};

      // 获取AppID和AppKey，优先使用传入的参数，否则使用配置的值
      String? finalAppId = appId;
      String? finalAppKey = appKey;

      if (finalAppId == null || finalAppKey == null) {
        final config = await BlueLMConfigService.getConfig();
        finalAppId = finalAppId ?? config['app_id'];
        finalAppKey = finalAppKey ?? config['app_key'];
      }

      // 如果有AppID和AppKey，添加到请求中
      if (finalAppId != null && finalAppKey != null) {
        requestData['app_id'] = finalAppId;
        requestData['app_key'] = finalAppKey;
      }

      // 发送POST请求
      final response = await http.post(
        Uri.parse('$_baseUrl/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // 根据模式处理返回数据
          switch (mode) {
            case ocrModeOnly:
              return responseData['data'] as String;
            case ocrModePos:
              // 如果需要坐标信息，可以在这里处理
              List<dynamic> ocrData = responseData['data'];
              StringBuffer result = StringBuffer();
              for (var item in ocrData) {
                result.writeln(item['words']);
              }
              return result.toString().trim();
            case ocrModeAll:
              // 混合模式，返回文字部分
              Map<String, dynamic> allData = responseData['data'];
              return allData['word'] as String;
            default:
              return responseData['data'] as String;
          }
        } else {
          throw Exception('OCR识别失败: ${responseData['message']}');
        }
      } else {
        throw Exception('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR服务错误: $e');
    }
  }

  /// 获取OCR识别结果的详细信息（包含坐标）
  static Future<List<OCRResult>> recognizeTextWithPosition(
    Uint8List imageBytes, {
    String? appId,
    String? appKey,
  }) async {
    try {
      String base64Image = base64Encode(imageBytes);

      Map<String, dynamic> requestData = {
        'image': base64Image,
        'mode': ocrModePos,
      };

      // 获取AppID和AppKey，优先使用传入的参数，否则使用配置的值
      String? finalAppId = appId;
      String? finalAppKey = appKey;

      if (finalAppId == null || finalAppKey == null) {
        final config = await BlueLMConfigService.getConfig();
        finalAppId = finalAppId ?? config['app_id'];
        finalAppKey = finalAppKey ?? config['app_key'];
      }

      // 如果有AppID和AppKey，添加到请求中
      if (finalAppId != null && finalAppKey != null) {
        requestData['app_id'] = finalAppId;
        requestData['app_key'] = finalAppKey;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          List<dynamic> ocrData = responseData['data'];
          return ocrData.map((item) => OCRResult.fromJson(item)).toList();
        } else {
          throw Exception('OCR识别失败: ${responseData['message']}');
        }
      } else {
        throw Exception('网络请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('OCR服务错误: $e');
    }
  }
}

/// OCR识别结果模型
class OCRResult {
  final String words;
  final OCRLocation location;

  OCRResult({required this.words, required this.location});

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      words: json['words'] as String,
      location: OCRLocation.fromJson(json['location']),
    );
  }
}

/// OCR文字位置信息
class OCRLocation {
  final OCRPoint topLeft;
  final OCRPoint topRight;
  final OCRPoint downLeft;
  final OCRPoint downRight;

  OCRLocation({
    required this.topLeft,
    required this.topRight,
    required this.downLeft,
    required this.downRight,
  });

  factory OCRLocation.fromJson(Map<String, dynamic> json) {
    return OCRLocation(
      topLeft: OCRPoint.fromJson(json['top_left']),
      topRight: OCRPoint.fromJson(json['top_right']),
      downLeft: OCRPoint.fromJson(json['down_left']),
      downRight: OCRPoint.fromJson(json['down_right']),
    );
  }
}

/// OCR坐标点
class OCRPoint {
  final double x;
  final double y;

  OCRPoint({required this.x, required this.y});

  factory OCRPoint.fromJson(Map<String, dynamic> json) {
    return OCRPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}
