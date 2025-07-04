import 'package:flutter/foundation.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayModeService {
  static const String _refreshRateKey = 'preferred_refresh_rate';

  static DisplayModeService? _instance;
  static DisplayModeService get instance =>
      _instance ??= DisplayModeService._();

  DisplayModeService._();

  List<DisplayMode> _supportedModes = [];
  DisplayMode? _currentMode;
  bool _isInitialized = false;

  /// 初始化显示模式服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 获取支持的显示模式
      _supportedModes = await FlutterDisplayMode.supported;
      _currentMode = await FlutterDisplayMode.active;

      debugPrint('支持的显示模式:');
      for (var mode in _supportedModes) {
        debugPrint('  ${mode.toString()}');
      }
      debugPrint('当前显示模式: ${_currentMode.toString()}');

      // 应用保存的设置
      await _applySavedSettings();

      _isInitialized = true;
    } catch (e) {
      debugPrint('初始化显示模式服务失败: $e');
    }
  }

  /// 获取支持的显示模式
  List<DisplayMode> get supportedModes => List.from(_supportedModes);

  /// 获取当前活动的显示模式
  Future<DisplayMode?> getCurrentMode() async {
    try {
      _currentMode = await FlutterDisplayMode.active;
      return _currentMode;
    } catch (e) {
      debugPrint('获取当前显示模式失败: $e');
      return null;
    }
  }

  /// 设置为最高刷新率
  Future<bool> setHighRefreshRate() async {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      await _saveRefreshRateSetting('high');
      _currentMode = await FlutterDisplayMode.active;
      debugPrint('已设置为高刷新率: ${_currentMode.toString()}');
      return true;
    } catch (e) {
      debugPrint('设置高刷新率失败: $e');
      return false;
    }
  }

  /// 设置为最低刷新率
  Future<bool> setLowRefreshRate() async {
    try {
      await FlutterDisplayMode.setLowRefreshRate();
      await _saveRefreshRateSetting('low');
      _currentMode = await FlutterDisplayMode.active;
      debugPrint('已设置为低刷新率: ${_currentMode.toString()}');
      return true;
    } catch (e) {
      debugPrint('设置低刷新率失败: $e');
      return false;
    }
  }

  /// 设置为自动模式
  Future<bool> setAutoMode() async {
    try {
      // 查找自动模式（通常是第一个模式，分辨率为0x0）
      final autoMode = _supportedModes.firstWhere(
        (mode) => mode.width == 0 && mode.height == 0,
        orElse: () => _supportedModes.first,
      );

      await FlutterDisplayMode.setPreferredMode(autoMode);
      await _saveRefreshRateSetting('auto');
      _currentMode = await FlutterDisplayMode.active;
      debugPrint('已设置为自动模式: ${_currentMode.toString()}');
      return true;
    } catch (e) {
      debugPrint('设置自动模式失败: $e');
      return false;
    }
  }

  /// 设置特定的显示模式
  Future<bool> setDisplayMode(DisplayMode mode) async {
    try {
      await FlutterDisplayMode.setPreferredMode(mode);
      await _saveRefreshRateSetting('custom_${mode.id}');
      _currentMode = await FlutterDisplayMode.active;
      debugPrint('已设置显示模式: ${_currentMode.toString()}');
      return true;
    } catch (e) {
      debugPrint('设置显示模式失败: $e');
      return false;
    }
  }

  /// 获取最高刷新率模式
  DisplayMode? getHighestRefreshRateMode() {
    if (_supportedModes.isEmpty) return null;

    DisplayMode? highest;
    double maxRefreshRate = 0;

    for (var mode in _supportedModes) {
      if (mode.refreshRate > maxRefreshRate &&
          mode.width > 0 &&
          mode.height > 0) {
        maxRefreshRate = mode.refreshRate;
        highest = mode;
      }
    }

    return highest;
  }

  /// 获取60Hz模式
  DisplayMode? get60HzMode() {
    if (_supportedModes.isEmpty) return null;

    // 查找60Hz模式，优先选择分辨率最高的
    final modes60Hz = _supportedModes
        .where(
          (mode) =>
              mode.refreshRate >= 59.0 &&
              mode.refreshRate <= 61.0 &&
              mode.width > 0 &&
              mode.height > 0,
        )
        .toList();

    if (modes60Hz.isEmpty) return null;

    // 按分辨率排序，选择最高分辨率的60Hz模式
    modes60Hz.sort(
      (a, b) => (b.width * b.height).compareTo(a.width * a.height),
    );
    return modes60Hz.first;
  }

  /// 检查是否支持高刷新率
  bool get supportsHighRefreshRate {
    final highest = getHighestRefreshRateMode();
    return highest != null && highest.refreshRate > 60;
  }

  /// 获取支持的刷新率列表
  List<double> getSupportedRefreshRates() {
    final rates = <double>{};
    for (var mode in _supportedModes) {
      if (mode.width > 0 && mode.height > 0) {
        rates.add(mode.refreshRate);
      }
    }
    final sortedRates = rates.toList()..sort();
    return sortedRates;
  }

  /// 保存刷新率设置
  Future<void> _saveRefreshRateSetting(String setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshRateKey, setting);
  }

  /// 应用保存的设置
  Future<void> _applySavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSetting = prefs.getString(_refreshRateKey);

    if (savedSetting == null) {
      // 首次使用，默认设置为高刷新率（如果支持）
      if (supportsHighRefreshRate) {
        await setHighRefreshRate();
      }
      return;
    }

    try {
      switch (savedSetting) {
        case 'high':
          await FlutterDisplayMode.setHighRefreshRate();
          break;
        case 'low':
          await FlutterDisplayMode.setLowRefreshRate();
          break;
        case 'auto':
          await setAutoMode();
          break;
        default:
          if (savedSetting.startsWith('custom_')) {
            final modeId = int.tryParse(savedSetting.substring(7));
            if (modeId != null) {
              final mode = _supportedModes.firstWhere(
                (m) => m.id == modeId,
                orElse: () => _supportedModes.first,
              );
              await FlutterDisplayMode.setPreferredMode(mode);
            }
          }
      }
    } catch (e) {
      debugPrint('应用保存的显示设置失败: $e');
    }
  }

  /// 获取当前设置的刷新率偏好
  Future<String> getCurrentSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshRateKey) ?? 'auto';
  }

  /// 为游戏或动画场景优化刷新率
  Future<void> optimizeForPerformance() async {
    if (supportsHighRefreshRate) {
      await setHighRefreshRate();
    }
  }

  /// 为省电优化刷新率
  Future<void> optimizeForBattery() async {
    final mode60Hz = get60HzMode();
    if (mode60Hz != null) {
      await setDisplayMode(mode60Hz);
    } else {
      await setLowRefreshRate();
    }
  }
}
