import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/chat_model.dart';

class AIChatService {
  static const String baseUrl = 'http://127.0.0.1:8888';
  late final Dio _dio;

  AIChatService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    // 添加请求和响应拦截器用于调试
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  /// 发送聊天消息到AI后端
  /// [message] 用户输入的消息
  /// [sessionId] 会话ID，用于维持对话上下文
  /// [historyMessages] 历史消息列表，用于上下文理解
  /// [imagePath] 图片路径，用于多模态输入
  Future<ChatModel> sendMessage({
    required String message,
    String? sessionId,
    List<Message>? historyMessages,
    String? imagePath,
  }) async {
    try {
      debugPrint('发送请求到: $baseUrl/bluelm/chat');

      if (imagePath != null && File(imagePath).existsSync()) {
        // 多模态请求，使用FormData
        final formData = FormData.fromMap({
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          if (historyMessages != null && historyMessages.isNotEmpty)
            'history_messages': historyMessages
                .map((msg) => msg.toJson())
                .toList()
                .toString(),
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: 'image.jpg',
          ),
        });

        debugPrint('发送多模态请求，包含图片: $imagePath');

        // 发送POST请求
        final response = await _dio.post(
          '/bluelm/chat/multimodal',
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );

        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('响应数据: ${response.data}');

        // 解析响应数据
        if (response.statusCode == 200) {
          return ChatModel.fromJson(response.data);
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: '请求失败，状态码: ${response.statusCode}',
          );
        }
      } else {
        // 普通文本请求
        final requestData = {
          'message': message,
          if (sessionId != null) 'session_id': sessionId,
          if (historyMessages != null && historyMessages.isNotEmpty)
            'history_messages': historyMessages
                .map((msg) => msg.toJson())
                .toList(),
        };

        debugPrint('请求数据: $requestData');

        // 发送POST请求
        final response = await _dio.post(
          '/bluelm/chat',
          data: requestData,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('响应数据: ${response.data}');

        // 解析响应数据
        if (response.statusCode == 200) {
          return ChatModel.fromJson(response.data);
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: '请求失败，状态码: ${response.statusCode}',
          );
        }
      }
    } on DioException catch (e) {
      debugPrint('网络请求异常: ${e.message}');
      debugPrint('错误类型: ${e.type}');
      if (e.response != null) {
        debugPrint('错误响应: ${e.response?.data}');
      }
      rethrow;
    } catch (e) {
      debugPrint('未知错误: $e');
      rethrow;
    }
  }

  /// 开始新的对话会话
  Future<ChatModel> startNewChat(String message, {String? imagePath}) async {
    return await sendMessage(message: message, imagePath: imagePath);
  }

  /// 继续现有对话
  Future<ChatModel> continueChat({
    required String message,
    required String sessionId,
    List<Message>? historyMessages,
    String? imagePath,
  }) async {
    return await sendMessage(
      message: message,
      sessionId: sessionId,
      historyMessages: historyMessages,
      imagePath: imagePath,
    );
  }

  /// 释放资源
  void dispose() {
    _dio.close();
  }
}

/// AI聊天会话管理器
class ChatSession {
  String? sessionId;
  final List<Message> messages = [];
  final AIChatService _chatService = AIChatService();

  /// 发送消息
  Future<ChatModel> sendMessage(String userMessage, {String? imagePath}) async {
    try {
      // 添加用户消息到本地历史
      final userMsg = Message(role: 'user', content: userMessage);
      messages.add(userMsg);

      ChatModel response;
      if (sessionId == null) {
        // 首次对话
        response = await _chatService.startNewChat(
          userMessage,
          imagePath: imagePath,
        );
      } else {
        // 继续对话
        response = await _chatService.continueChat(
          message: userMessage,
          sessionId: sessionId!,
          historyMessages: messages,
          imagePath: imagePath,
        );
      }

      // 更新会话ID
      if (response.sessionId != null) {
        sessionId = response.sessionId;
      }

      // 添加AI回复到本地历史
      if (response.data?.reply != null) {
        final aiMsg = Message(
          role: response.data?.role ?? 'assistant',
          content: response.data!.reply,
        );
        messages.add(aiMsg);
      }

      return response;
    } catch (e) {
      // 如果请求失败，移除刚添加的用户消息
      if (messages.isNotEmpty && messages.last.role == 'user') {
        messages.removeLast();
      }
      rethrow;
    }
  }

  /// 清空会话
  void clearSession() {
    sessionId = null;
    messages.clear();
  }

  /// 获取最后一条AI回复
  String? getLastAssistantReply() {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].role == 'assistant') {
        return messages[i].content;
      }
    }
    return null;
  }

  /// 释放资源
  void dispose() {
    _chatService.dispose();
  }
}
