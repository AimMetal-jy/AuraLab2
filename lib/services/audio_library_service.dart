import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import './database_helper.dart';

/// 音频文件信息 - 数据模型
class AudioItem {
  final int? id; // 数据库自增ID
  final String title;
  final String artist;
  final String filePath;
  final AudioType type;
  final DateTime createdAt;
  final int? fileSize;
  final Duration? duration;

  // 新增字段
  final int playCount;
  final bool isFavorite;
  final DateTime? lastPlayed;
  final String? transcriptionResult; // ASR转录结果

  AudioItem({
    this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.type,
    required this.createdAt,
    this.fileSize,
    this.duration,
    this.playCount = 0,
    this.isFavorite = false,
    this.lastPlayed,
    this.transcriptionResult,
  });

  bool get isLocal => type == AudioType.local;
  bool get isTTS => type == AudioType.tts;
  bool get isASR => type == AudioType.asr;

  // 用于创建副本并更新值
  AudioItem copyWith({
    int? id,
    String? title,
    String? artist,
    String? filePath,
    AudioType? type,
    DateTime? createdAt,
    int? fileSize,
    Duration? duration,
    int? playCount,
    bool? isFavorite,
    DateTime? lastPlayed,
    String? transcriptionResult,
  }) {
    return AudioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      transcriptionResult: transcriptionResult ?? this.transcriptionResult,
    );
  }

  // 从 Map 转换为 AudioItem 对象
  factory AudioItem.fromMap(Map<String, dynamic> map) {
    return AudioItem(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      filePath: map['filePath'],
      type: AudioType.values.byName(map['type']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      fileSize: map['fileSize'],
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      playCount: map['playCount'] ?? 0,
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      lastPlayed: map['lastPlayed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastPlayed'])
          : null,
      transcriptionResult: map['transcriptionResult'],
    );
  }

  // 转换为 Map 以便存入数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'filePath': filePath,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'duration': duration?.inMilliseconds,
      'playCount': playCount,
      'isFavorite': isFavorite ? 1 : 0,
      'lastPlayed': lastPlayed?.millisecondsSinceEpoch,
      'transcriptionResult': transcriptionResult,
    };
  }
}

/// 音频类型
enum AudioType {
  local, // 本地音频文件
  tts, // TTS生成的音频
  asr, // ASR转录音频
}

/// 音频库服务 (由数据库驱动)
class AudioLibraryService extends ChangeNotifier {
  static final AudioLibraryService _instance = AudioLibraryService._internal();
  factory AudioLibraryService() => _instance;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final List<AudioItem> _audioItems = [];
  bool _isLoading = false;

  AudioLibraryService._internal() {
    refreshLibrary();
  }

  List<AudioItem> get audioItems => List.unmodifiable(_audioItems);
  List<AudioItem> get ttsAudioItems =>
      _audioItems.where((item) => item.isTTS).toList();
  List<AudioItem> get localAudioItems =>
      _audioItems.where((item) => item.isLocal).toList();
  List<AudioItem> get asrAudioItems =>
      _audioItems.where((item) => item.isASR).toList();
  bool get isLoading => _isLoading;
  int get totalCount => _audioItems.length;
  int get ttsCount => ttsAudioItems.length;
  int get asrCount => asrAudioItems.length;

  /// 从数据库和文件系统刷新整个音频库
  Future<void> refreshLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. 从数据库加载所有项目
      final dbItems = await _dbHelper.getAllAudioItems();
      _audioItems.clear();
      _audioItems.addAll(dbItems);

