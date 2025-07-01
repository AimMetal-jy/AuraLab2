// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  data: json['data'] == null
      ? null
      : Data.fromJson(json['data'] as Map<String, dynamic>),
  message: json['message'] as String,
  sessionId: json['session_id'] as String?,
  success: json['success'] as bool?,
  timestamp: json['timestamp'] == null
      ? null
      : DateTime.parse(json['timestamp'] as String),
  historyMessages: (json['history_messages'] as List<dynamic>?)
      ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'data': instance.data,
  'message': instance.message,
  'session_id': instance.sessionId,
  'success': instance.success,
  'timestamp': instance.timestamp?.toIso8601String(),
  'history_messages': instance.historyMessages,
};

Data _$DataFromJson(Map<String, dynamic> json) => Data(
  messages: (json['messages'] as List<dynamic>)
      .map((e) => Message.fromJson(e as Map<String, dynamic>))
      .toList(),
  reply: json['reply'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  'messages': instance.messages,
  'reply': instance.reply,
  'role': instance.role,
};

Message _$MessageFromJson(Map<String, dynamic> json) =>
    Message(role: json['role'] as String, content: json['content'] as String);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'role': instance.role,
  'content': instance.content,
};
