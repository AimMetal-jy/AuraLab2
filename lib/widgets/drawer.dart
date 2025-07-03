import 'package:flutter/material.dart';
import '../screens/settings_page.dart';

class TabsDrawer extends StatelessWidget {
  const TabsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              image: DecorationImage(
                image: AssetImage('assets/images/AuraLab_icon.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: null,
          ),
          ListTile(
            title: const Text("系统设置"),
            leading: const CircleAvatar(child: Icon(Icons.settings)),
            onTap: () {
              Navigator.of(context).pop(); // 关闭抽屉
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text("关于应用"),
            leading: const CircleAvatar(child: Icon(Icons.info)),
            onTap: () {
              Navigator.of(context).pop(); // 关闭抽屉
              showAboutDialog(
                context: context,
                applicationName: 'AuraLab',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/images/AuraLab_icon.png',
                  width: 48,
                  height: 48,
                ),
                applicationLegalese:
                    '© 2025 AuraLab Team. All rights reserved.\n\n'
                    '本应用遵循 MIT 许可证。\n'
                    '使用本应用即表示您同意相关条款和条件。',
                children: [
                  const Text('多功能AI音频处理应用'),
                  const SizedBox(height: 16),
                  const Text('功能包括：'),
                  const Text('• 语音转录 (ASR)'),
                  const Text('• 文字转语音 (TTS)'),
                  const Text('• 音频播放器'),
                  const Text('• 多语言翻译'),
                  const Text('• 单词本管理'),
                  const SizedBox(height: 16),
                  const Text('特别感谢：'),
                  const Text('• Flutter 开发团队'),
                  const Text('• 开源社区贡献者'),
                  const Text('• HuggingFace 和 WhisperX 项目'),
                  const Text('• vivo AI 平台'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
