import 'package:flutter/material.dart';
import '../widgets/music_player/music_player.dart';

/// 普通音频播放器页面
/// 这是一个包装器，内部使用UnifiedPlayerPage
class MusicPlayerPage extends StatelessWidget {
  final dynamic audioData;

  const MusicPlayerPage({super.key, this.audioData});

  @override
  Widget build(BuildContext context) {
    // 如果没有提供audioData，可以从路由参数中获取
    final routeAudioData =
        audioData ?? ModalRoute.of(context)?.settings.arguments;

    // 处理新的数据格式
    if (routeAudioData is Map<String, dynamic>) {
      if (routeAudioData.containsKey('audioData')) {
        // ASR音频：包含完整的转录数据
        return UnifiedPlayerPage(
          audioData: routeAudioData['audioData'],
          isTranscriptionAudio: routeAudioData['isTranscriptionAudio'] ?? false,
        );
      } else {
        // 普通音频：包含文件路径和元数据
        return UnifiedPlayerPage(
          audioData: routeAudioData,
          isTranscriptionAudio: false,
        );
      }
    }

    return UnifiedPlayerPage(
      audioData: routeAudioData ?? 'assets/audio/English_Pod_30s.wav',
      isTranscriptionAudio: false,
    );
  }
}
