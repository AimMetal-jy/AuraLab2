// To parse this JSON data, do
//
//     final chatModel = chatModelFromJson(jsonString);

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

part 'chat_model.g.dart';

ChatModel chatModelFromJson(String str) => ChatModel.fromJson(json.decode(str));

String chatModelToJson(ChatModel data) => json.encode(data.toJson());

@JsonSerializable()
class ChatModel {
    @JsonKey(name: "data")
    Data? data;
    @JsonKey(name: "message")
    String message;
    @JsonKey(name: "session_id")
    String? sessionId;
    @JsonKey(name: "success")
    bool? success;
    @JsonKey(name: "timestamp")
    DateTime? timestamp;
    @JsonKey(name: "history_messages")
    List<Message>? historyMessages;
    @JsonKey(name: "history_message")
    String? historyMessage;

    ChatModel({
        this.data,
        required this.message,
        this.sessionId,
        this.success,
        this.timestamp,
        this.historyMessages,
        this.historyMessage,
    });

    factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);

    Map<String, dynamic> toJson() => _$ChatModelToJson(this);
}

@JsonSerializable()
class Data {
    @JsonKey(name: "messages")
    List<Message> messages;
    @JsonKey(name: "reply")
    String reply;
    @JsonKey(name: "role")
    String role;

    Data({
        required this.messages,
        required this.reply,
        required this.role,
    });

    factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);

    Map<String, dynamic> toJson() => _$DataToJson(this);
}

@JsonSerializable()
class Message {
    @JsonKey(name: "role")
    String role;
    @JsonKey(name: "content")
    String content;

    Message({
        required this.role,
        required this.content,
    });

    factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);

    Map<String, dynamic> toJson() => _$MessageToJson(this);
}
