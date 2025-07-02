import 'package:flutter/material.dart';
import 'package:auralab_0701/screens/tts/tts_ai.dart';
import 'package:auralab_0701/screens/tts/tts_local.dart';

class TtsPage extends StatefulWidget {
  const TtsPage({super.key});

  @override
  State<TtsPage> createState() => _TtsPageState();
}

class _TtsPageState extends State<TtsPage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [TtsSenderWithAI(), TtsSenderLocal()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("文枢工坊 TTS"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Tab 切换器
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 0
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud,
                            color: _currentIndex == 0
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI生成',
                            style: TextStyle(
                              color: _currentIndex == 0
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentIndex == 1
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder,
                            color: _currentIndex == 1
                                ? Colors.white
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '本地上传',
                            style: TextStyle(
                              color: _currentIndex == 1
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 页面内容
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }
}

// 保留原有的TtsSender类以保持兼容性，但不再使用
class TtsSender extends StatefulWidget {
  const TtsSender({super.key});

  @override
  TtsSenderState createState() => TtsSenderState();
}

class TtsSenderState extends State<TtsSender> {
  int _currentIndex = 0;
  final List<Widget> _pages = [TtsSenderWithAI(), TtsSenderLocal()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("这是TTS Sender界面")),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "AI生成"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "本地上传"),
        ],
      ),
    );
  }
}
