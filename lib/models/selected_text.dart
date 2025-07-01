class SelectedText {
  final int? id;
  final String text;
  final DateTime createdAt;

  SelectedText({
    this.id,
    required this.text,
    required this.createdAt,
  });

  // 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  // 从Map创建对象
  factory SelectedText.fromMap(Map<String, dynamic> map) {
    return SelectedText(
      id: map['id']?.toInt(),
      text: map['text'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  // 复制对象并修改某些字段
  SelectedText copyWith({
    int? id,
    String? text,
    DateTime? createdAt,
  }) {
    return SelectedText(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'SelectedText{id: $id, text: $text, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedText &&
        other.id == id &&
        other.text == text &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ text.hashCode ^ createdAt.hashCode;
  }
}