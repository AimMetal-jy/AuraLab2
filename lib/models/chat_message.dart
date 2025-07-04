class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });

  @override
  String toString() {
    return 'ChatMessage{content: $content, isUser: $isUser, timestamp: $timestamp, imagePath: $imagePath}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          isUser == other.isUser &&
          timestamp == other.timestamp &&
          imagePath == other.imagePath;

  @override
  int get hashCode =>
      content.hashCode ^
      isUser.hashCode ^
      timestamp.hashCode ^
      imagePath.hashCode;
}
