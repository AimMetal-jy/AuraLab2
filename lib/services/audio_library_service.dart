import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// 音频文件信息
class AudioItem {
  final String id;
  final String title;
  final String artist;
  final String filePath;
  final AudioType type;
  final DateTime createdAt;
  final int? fileSize;
  final Duration? duration;

  AudioItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.filePath,
    required this.type,
    required this.createdAt,
    this.fileSize,
    this.duration,
  });

  bool get isLocal => type == AudioType.local;
  bool get isTTS => type == AudioType.tts;
}

/// 音频类型
enum AudioType {
  local, // 本地音频文件
  tts, // TTS生成的音频
}

/// 音频库服务
class AudioLibraryService extends ChangeNotifier {
  static final AudioLibraryService _instance = AudioLibraryService._internal();
  factory AudioLibraryService() => _instance;
  AudioLibraryService._internal() {
    _loadAudioLibrary();
  }

  final List<AudioItem> _audioItems = [];
  bool _isLoading = false;

  List<AudioItem> get audioItems => List.unmodifiable(_audioItems);
  List<AudioItem> get ttsAudioItems =>
      _audioItems.where((item) => item.isTTS).toList();
  List<AudioItem> get localAudioItems =>
      _audioItems.where((item) => item.isLocal).toList();
  bool get isLoading => _isLoading;
  int get totalCount => _audioItems.length;
  int get ttsCount => ttsAudioItems.length;

  /// 初始化加载音频库
  Future<void> _loadAudioLibrary() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 加载本地预置音频
      _loadLocalAudioItems();

      // 加载TTS生成的音频
      await _loadTTSAudioItems();
    } catch (e) {
      debugPrint('加载音频库失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载本地预置音频
  void _loadLocalAudioItems() {
    // 添加示例音频
    _audioItems.add(
      AudioItem(
        id: 'local_english_pod',
        title: 'English Pod Sample',
        artist: 'Test Audio',
        filePath: 'audio/English_Pod_30s.wav',
        type: AudioType.local,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 加载TTS生成的音频文件
  Future<void> _loadTTSAudioItems() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final ttsDir = Directory(path.join(directory.path, 'tts_audio'));

      if (!await ttsDir.exists()) {
        return;
      }

      // 清空现有的TTS音频项，避免重复
      _audioItems.removeWhere((item) => item.isTTS);

      final files = await ttsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.wav'))
          .cast<File>()
          .toList();

      for (final file in files) {
        final fileName = path.basename(file.path);
        final fileStats = await file.stat();

        // 从文件名解析信息
        // 格式: tts_timestamp_mode_vcn.wav
        final parts = fileName.replaceAll('.wav', '').split('_');
        String mode = 'unknown';
        String vcn = 'unknown';

        if (parts.length >= 4) {
          mode = parts[2];
          vcn = parts.sublist(3).join('_');
        }

        // 使用文件路径作为唯一标识符，确保不会重复
        final id = 'tts_${file.path}';

        // 检查是否已经存在相同ID的项目，避免重复
        if (_audioItems.any((item) => item.id == id)) {
          continue;
        }

        final audioItem = AudioItem(
          id: id,
          title: fileName, // 使用文件名作为标题
          artist:
              'TTS生成 - ${_getVoiceName(vcn)} (${_getModeName(mode)})', // 音色信息作为艺术家信息
          filePath: file.path,
          type: AudioType.tts,
          createdAt: fileStats.modified,
          fileSize: fileStats.size,
        );

        _audioItems.add(audioItem);
      }

      // 按创建时间排序，最新的在前
      _audioItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('加载TTS音频文件失败: $e');
    }
  }

  /// 添加TTS生成的音频到库中
  Future<void> addTTSAudio(String filePath, String mode, String vcn) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('音频文件不存在');
      }

      final fileName = path.basename(filePath);
      final fileStats = await file.stat();

      // 使用文件路径作为唯一标识符，确保ID一致性
      final id = 'tts_$filePath';

      // 检查是否已存在相同ID的文件，避免重复添加
      final existingIndex = _audioItems.indexWhere((item) => item.id == id);

      final audioItem = AudioItem(
        id: id,
        title: fileName, // 使用文件名作为标题
        artist: 'TTS生成 - ${_getVoiceName(vcn)} (${_getModeName(mode)})',
        filePath: filePath,
        type: AudioType.tts,
        createdAt: fileStats.modified,
        fileSize: fileStats.size,
      );

      if (existingIndex != -1) {
        // 如果已存在，更新而不是添加
        _audioItems[existingIndex] = audioItem;
      } else {
        // 不存在则添加新项到列表开头
        _audioItems.insert(0, audioItem);
      }

      // 重新排序，确保最新的在前面
      _audioItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      notifyListeners();
    } catch (e) {
      debugPrint('添加TTS音频失败: $e');
      rethrow;
    }
  }

  /// 从库中移除音频
  Future<void> removeAudio(String id) async {
    try {
      final index = _audioItems.indexWhere((item) => item.id == id);
      if (index == -1) return;

      final audioItem = _audioItems[index];

      // 如果是TTS文件，同时删除物理文件
      if (audioItem.isTTS) {
        final file = File(audioItem.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _audioItems.removeAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('移除音频失败: $e');
      rethrow;
    }
  }

  /// 刷新音频库
  Future<void> refresh() async {
    _audioItems.clear();
    await _loadAudioLibrary();
  }

  /// 搜索音频
  List<AudioItem> search(String query) {
    if (query.isEmpty) return audioItems;

    final lowerQuery = query.toLowerCase();
    return _audioItems.where((item) {
      return item.title.toLowerCase().contains(lowerQuery) ||
          item.artist.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// 根据类型获取音频
  List<AudioItem> getAudioByType(AudioType type) {
    return _audioItems.where((item) => item.type == type).toList();
  }

  /// 获取最近添加的音频
  List<AudioItem> getRecentAudio({int limit = 10}) {
    final sorted = List<AudioItem>.from(_audioItems)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  /// 获取模式的中文名称
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

  /// 获取音色的中文名称
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
}
