import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/chat_message.dart';

class ChatDatabaseService {
  static final ChatDatabaseService instance = ChatDatabaseService._init();
  static Database? _database;

  ChatDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建对话会话表
    await db.execute('''
      CREATE TABLE chat_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL UNIQUE,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建消息表
    await db.execute('''
      CREATE TABLE chat_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        image_path TEXT,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (session_id)
      )
    ''');
  }

  // 创建新的对话会话
  Future<String> createChatSession({String? title}) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('chat_sessions', {
      'session_id': sessionId,
      'title': title ?? '新对话 ${now.substring(0, 10)}',
      'created_at': now,
      'updated_at': now,
    });

    return sessionId;
  }

  // 更新会话标题
  Future<void> updateSessionTitle(String sessionId, String title) async {
    final db = await instance.database;
    await db.update(
      'chat_sessions',
      {'title': title, 'updated_at': DateTime.now().toIso8601String()},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // 保存消息
  Future<void> saveMessage(ChatMessage message, String sessionId) async {
    final db = await instance.database;

    await db.insert('chat_messages', {
      'session_id': sessionId,
      'content': message.content,
      'is_user': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
      'image_path': message.imagePath,
    });

    // 更新会话的最后更新时间
    await db.update(
      'chat_sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // 批量保存消息
  Future<void> saveMessages(
    List<ChatMessage> messages,
    String sessionId,
  ) async {
    final db = await instance.database;
    final batch = db.batch();

    for (final message in messages) {
      batch.insert('chat_messages', {
        'session_id': sessionId,
        'content': message.content,
        'is_user': message.isUser ? 1 : 0,
        'timestamp': message.timestamp.toIso8601String(),
        'image_path': message.imagePath,
      });
    }

    await batch.commit();

    // 更新会话的最后更新时间
    await db.update(
      'chat_sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // 获取会话的所有消息
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    final db = await instance.database;
    final maps = await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage(
        content: maps[i]['content'] as String,
        isUser: maps[i]['is_user'] == 1,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        imagePath: maps[i]['image_path'] as String?,
      );
    });
  }

  // 获取所有会话列表
  Future<List<ChatSession>> getAllSessions() async {
    final db = await instance.database;
    final maps = await db.query('chat_sessions', orderBy: 'updated_at DESC');

    return List.generate(maps.length, (i) {
      return ChatSession(
        sessionId: maps[i]['session_id'] as String,
        title: maps[i]['title'] as String,
        createdAt: DateTime.parse(maps[i]['created_at'] as String),
        updatedAt: DateTime.parse(maps[i]['updated_at'] as String),
      );
    });
  }

  // 删除会话及其所有消息
  Future<void> deleteSession(String sessionId) async {
    final db = await instance.database;

    // 先删除所有消息
    await db.delete(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );

    // 再删除会话
    await db.delete(
      'chat_sessions',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // 清空所有对话历史
  Future<void> clearAllHistory() async {
    final db = await instance.database;
    await db.delete('chat_messages');
    await db.delete('chat_sessions');
  }

  // 关闭数据库
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

// 聊天会话模型
class ChatSession {
  final String sessionId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.sessionId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