      // 2. 同步文件系统
      await _syncWithFileSystem();
    } catch (e) {
      debugPrint('刷新音频库失败: $e');
    } finally {
      _isLoading = false;
      _sortItems();
      notifyListeners();
    }
  }

  /// 智能同步数据库与文件系统
  Future<void> _syncWithFileSystem() async {
    // 检查TTS目录下的新文件
    await _syncTtsDirectory();

    // 检查数据库中记录的文件是否存在
    final List<AudioItem> itemsToRemove = [];
    for (final item in _audioItems) {
      final file = File(item.filePath);
      if (!await file.exists()) {
        itemsToRemove.add(item);
      }
    }

    // 从数据库和内存中移除不存在的文件记录
    if (itemsToRemove.isNotEmpty) {
      for (final item in itemsToRemove) {
        await _dbHelper.deleteAudioItemByPath(item.filePath);
        _audioItems.removeWhere((i) => i.id == item.id);
      }
    }
  }

  /// 同步TTS目录
  Future<void> _syncTtsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final ttsDir = Directory(path.join(directory.path, 'tts_audio'));

      if (!await ttsDir.exists()) return;

      final files = await ttsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.wav'))
          .cast<File>()
          .toList();

      for (final file in files) {
        // 如果文件已在数据库中，则跳过
        if (_audioItems.any((item) => item.filePath == file.path)) {
          continue;
        }

        // 发现新文件，创建并存入数据库
        final newItem = await _createTtsAudioItem(file);
        final dbItem = await _dbHelper.upsertAudioItem(newItem);
        _audioItems.add(dbItem);
      }
    } catch (e) {
      debugPrint('同步TTS目录失败: $e');
    }
  }

  /// 批量添加本地音频文件到数据库
  Future<int> addLocalAudioBatch(List<String> filePaths) async {
    int count = 0;
    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        if (!await file.exists()) continue;

        // 检查数据库中是否已存在
        if (await _dbHelper.getAudioItemByPath(filePath) != null) continue;

        final newItem = await _createLocalAudioItem(file);
        final dbItem = await _dbHelper.upsertAudioItem(newItem);
        _audioItems.add(dbItem);
        count++;
      } catch (e) {
        debugPrint('添加文件 $filePath 失败: $e');
      }
    }
    if (count > 0) {
      _sortItems();
      notifyListeners();
    }
    return count;
  }

  /// 删除一个音频项（从数据库和文件系统）
  Future<void> deleteAudioItem(AudioItem item) async {
    try {
      await _dbHelper.deleteAudioItemByPath(item.filePath);
      _audioItems.removeWhere((i) => i.id == item.id);

      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('删除音频项失败: $e');
      rethrow;
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(int itemId) async {
    final index = _audioItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final item = _audioItems[index];
    final updatedItem = item.copyWith(isFavorite: !item.isFavorite);

    _audioItems[index] = updatedItem;
    await _dbHelper.updateAudioItem(updatedItem);
    notifyListeners();
  }

  /// 增加播放次数并更新最后播放时间
  Future<void> incrementPlayCount(int itemId) async {
    final index = _audioItems.indexWhere((item) => item.id == itemId);
    if (index == -1) return;

    final item = _audioItems[index];
    final updatedItem = item.copyWith(
      playCount: item.playCount + 1,
      lastPlayed: DateTime.now(),
    );

    _audioItems[index] = updatedItem;
    await _dbHelper.updateAudioItem(updatedItem);
    // 不需要通知监听器，因为这通常是后台操作，不会立即影响UI
  }

  /// 搜索音频文件
  List<AudioItem> search(String query) {
    if (query.isEmpty) return _audioItems;

    final lowerQuery = query.toLowerCase();
    return _audioItems.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.artist.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 删除音频（通过ID）
  Future<void> removeAudio(int? itemId) async {
    if (itemId == null) return;

    final item = _audioItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw Exception('音频项未找到'),
    );

    await deleteAudioItem(item);
  }

  /// 添加单个本地音频文件
  Future<void> addLocalAudio(String filePath) async {
    await addLocalAudioBatch([filePath]);
  }

  /// 添加TTS音频文件
  Future<void> addTTSAudio(String filePath, String mode, String vcn) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      // 检查数据库中是否已存在
      if (await _dbHelper.getAudioItemByPath(filePath) != null) {
        debugPrint('TTS文件已存在，跳过添加: $filePath');
        return;
      }

      final newItem = await _createTtsAudioItem(file);
      final dbItem = await _dbHelper.upsertAudioItem(newItem);
      _audioItems.add(dbItem);

      _sortItems();
      notifyListeners();
      debugPrint('TTS音频已添加到库: ${newItem.title}');
    } catch (e) {
      debugPrint('添加TTS音频失败: $e');
      rethrow;
    }
  }

  /// 添加ASR音频文件
  Future<void> addASRAudio(
    String filePath,
    String transcriptionResult, {
    String? modelName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在: $filePath');
      }

      // 检查数据库中是否已存在
      if (await _dbHelper.getAudioItemByPath(filePath) != null) {
        debugPrint('ASR文件已存在，跳过添加: $filePath');
        return;
      }

      final newItem = await _createAsrAudioItem(
        file,
        transcriptionResult,
        modelName,
      );
      final dbItem = await _dbHelper.upsertAudioItem(newItem);
      _audioItems.add(dbItem);

      _sortItems();
      notifyListeners();
      debugPrint('ASR音频已添加到库: ${newItem.title}');
    } catch (e) {
      debugPrint('添加ASR音频失败: $e');
      rethrow;
    }
  }

  // --- 私有辅助方法 ---

  void _sortItems() {
    _audioItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<AudioItem> _createTtsAudioItem(File file) async {
    final fileName = path.basename(file.path);
    final fileStats = await file.stat();
    final parts = fileName.replaceAll('.wav', '').split('_');
    String mode = 'unknown', vcn = 'unknown';
    if (parts.length >= 4) {
      mode = parts[2];
      vcn = parts.sublist(3).join('_');
    }
    return AudioItem(
      title: fileName,
      artist: 'TTS生成 - ${_getVoiceName(vcn)} (${_getModeName(mode)})',
      filePath: file.path,
      type: AudioType.tts,
      createdAt: fileStats.modified,
      fileSize: fileStats.size,
    );
  }

  Future<AudioItem> _createLocalAudioItem(File file) async {
    final fileName = path.basename(file.path);
    final fileStats = await file.stat();
    final titleWithoutExt = path.basenameWithoutExtension(fileName);
    return AudioItem(
      title: titleWithoutExt,
      artist: '本地音频',
      filePath: file.path,
      type: AudioType.local,
      createdAt: fileStats.modified,
      fileSize: fileStats.size,
    );
  }

  Future<AudioItem> _createAsrAudioItem(
    File file,
    String transcriptionResult,
    String? modelName,
  ) async {
    final fileName = path.basename(file.path);
    final fileStats = await file.stat();
    final titleWithoutExt = path.basenameWithoutExtension(fileName);
    String artist = 'ASR转录';
    if (modelName != null) {
      artist = 'ASR转录 - $modelName';
    }
    return AudioItem(
      title: titleWithoutExt,
      artist: artist,
      filePath: file.path,
      type: AudioType.asr,
      createdAt: fileStats.modified,
      fileSize: fileStats.size,
      transcriptionResult: transcriptionResult,
    );
  }

  String _getVoiceName(String vcn) {
    // 这里可以从TTSVoices配置中获取完整的中文名称
    // 暂时直接返回vcn
    final voiceMap = {
      'F245_natural': '知性柔美',
      'M24': '俊朗男声',
      'M193': '理性男声',
      'GAME_GIR_YG': '游戏少女',
      'GAME_GIR_MB': '游戏萌宝',
      'GAME_GIR_YJ': '游戏御姐',
      'GAME_GIR_LTY': '电台主播',
      'YIGEXIAOV': '依格',
      'FY_CANTONESE': '粤语',
      'FY_SICHUANHUA': '四川话',
      'FY_MIAOYU': '苗语',
      'vivoHelper': '奕雯',
      'yunye': '云野-温柔',
      'wanqing': '婉清-御姐',
      'xiaofu': '晓芙-少女',
      'yige_child': '小萌-女童',
      'yige': '依格',
      'yiyi': '依依',
      'xiaoming': '小茗',
      'x2_vivoHelper': '奕雯',
      'x2_yige': '依格-甜美',
      'x2_yige_news': '依格-稳重',
      'x2_yunye': '云野-温柔',
      'x2_yunye_news': '云野-稳重',
      'x2_M02': '怀斌-浑厚',
      'x2_M05': '兆坤-成熟',
      'x2_M10': '亚恒-磁性',
      'x2_F163': '晓云-稳重',
      'x2_F25': '倩倩-清甜',
      'x2_F22': '海蔚-大气',
      'x2_F82': '英文女声',
    };

    return voiceMap[vcn] ?? vcn;
  }

  String _getModeName(String mode) {
    switch (mode) {
      case 'human':
        return '大模型';
      case 'short':
        return '短音频';
      case 'long':
        return '长音频';
      default:
        return mode;
    }
  }
}
