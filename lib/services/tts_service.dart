import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'audio_library_service.dart';

class TtsService {
  static const String baseUrl = 'http://127.0.0.1:8888';
  late final Dio _dio;
  final AudioLibraryService _audioLibrary = AudioLibraryService();

  TtsService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        responseType: ResponseType.bytes, // 设置为bytes以接收音频文件
      ),
    );

    // 添加拦截器用于调试
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false, // 不打印音频数据
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  /// 发送TTS请求并保存音频文件
  /// [text] 要转换的文本
  /// [mode] 模式: human, short, long
  /// [vcn] 音色
  /// 返回保存的文件路径
  Future<String> generateTTS({
    required String text,
    required String mode,
    required String vcn,
    bool addToLibrary = true,
  }) async {
    try {
      debugPrint(
        '发送TTS请求: mode=$mode, vcn=$vcn, text=${text.substring(0, text.length > 50 ? 50 : text.length)}...',
      );

      // 发送POST请求
      final response = await _dio.post(
        '/bluelm/tts',
        data: {'mode': mode, 'text': text, 'vcn': vcn},
        options: Options(
          headers: {'Content-Type': 'application/json', 'Accept': 'audio/wav'},
        ),
      );

      if (response.statusCode == 200) {
        // 获取应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        final ttsDir = Directory(path.join(directory.path, 'tts_audio'));

        // 确保目录存在
        if (!await ttsDir.exists()) {
          await ttsDir.create(recursive: true);
        }

        // 生成文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'tts_${timestamp}_${mode}_$vcn.wav';
        final filePath = path.join(ttsDir.path, fileName);

        // 保存音频文件
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        debugPrint('TTS音频已保存到: $filePath');

        // 添加到音频库
        if (addToLibrary) {
          try {
            await _audioLibrary.addTTSAudio(filePath, mode, vcn);
            debugPrint('音频已添加到音频库');
          } catch (e) {
            debugPrint('添加到音频库失败: $e');
          }
        }

        return filePath;
      } else {
        throw Exception('TTS请求失败，状态码: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TTS网络请求异常: ${e.message}');
      if (e.response != null) {
        debugPrint('错误响应: ${e.response?.data}');
      }
      throw Exception('TTS请求失败: ${e.message}');
    } catch (e) {
      debugPrint('TTS未知错误: $e');
      throw Exception('TTS处理失败: $e');
    }
  }

  /// 获取所有已生成的TTS音频文件
  Future<List<File>> getTTSFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final ttsDir = Directory(path.join(directory.path, 'tts_audio'));

      if (!await ttsDir.exists()) {
        return [];
      }

      final files = await ttsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.wav'))
          .cast<File>()
          .toList();

      // 按修改时间排序，最新的在前
      files.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

      return files;
    } catch (e) {
      debugPrint('获取TTS文件列表失败: $e');
      return [];
    }
  }

  /// 删除TTS音频文件
  Future<bool> deleteTTSFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除TTS文件失败: $e');
      return false;
    }
  }

  /// 清空所有TTS音频文件
  Future<void> clearAllTTSFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final ttsDir = Directory(path.join(directory.path, 'tts_audio'));

      if (await ttsDir.exists()) {
        await ttsDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('清空TTS文件失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}

/// TTS音色数据类
class TTSVoice {
  final String id;
  final String name;
  final String mode;

  TTSVoice({required this.id, required this.name, required this.mode});
}

/// TTS音色配置
class TTSVoices {
  // 短音频合成音色
  static final List<TTSVoice> shortVoices = [
    TTSVoice(id: 'vivoHelper', name: '奕雯', mode: 'short'),
    TTSVoice(id: 'yunye', name: '云野-温柔', mode: 'short'),
    TTSVoice(id: 'wanqing', name: '婉清-御姐', mode: 'short'),
    TTSVoice(id: 'xiaofu', name: '晓芙-少女', mode: 'short'),
    TTSVoice(id: 'yige_child', name: '小萌-女童', mode: 'short'),
    TTSVoice(id: 'yige', name: '依格', mode: 'short'),
    TTSVoice(id: 'yiyi', name: '依依', mode: 'short'),
    TTSVoice(id: 'xiaoming', name: '小茗', mode: 'short'),
  ];

  // 长音频合成音色
  static final List<TTSVoice> longVoices = [
    TTSVoice(id: 'x2_vivoHelper', name: '奕雯', mode: 'long'),
    TTSVoice(id: 'x2_yige', name: '依格-甜美', mode: 'long'),
    TTSVoice(id: 'x2_yige_news', name: '依格-稳重', mode: 'long'),
    TTSVoice(id: 'x2_yunye', name: '云野-温柔', mode: 'long'),
    TTSVoice(id: 'x2_yunye_news', name: '云野-稳重', mode: 'long'),
    TTSVoice(id: 'x2_M02', name: '怀斌-浑厚', mode: 'long'),
    TTSVoice(id: 'x2_M05', name: '兆坤-成熟', mode: 'long'),
    TTSVoice(id: 'x2_M10', name: '亚恒-磁性', mode: 'long'),
    TTSVoice(id: 'x2_F163', name: '晓云-稳重', mode: 'long'),
    TTSVoice(id: 'x2_F25', name: '倩倩-清甜', mode: 'long'),
    TTSVoice(id: 'x2_F22', name: '海蔚-大气', mode: 'long'),
    TTSVoice(id: 'x2_F82', name: '英文女声', mode: 'long'),
  ];

  // 大模型音色
  static final List<TTSVoice> humanVoices = [
    TTSVoice(id: 'F245_natural', name: '知性柔美', mode: 'human'),
    TTSVoice(id: 'M24', name: '俊朗男声', mode: 'human'),
    TTSVoice(id: 'M193', name: '理性男声', mode: 'human'),
    TTSVoice(id: 'GAME_GIR_YG', name: '游戏少女', mode: 'human'),
    TTSVoice(id: 'GAME_GIR_MB', name: '游戏萌宝', mode: 'human'),
    TTSVoice(id: 'GAME_GIR_YJ', name: '游戏御姐', mode: 'human'),
    TTSVoice(id: 'GAME_GIR_LTY', name: '电台主播', mode: 'human'),
    TTSVoice(id: 'YIGEXIAOV', name: '依格', mode: 'human'),
    TTSVoice(id: 'FY_CANTONESE', name: '粤语', mode: 'human'),
    TTSVoice(id: 'FY_SICHUANHUA', name: '四川话', mode: 'human'),
    TTSVoice(id: 'FY_MIAOYU', name: '苗语', mode: 'human'),
  ];

  /// 根据模式获取对应的音色列表
  static List<TTSVoice> getVoicesByMode(String mode) {
    switch (mode) {
      case 'short':
        return shortVoices;
      case 'long':
        return longVoices;
      case 'human':
        return humanVoices;
      default:
        return [];
    }
  }

  /// 获取所有音色
  static List<TTSVoice> getAllVoices() {
    return [...shortVoices, ...longVoices, ...humanVoices];
  }
}
