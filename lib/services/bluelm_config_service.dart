import 'package:shared_preferences/shared_preferences.dart';

class BlueLMConfigService {
  static const String _appIdKey = 'bluelm_app_id';
  static const String _appKeyKey = 'bluelm_app_key';
  static const String _hasConfigKey = 'has_bluelm_config';

  /// 保存蓝心大模型配置
  static Future<bool> saveConfig({
    required String appId,
    required String appKey,
  }) async {
    if (appId.trim().isEmpty || appKey.trim().isEmpty) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appIdKey, appId.trim());
      await prefs.setString(_appKeyKey, appKey.trim());
      await prefs.setBool(_hasConfigKey, true);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取AppID
  static Future<String?> getAppId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appIdKey);
    } catch (e) {
      return null;
    }
  }

  /// 获取AppKey
  static Future<String?> getAppKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appKeyKey);
    } catch (e) {
      return null;
    }
  }

  /// 获取完整配置
  static Future<Map<String, String?>> getConfig() async {
    try {
      final appId = await getAppId();
      final appKey = await getAppKey();
      return {'app_id': appId, 'app_key': appKey};
    } catch (e) {
      return {'app_id': null, 'app_key': null};
    }
  }

  /// 检查是否已设置配置
  static Future<bool> hasConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasConfigKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 删除配置
  static Future<bool> removeConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_appIdKey);
      await prefs.remove(_appKeyKey);
      await prefs.setBool(_hasConfigKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证AppID格式
  static bool isValidAppIdFormat(String appId) {
    // 只检查是否为空，不限制格式和长度
    return appId.trim().isNotEmpty;
  }

  /// 验证AppKey格式
  static bool isValidAppKeyFormat(String appKey) {
    // 只检查是否为空，不限制格式和长度
    return appKey.trim().isNotEmpty;
  }

  /// 隐藏AppKey显示（只显示前4位和后4位）
  static String maskAppKey(String appKey) {
    if (appKey.length <= 8) {
      return '*' * appKey.length;
    }

    final start = appKey.substring(0, 4);
    final end = appKey.substring(appKey.length - 4);
    final middle = '*' * (appKey.length - 8);

    return '$start$middle$end';
  }
}
