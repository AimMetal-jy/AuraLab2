import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/selected_text.dart';
import './audio_library_service.dart'; // 导入 AudioItem 模型

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // 数据库名称和版本
  static const String _databaseName = 'auralab.db'; // 统一数据库名称
  static const int _databaseVersion = 3; // 升级版本以添加新字段

  // 表名和字段
  // -- TTS 文本选择表
  static const String _ttsTableName = 'selected_texts';
  static const String _ttsColumnId = 'id';
  static const String _ttsColumnText = 'text';
  static const String _ttsColumnCreatedAt = 'created_at';

  // -- 音频库表
  static const String _audioTableName = 'audio_items';
  static const String _audioColumnId = 'id';
  static const String _audioColumnTitle = 'title';
  static const String _audioColumnArtist = 'artist';
  static const String _audioColumnFilePath = 'filePath';
  static const String _audioColumnType = 'type';
  static const String _audioColumnCreatedAt = 'createdAt';
  static const String _audioColumnFileSize = 'fileSize';
  static const String _audioColumnDuration = 'duration';
  static const String _audioColumnPlayCount = 'playCount';
  static const String _audioColumnIsFavorite = 'isFavorite';
  static const String _audioColumnLastPlayed = 'lastPlayed';
  static const String _audioColumnTranscriptionResult = 'transcriptionResult';

  // 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // 首次创建数据库
  Future<void> _onCreate(Database db, int version) async {
    await _createTtsTable(db);
    await _createAudioTable(db);
  }

  // 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAudioTable(db);
    }
    if (oldVersion < 3) {
      await _addTranscriptionResultColumn(db);
    }
  }

  // 创建 TTS 文本表
  Future<void> _createTtsTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_ttsTableName (
        $_ttsColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_ttsColumnText TEXT NOT NULL UNIQUE,
        $_ttsColumnCreatedAt INTEGER NOT NULL
      )
    ''');
  }

  // 创建音频库表
  Future<void> _createAudioTable(Database db) async {
    await db.execute('''
      CREATE TABLE $_audioTableName (
        $_audioColumnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_audioColumnTitle TEXT NOT NULL,
        $_audioColumnArtist TEXT,
        $_audioColumnFilePath TEXT NOT NULL UNIQUE,
        $_audioColumnType TEXT NOT NULL,
        $_audioColumnCreatedAt INTEGER NOT NULL,
        $_audioColumnFileSize INTEGER,
        $_audioColumnDuration INTEGER,
        $_audioColumnPlayCount INTEGER NOT NULL DEFAULT 0,
        $_audioColumnIsFavorite INTEGER NOT NULL DEFAULT 0,
        $_audioColumnLastPlayed INTEGER,
        $_audioColumnTranscriptionResult TEXT
      )
    ''');
  }

  // 添加转录结果字段（数据库升级用）
  Future<void> _addTranscriptionResultColumn(Database db) async {
    await db.execute('''
      ALTER TABLE $_audioTableName
      ADD COLUMN $_audioColumnTranscriptionResult TEXT
    ''');
  }

  // --- 音频库 CRUD 操作 ---

  /// 插入或更新一个音频项
  Future<AudioItem> upsertAudioItem(AudioItem item) async {
    final db = await database;
    // 尝试根据 filePath 查找现有项
    final existing = await getAudioItemByPath(item.filePath);
    if (existing != null) {
      // 更新现有项
      final updatedItem = item.copyWith(id: existing.id);
      await db.update(
        _audioTableName,
        updatedItem.toMap(),
        where: '$_audioColumnId = ?',
        whereArgs: [existing.id],
      );
      return updatedItem;
    } else {
      // 插入新项
      final id = await db.insert(
        _audioTableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return item.copyWith(id: id);
    }
  }

  /// 获取所有音频项
  Future<List<AudioItem>> getAllAudioItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _audioTableName,
      orderBy: '$_audioColumnCreatedAt DESC', // 按创建时间降序
    );
    return List.generate(maps.length, (i) => AudioItem.fromMap(maps[i]));
  }

  /// 根据文件路径获取单个音频项
  Future<AudioItem?> getAudioItemByPath(String filePath) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _audioTableName,
      where: '$_audioColumnFilePath = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return AudioItem.fromMap(maps.first);
    }
    return null;
  }

  /// 根据文件路径删除音频项
  Future<int> deleteAudioItemByPath(String filePath) async {
    final db = await database;
    return await db.delete(
      _audioTableName,
      where: '$_audioColumnFilePath = ?',
      whereArgs: [filePath],
    );
  }

  /// 更新一个音频项
  Future<int> updateAudioItem(AudioItem item) async {
    final db = await database;
    return await db.update(
      _audioTableName,
      item.toMap(),
      where: '$_audioColumnId = ?',
      whereArgs: [item.id],
    );
  }

  /// 清空音频库表
  Future<int> clearAllAudioItems() async {
    final db = await database;
    return await db.delete(_audioTableName);
  }

  // --- TTS 文本 CRUD 操作 (保持不变) ---

  // 插入文本
  Future<int> insertText(String text) async {
    final db = await database;
    final selectedText = SelectedText(text: text, createdAt: DateTime.now());

    try {
      return await db.insert(
        _ttsTableName,
        selectedText.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore, // 忽略重复文本
      );
    } catch (e) {
      debugPrint('Error inserting text: $e');
      return 0;
    }
  }

  // 获取所有文本
  Future<List<SelectedText>> getAllTexts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _ttsTableName,
      orderBy: '$_ttsColumnCreatedAt ASC',
    );

    return List.generate(maps.length, (i) {
      return SelectedText.fromMap(maps[i]);
    });
  }

  // 获取所有文本内容（字符串列表）
  Future<List<String>> getAllTextStrings() async {
    final texts = await getAllTexts();
    return texts.map((t) => t.text).toList();
  }

  // 根据ID删除文本
  Future<int> deleteTextById(int id) async {
    final db = await database;
    return await db.delete(
      _ttsTableName,
      where: '$_ttsColumnId = ?',
      whereArgs: [id],
    );
  }

  // 根据内容删除文本
  Future<int> deleteTextByContent(String text) async {
    final db = await database;
    return await db.delete(
      _ttsTableName,
      where: '$_ttsColumnText = ?',
      whereArgs: [text],
    );
  }

  // 根据索引删除文本（按创建时间排序）
  Future<int> deleteTextByIndex(int index) async {
    final texts = await getAllTexts();
    if (index >= 0 && index < texts.length) {
      return await deleteTextById(texts[index].id!);
    }
    return 0;
  }

  // 根据索引更新文本
  Future<int> updateTextByIndex(int index, String newText) async {
    final texts = await getAllTexts();
    if (index >= 0 && index < texts.length && newText.trim().isNotEmpty) {
      final db = await database;
      return await db.update(
        _ttsTableName,
        {'text': newText},
        where: '$_ttsColumnId = ?',
        whereArgs: [texts[index].id],
      );
    }
    return 0;
  }

  // 清空所有文本
  Future<int> clearAllTexts() async {
    final db = await database;
    return await db.delete(_ttsTableName);
  }

  // 获取文本数量
  Future<int> getTextCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_ttsTableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 检查文本是否存在
  Future<bool> textExists(String text) async {
    final db = await database;
    final result = await db.query(
      _ttsTableName,
      where: '$_ttsColumnText = ?',
      whereArgs: [text],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // 关闭数据库
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
