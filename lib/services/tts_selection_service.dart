import 'database_helper.dart';

class TtsSelectionService {
  static final TtsSelectionService _instance = TtsSelectionService._internal();
  factory TtsSelectionService() => _instance;
  TtsSelectionService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  // 缓存的文字列表，用于同步访问
  List<String> _cachedTexts = [];
  bool _isInitialized = false;

  // 初始化服务，加载数据库中的数据
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _cachedTexts = await _dbHelper.getAllTextStrings();
      _isInitialized = true;
    }
  }

  // 获取待选区文字列表
  Future<List<String>> get selectedTexts async {
    await _ensureInitialized();
    return List.unmodifiable(_cachedTexts);
  }

  // 同步获取缓存的文字列表（用于UI显示）
  List<String> get selectedTextsSync {
    return List.unmodifiable(_cachedTexts);
  }

  // 添加文字到待选区
  Future<void> addText(String text) async {
    if (text.trim().isEmpty) return;
    
    await _ensureInitialized();
    
    // 检查是否已存在
    if (!_cachedTexts.contains(text)) {
      final result = await _dbHelper.insertText(text);
      if (result > 0) {
        _cachedTexts.add(text);
      }
    }
  }

  // 从待选区移除文字
  Future<void> removeText(String text) async {
    await _ensureInitialized();
    
    final result = await _dbHelper.deleteTextByContent(text);
    if (result > 0) {
      _cachedTexts.remove(text);
    }
  }

  // 按索引移除文字
  Future<void> removeTextAt(int index) async {
    await _ensureInitialized();
    
    if (index >= 0 && index < _cachedTexts.length) {
      final result = await _dbHelper.deleteTextByIndex(index);
      if (result > 0) {
        _cachedTexts.removeAt(index);
      }
    }
  }

  // 按索引更新文字
  Future<void> updateTextAt(int index, String newText) async {
    await _ensureInitialized();
    
    if (index >= 0 && index < _cachedTexts.length && newText.trim().isNotEmpty) {
      final result = await _dbHelper.updateTextByIndex(index, newText);
      if (result > 0) {
        _cachedTexts[index] = newText;
      }
    }
  }

  // 清空待选区
  Future<void> clearAll() async {
    await _ensureInitialized();
    
    final result = await _dbHelper.clearAllTexts();
    if (result > 0) {
      _cachedTexts.clear();
    }
  }

  // 获取待选区文字数量
  int get count => _cachedTexts.length;

  // 检查是否为空
  bool get isEmpty => _cachedTexts.isEmpty;

  // 检查是否非空
  bool get isNotEmpty => _cachedTexts.isNotEmpty;

  // 刷新缓存（从数据库重新加载）
  Future<void> refresh() async {
    _cachedTexts = await _dbHelper.getAllTextStrings();
    _isInitialized = true;
  }
}