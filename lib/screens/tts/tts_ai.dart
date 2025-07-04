import 'package:auralab_0701/services/ai_chat.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:auralab_0701/models/chat_model.dart';
import 'package:auralab_0701/models/chat_message.dart';
import 'package:auralab_0701/services/tts_selection_service.dart';
import 'package:auralab_0701/services/chat_database_service.dart' as db;
import 'package:auralab_0701/screens/tts/tts_processing.dart';
import 'package:auralab_0701/widgets/custom_toast.dart';

class TtsSenderWithAI extends StatefulWidget {
  const TtsSenderWithAI({super.key});

  @override
  TtsSenderWithAIState createState() => TtsSenderWithAIState();
}

class TtsSenderWithAIState extends State<TtsSenderWithAI> {
  final TextEditingController textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AIChatService chatService;
  final TtsSelectionService _selectionService = TtsSelectionService();
  final db.ChatDatabaseService _chatDatabase = db.ChatDatabaseService.instance;
  final ImagePicker _picker = ImagePicker();

  bool isLoading = false;
  bool isFirst = true;
  String sessionId = "";
  String? currentSessionTitle;
  File? _selectedImage;

  // 消息列表存储对话历史
  final List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    chatService = AIChatService();
    _startNewSession();
  }

  // 开始新的对话会话
  Future<void> _startNewSession() async {
    try {
      sessionId = await _chatDatabase.createChatSession();
      setState(() {
        messages.clear();
        isFirst = true;
        currentSessionTitle = '新对话';
        _selectedImage = null;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: '创建新对话失败: $e',
          type: ToastType.error,
        );
      }
    }
  }

  // 加载历史对话
  Future<void> _loadSession(String loadSessionId) async {
    try {
      final loadedMessages = await _chatDatabase.getSessionMessages(
        loadSessionId,
      );
      setState(() {
        sessionId = loadSessionId;
        messages.clear();
        messages.addAll(loadedMessages);
        isFirst = false;
        _selectedImage = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '加载对话失败: $e', type: ToastType.error);
      }
    }
  }

  // 滚动到底部
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: '选择图片失败: $e', type: ToastType.error);
      }
    }
  }

  // 显示历史对话列表
  void _showChatHistory() async {
    final sessions = await _chatDatabase.getAllSessions();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '对话历史',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: sessions.isEmpty
                  ? const Center(child: Text('暂无对话历史'))
                  : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isCurrentSession = session.sessionId == sessionId;

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
                                final navigator = Navigator.of(context);
                                await _chatDatabase.deleteSession(
                                  session.sessionId,
                                );
                                if (mounted) {
                                  navigator.pop();
                                  _showChatHistory();
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
                            _loadSession(session.sessionId);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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
        title: const Text("AI创作助手"),
        automaticallyImplyLeading: false,
        actions: [
          // 新增对话按钮
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _startNewSession,
            tooltip: '新对话',
          ),
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showChatHistory,
            tooltip: '历史对话',
          ),
          // TTS处理区按钮
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TtsProcessingPage(),
                ),
              );
            },
            icon: Stack(
              children: [
                const Icon(Icons.music_note, size: 30),
                if (_selectionService.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_selectionService.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'TTS音频处理区',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 消息列表
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isUser = message.isUser;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Icon(
                            Icons.smart_toy,
                            size: 22,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 如果有图片，显示图片
                                if (message.imagePath != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(message.imagePath!),
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  message.content,
                                  style: const TextStyle(fontSize: 16),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isUser) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.person,
                            size: 22,
                            color: Colors.green,
                          ),
                        ],
                      ],
                    ),
                    // 为AI消息添加"添加到待选区"按钮
                    if (!isUser) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 30), // 与消息对齐
                        child: TextButton.icon(
                          onPressed: () async {
                            final currentContext = context;
                            await _selectionService.addText(message.content);
                            if (mounted && currentContext.mounted) {
                              CustomToast.show(
                                currentContext,
                                message: '已添加到待选区',
                                type: ToastType.success,
                              );
                              setState(() {}); // 更新UI以显示徽章数量
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16),
                          label: const Text(
                            '添加到待选区',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          // 输入区域
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Card(
              shape: const RoundedRectangleBorder(),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 显示选中的图片
                    if (_selectedImage != null) ...[
                      Container(
                        height: 100,
                        width: 100,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        // 图片选择按钮
                        IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          tooltip: '添加图片',
                        ),
                        Expanded(
                          child: TextField(
                            controller: textEditingController,
                            decoration: InputDecoration(
                              hintText: '请输入您的想法',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        IconButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (textEditingController.text.isNotEmpty ||
                                      _selectedImage != null) {
                                    final userMessage =
                                        textEditingController.text.isEmpty
                                        ? '请分析这张图片'
                                        : textEditingController.text;

                                    // 立即清空输入框
                                    textEditingController.clear();
                                    final imagePath = _selectedImage?.path;
                                    setState(() {
                                      _selectedImage = null;
                                    });

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // 创建用户消息
                                      final userChatMessage = ChatMessage(
                                        content: userMessage,
                                        isUser: true,
                                        timestamp: DateTime.now(),
                                        imagePath: imagePath,
                                      );

                                      // 添加用户消息到列表
                                      setState(() {
                                        messages.add(userChatMessage);
                                      });

                                      // 保存用户消息到数据库
                                      await _chatDatabase.saveMessage(
                                        userChatMessage,
                                        sessionId,
                                      );

                                      _scrollToBottom();

                                      ChatModel response;
                                      if (isFirst) {
                                        response = await chatService
                                            .startNewChat(
                                              userMessage,
                                              imagePath: imagePath,
                                            );
                                        if (response.sessionId != null) {
                                          sessionId = response.sessionId!;
                                        }
                                        isFirst = false;

                                        // 使用AI的第一句回复作为会话标题
                                        if (response.data != null &&
                                            response
                                                .data!
                                                .messages
                                                .isNotEmpty) {
                                          final firstReply = response
                                              .data!
                                              .messages
                                              .last
                                              .content;
                                          final title = firstReply.length > 20
                                              ? '${firstReply.substring(0, 20)}...'
                                              : firstReply;
                                          await _chatDatabase
                                              .updateSessionTitle(
                                                sessionId,
                                                title,
                                              );
                                        }
                                      } else {
                                        // 将本地消息历史转换为Message对象列表
                                        List<Message> historyMessages = messages
                                            .map(
                                              (chatMessage) => Message(
                                                role: chatMessage.isUser
                                                    ? 'user'
                                                    : 'assistant',
                                                content: chatMessage.content,
                                              ),
                                            )
                                            .toList();

                                        response = await chatService
                                            .continueChat(
                                              message: userMessage,
                                              sessionId: sessionId,
                                              historyMessages: historyMessages,
                                              imagePath: imagePath,
                                            );
                                      }

                                      // 处理AI响应并添加到消息列表
                                      if (response.data != null &&
                                          response.data!.messages.isNotEmpty) {
                                        final aiReply = response
                                            .data!
                                            .messages
                                            .last
                                            .content;

                                        final aiChatMessage = ChatMessage(
                                          content: aiReply,
                                          isUser: false,
                                          timestamp: DateTime.now(),
                                        );

                                        setState(() {
                                          messages.add(aiChatMessage);
                                        });

                                        // 保存AI回复到数据库
                                        await _chatDatabase.saveMessage(
                                          aiChatMessage,
                                          sessionId,
                                        );

                                        _scrollToBottom();
                                        debugPrint('AI回复: $aiReply');
                                      }
                                    } catch (e) {
                                      debugPrint('发送消息失败: $e');
                                      // 发送失败时移除刚添加的用户消息
                                      if (messages.isNotEmpty &&
                                          messages.last.isUser) {
                                        setState(() {
                                          messages.removeLast();
                                        });
                                      }

                                      if (mounted) {
                                        final currentErrorContext = context;
                                        if (currentErrorContext.mounted) {
                                          CustomToast.show(
                                            currentErrorContext,
                                            message:
                                                '处理失败: ${e.toString().replaceAll('Exception: ', '')}',
                                            type: ToastType.error,
                                          );
                                        }
                                      }
                                    } finally {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                          icon: isLoading
                              ? const CircularProgressIndicator()
                              : const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
