import 'package:flutter/material.dart';
import 'package:auralab_0701/services/chat_database_service.dart';

class ChatHistoryPage extends StatefulWidget {
  final String currentSessionId;
  final Function(String) onSelectSession;

  const ChatHistoryPage({
    super.key,
    required this.currentSessionId,
    required this.onSelectSession,
  });

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final ChatDatabaseService _chatDatabase = ChatDatabaseService.instance;
  List<ChatSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _chatDatabase.getAllSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.month}-${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对话历史'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? const Center(child: Text('暂无对话历史'))
          : ListView.builder(
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final isCurrentSession =
                    session.sessionId == widget.currentSessionId;

                return ListTile(
                  leading: Icon(
                    Icons.chat_bubble_outline,
                    color: isCurrentSession ? Colors.blue : Colors.grey,
                  ),
                  title: Text(
                    session.title,
                    style: TextStyle(
                      fontWeight: isCurrentSession
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCurrentSession ? Colors.blue : null,
                    ),
                  ),
                  subtitle: Text(
                    '更新于 ${_formatDate(session.updatedAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        // 显示确认对话框
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('确认删除'),
                            content: Text('确定要删除对话"${session.title}"吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _chatDatabase.deleteSession(session.sessionId);
                          _loadSessions();

                          // 如果删除的是当前会话，通知父页面创建新会话
                          if (isCurrentSession) {
                            widget.onSelectSession('');
                          }
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onSelectSession(session.sessionId);
                  },
                );
              },
            ),
    );
  }
}
