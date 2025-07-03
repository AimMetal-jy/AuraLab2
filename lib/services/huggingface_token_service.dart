import 'package:shared_preferences/shared_preferences.dart';

class HuggingFaceTokenService {
  static const String _tokenKey = 'huggingface_token';
  static const String _hasTokenKey = 'has_huggingface_token';

  /// 保存HuggingFace Token
  static Future<bool> saveToken(String token) async {
    if (token.trim().isEmpty) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token.trim());
      await prefs.setBool(_hasTokenKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取HuggingFace Token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// 检查是否已设置Token
  static Future<bool> hasToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasTokenKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 删除Token
  static Future<bool> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.setBool(_hasTokenKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证Token格式（基本格式检查）
  static bool isValidTokenFormat(String token) {
    if (token.trim().isEmpty) return false;

    // HuggingFace token 通常以 hf_ 开头，长度约为37个字符
    final trimmedToken = token.trim();
    if (trimmedToken.startsWith('hf_') && trimmedToken.length >= 32) {
      return true;
    }

    // 也可能是其他格式的有效token
    return trimmedToken.length >= 20;
  }

  /// 隐藏Token显示（只显示前4位和后4位）
  static String maskToken(String token) {
    if (token.length <= 8) {
      return '*' * token.length;
    }

    final start = token.substring(0, 4);
    final end = token.substring(token.length - 4);
    final middle = '*' * (token.length - 8);

    return '$start$middle$end';
  }
}
