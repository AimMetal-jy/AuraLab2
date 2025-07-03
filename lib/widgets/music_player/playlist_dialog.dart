import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';
import '../../services/audio_library_service.dart';

/// 播放列表对话框
class PlaylistDialog extends StatelessWidget {
  const PlaylistDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [Icon(Icons.queue_music), SizedBox(width: 8), Text('当前播放列表')],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Consumer<AudioLibraryService>(
          builder: (context, audioLibraryService, child) {
            final audioItems = audioLibraryService.audioItems;

            if (audioItems.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '播放列表为空',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '请先在主页添加音频文件',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: audioItems.length,
              itemBuilder: (context, index) {
                final audioItem = audioItems[index];
                return Consumer<AudioPlayerService>(
                  builder: (context, audioService, child) {
                    final isCurrentlyPlaying =
                        audioService.currentSong == audioItem.title;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.2)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          audioItem.isTTS
                              ? Icons.record_voice_over
                              : Icons.music_note,
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        audioItem.title,
                        style: TextStyle(
                          fontWeight: isCurrentlyPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrentlyPlaying
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        audioItem.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isCurrentlyPlaying
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.7)
                              : Colors.grey[600],
                        ),
                      ),
                      trailing: isCurrentlyPlaying
                          ? Icon(
                              audioService.isPlaying
                                  ? Icons.volume_up
                                  : Icons.pause,
                              color: Theme.of(context).primaryColor,
                            )
                          : const Icon(Icons.play_arrow, color: Colors.grey),
                      onTap: () {
                        // 播放选中的音频
                        audioService.playFromFile(
                          audioItem.filePath,
                          songTitle: audioItem.title,
                          artist: audioItem.artist,
                        );
                        Navigator.of(context).pop(); // 关闭对话框
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
