import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/audio_player_service.dart';

/// 播放器设置对话框
class PlayerSettingsDialog extends StatelessWidget {
  final bool isTranscriptionAudio;
  final bool autoScrollEnabled;
  final ValueChanged<bool>? onAutoScrollChanged;

  const PlayerSettingsDialog({
    super.key,
    required this.isTranscriptionAudio,
    this.autoScrollEnabled = true,
    this.onAutoScrollChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, child) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text('播放设置', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                height:
                    MediaQuery.of(context).size.height * 0.7, // 限制高度为屏幕高度的70%
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 转录音频专用设置
                      if (isTranscriptionAudio) ...[
                        SwitchListTile(
                          title: const Text(
                            '单词高亮',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            '高亮显示当前播放的单词',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          value: player.config.showWordHighlight,
                          onChanged: player.setWordHighlight,
                          activeColor: Colors.white,
                        ),
                        SwitchListTile(
                          title: const Text(
                            '说话人标签',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            '显示不同说话人的颜色标签',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          value: player.config.showSpeakerLabels,
                          onChanged: player.setSpeakerLabels,
                          activeColor: Colors.white,
                        ),
                        SwitchListTile(
                          title: const Text(
                            '歌词自动滚动',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            '跟随播放进度自动滚动到中央',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          value: autoScrollEnabled,
                          onChanged: (value) {
                            setDialogState(() {});
                            onAutoScrollChanged?.call(value);
                          },
                          activeColor: Colors.white,
                        ),

                        // 延迟歌词设置
                        SwitchListTile(
                          title: const Text(
                            '延迟歌词',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            '延迟显示歌词，锻炼听力能力',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          value: player.config.delayedLyricsEnabled,
                          onChanged: player.setDelayedLyricsEnabled,
                          activeColor: Colors.white,
                        ),

                        // 延迟时间设置
                        if (player.config.delayedLyricsEnabled) ...[
                          const SizedBox(height: 16),
                          _buildDelayedLyricsSettings(player, setDialogState),
                        ],

                        const Divider(color: Colors.white24),
                      ],

                      // 通用设置
                      SwitchListTile(
                        title: const Text(
                          '循环播放',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          isTranscriptionAudio ? '播放完毕后重新开始' : '重复播放当前音频',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        value: isTranscriptionAudio
                            ? player.config.loopEnabled
                            : player.isRepeat,
                        onChanged: (value) {
                          if (isTranscriptionAudio) {
                            player.setLoopEnabled(value);
                          } else {
                            player.toggleRepeat();
                          }
                        },
                        activeColor: Colors.white,
                      ),

                      // 普通音频专用设置
                      if (!isTranscriptionAudio) ...[
                        const Divider(color: Colors.white24),
                        SwitchListTile(
                          title: const Text(
                            '随机播放',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            '打乱播放顺序',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          value: player.isShuffle,
                          onChanged: (value) => player.toggleShuffle(),
                          activeColor: Colors.white,
                        ),

                        // 音量控制
                        const SizedBox(height: 16),
                        const Text(
                          '音量',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.volume_down,
                              color: Colors.white54,
                              size: 20,
                            ),
                            Expanded(
                              child: Slider(
                                value: player.volume,
                                onChanged: (value) {
                                  player.setVolume(value);
                                  setDialogState(() {});
                                },
                                activeColor: Colors.white,
                                inactiveColor: Colors.grey[700],
                              ),
                            ),
                            const Icon(
                              Icons.volume_up,
                              color: Colors.white54,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(player.volume * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // 播放速度（转录音频显示更详细的控制）
                      if (isTranscriptionAudio) ...[
                        const Divider(color: Colors.white24),
                        const Text(
                          '播放速度',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        _buildSpeedControl(player, setDialogState),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    '关闭',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedControl(AudioPlayerService player, StateSetter setState) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Column(
      children: [
        // 速度按钮网格
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: speeds.map((speed) {
            final isSelected = player.config.playbackSpeed == speed;
            return GestureDetector(
              onTap: () {
                player.setPlaybackSpeed(speed);
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 精确调节滑块
        Row(
          children: [
            const Text(
              '0.5x',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Expanded(
              child: Slider(
                value: player.config.playbackSpeed.clamp(0.5, 2.0),
                min: 0.5,
                max: 2.0,
                divisions: 30,
                onChanged: (value) {
                  final roundedValue = (value * 20).round() / 20;
                  player.setPlaybackSpeed(roundedValue);
                  setState(() {});
                },
                activeColor: Colors.white,
                inactiveColor: Colors.grey[700],
              ),
            ),
            const Text(
              '2.0x',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),

        Text(
          '当前: ${player.config.playbackSpeed}x',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDelayedLyricsSettings(
    AudioPlayerService player,
    StateSetter setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('延迟时间', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 16),

        // 延迟时间滑块
        Row(
          children: [
            const Text(
              '0s',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Expanded(
              child: Slider(
                value: player.config.delayedLyricsDelay,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                onChanged: (value) {
                  final roundedValue = (value * 10).round() / 10;
                  player.setDelayedLyricsDelay(roundedValue);
                  setState(() {});
                },
                activeColor: Colors.white,
                inactiveColor: Colors.grey[700],
              ),
            ),
            const Text(
              '10s',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 延迟时间输入框
        Row(
          children: [
            const Text(
              '精确设置: ',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: TextField(
                controller: TextEditingController(
                  text: player.config.delayedLyricsDelay.toStringAsFixed(1),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(8),
                ),
                onSubmitted: (value) {
                  final parsedValue = double.tryParse(value);
                  if (parsedValue != null &&
                      parsedValue >= 0.0 &&
                      parsedValue <= 10.0) {
                    final roundedValue = (parsedValue * 10).round() / 10;
                    player.setDelayedLyricsDelay(roundedValue);
                    setState(() {});
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '秒',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 延迟歌词说明
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.withValues(alpha: 0.8),
                size: 16,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '延迟歌词会在句子播放完毕后延迟指定时间显示，确保用户先听完整句话再看到文字',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
