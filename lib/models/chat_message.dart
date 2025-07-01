class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ChatMessage{content: $content, isUser: $isUser, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          isUser == other.isUser &&
          timestamp == other.timestamp;

  @override
  int get hashCode => content.hashCode ^ isUser.hashCode ^ timestamp.hashCode;
}