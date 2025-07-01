import 'package:auralab_0701/services/ai_chat.dart';
import 'package:flutter/material.dart';
import 'package:auralab_0701/models/chat_model.dart';
import 'package:auralab_0701/models/chat_message.dart';

class TtsSenderWithAI extends StatefulWidget {
  const TtsSenderWithAI({super.key});

  @override
  TtsSenderWithAIState createState() => TtsSenderWithAIState();
}

class TtsSenderWithAIState extends State<TtsSenderWithAI> {
  final TextEditingController textEditingController = TextEditingController();
  late AIChatService chatService;
  late ChatSession chatSession;
  bool isLoading = false;
  bool isFirst = true;
  String sessionId = "";
  
  // 消息列表存储对话历史
  final List<ChatMessage> messages = [];
  
  @override
  void initState() {
    super.initState();
    chatService = AIChatService();
    chatSession = ChatSession();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("从AI获取灵感"), automaticallyImplyLeading: false),
      body: Stack(
        children: [
          // ListView(
          //   padding: EdgeInsets.only(bottom: 50),
          //   children: [
          //     Container(
          //       alignment: Alignment.centerLeft,
          //       padding: EdgeInsets.all(16),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.start,
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Icon(Icons.cloud, size: 22, color: Colors.blue),
          //           SizedBox(width: 8),
          //           Container(
          //             constraints: BoxConstraints(
          //               maxWidth: MediaQuery.of(context).size.width * 0.7,
          //             ),
          //             padding: EdgeInsets.all(16),
          //             decoration: BoxDecoration(
          //               color: Colors.blue.withAlpha(100),
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             child: Text(
          //               "你好,我是蓝心大模型",
          //               style: TextStyle(fontSize: 18),
          //               softWrap: true,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //     Container(
          //       alignment: Alignment.centerRight,
          //       padding: EdgeInsets.only(right: 10),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.end,
          //         crossAxisAlignment: CrossAxisAlignment.start,
          //         children: [
          //           Container(
          //             constraints: BoxConstraints(
          //               maxWidth: MediaQuery.of(context).size.width * 0.7,
          //             ),
          //             padding: EdgeInsets.all(16),
          //             decoration: BoxDecoration(
          //               color: Colors.blue.withAlpha(100),
          //               borderRadius: BorderRadius.circular(10),
          //             ),
          //             child: Text(
          //               "这是用户的输入内容",
          //               textAlign: TextAlign.right,
          //               style: TextStyle(fontSize: 18),
          //               softWrap: true,
          //             ),
          //           ),
          //           SizedBox(width: 8),
          //           Icon(Icons.person, size: 22, color: Colors.blue),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
          ListView.builder(
            padding: EdgeInsets.only(bottom: 100),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final isUser = message.isUser;
              
              return Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUser) ...[  
                      Icon(Icons.smart_toy, size: 22, color: Colors.blue),
                      SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                           color: isUser 
                               ? Colors.blue.withValues(alpha: 0.1)
                               : Colors.grey.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(10),
                         ),
                        child: Text(
                          message.content,
                          style: TextStyle(fontSize: 16),
                          softWrap: true,
                        ),
                      ),
                    ),
                    if (isUser) ...[  
                      SizedBox(width: 8),
                      Icon(Icons.person, size: 22, color: Colors.green),
                    ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Card(
              shape: RoundedRectangleBorder(
                //borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        decoration: InputDecoration(
                          hintText: '请输入您的想法',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        if (textEditingController.text.isNotEmpty) {
                          final userMessage = textEditingController.text;
                          // 立即清空输入框
                          textEditingController.clear();
                          
                          setState(() {
                            isLoading = true;
                          });
                          
                          try {
                              // 添加用户消息到列表
                              setState(() {
                                messages.add(ChatMessage(
                                  content: userMessage,
                                  isUser: true,
                                  timestamp: DateTime.now(),
                                ));
                              });
                              
                              ChatModel response;
                              if (isFirst) {
                                 response = await chatService.startNewChat(userMessage);
                                 if (response.sessionId != null) {
                                   sessionId = response.sessionId!;
                                 }
                                 isFirst = false;
                              } else {
                                // 将本地消息历史转换为Message对象列表
                                List<Message> historyMessages = messages.map((chatMessage) => 
                                  Message(
                                    role: chatMessage.isUser ? 'user' : 'assistant',
                                    content: chatMessage.content,
                                  )
                                ).toList();
                                
                                response = await chatService.continueChat(
                                  message: userMessage,
                                  sessionId: sessionId,
                                  historyMessages: historyMessages,
                                );
                              }
                              
                              // 处理AI响应并添加到消息列表
                              if (response.data != null && 
                                  response.data!.messages.isNotEmpty) {
                                final aiReply = response.data!.messages.last.content;
                                setState(() {
                                  messages.add(ChatMessage(
                                    content: aiReply,
                                    isUser: false,
                                    timestamp: DateTime.now(),
                                  ));
                                });
                                debugPrint('AI回复: $aiReply');
                              }
                          } catch (e) {
                            debugPrint('发送消息失败: $e');
                            // 发送失败时移除刚添加的用户消息
                            if (messages.isNotEmpty && messages.last.isUser) {
                              setState(() {
                                messages.removeLast();
                              });
                            }
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                      icon: isLoading ? CircularProgressIndicator() : Icon(Icons.send),
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
