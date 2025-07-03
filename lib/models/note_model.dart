class Note {
  final int? id;
  final String title;
  final String content;
  final bool isMarkdown;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int categoryId;
  final List<String> tags;
  final List<String> images;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.isMarkdown = false,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryId,
    this.tags = const [],
    this.images = const [],
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    bool? isMarkdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? categoryId,
    List<String>? tags,
    List<String>? images,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      isMarkdown: isMarkdown ?? this.isMarkdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      images: images ?? this.images,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'isMarkdown': isMarkdown ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'categoryId': categoryId,
      'tags': tags.join(','),
      'images': images.join(','),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      isMarkdown: map['isMarkdown'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      categoryId: map['categoryId'],
      tags: map['tags'].toString().split(','),
      images: map['images'].toString().split(','),
    );
  }
}

class NoteCategory {
  final int? id;
  final String name;

  NoteCategory({this.id, required this.name});

  NoteCategory copyWith({
    int? id,
    String? name,
  }) {
    return NoteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory NoteCategory.fromMap(Map<String, dynamic> map) {
    return NoteCategory(
      id: map['id'],
      name: map['name'],
    );
  }
}