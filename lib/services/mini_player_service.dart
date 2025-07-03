import 'package:flutter/foundation.dart';

/// Mini Player 状态管理服务
/// 用于控制 Mini Player 的显示和隐藏状态
class MiniPlayerService extends ChangeNotifier {
  static final MiniPlayerService _instance = MiniPlayerService._internal();
  factory MiniPlayerService() => _instance;
  MiniPlayerService._internal();

  bool _isVisible = true;
  bool _isMinimized = false;

  /// 是否可见
  bool get isVisible => _isVisible;

  /// 是否最小化
  bool get isMinimized => _isMinimized;

  /// 显示 Mini Player
  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
  }

  /// 隐藏 Mini Player
  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
  }

  /// 切换 Mini Player 显示状态
  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  /// 最小化 Mini Player
  void minimize() {
    if (!_isMinimized) {
      _isMinimized = true;
      notifyListeners();
    }
  }

  /// 恢复 Mini Player
  void restore() {
    if (_isMinimized) {
      _isMinimized = false;
      notifyListeners();
    }
  }

  /// 切换最小化状态
  void toggleMinimized() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }
}
