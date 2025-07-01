import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/selected_text.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // 数据库名称和版本
  static const String _databaseName = 'tts_selection.db';
  static const int _databaseVersion = 1;

  // 表名和字段
  static const String _tableName = 'selected_texts';
  static const String _columnId = 'id';
  static const String _columnText = 'text';
  static const String _columnCreatedAt = 'created_at';

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
    );
  }

  // 创建表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        $_columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $_columnText TEXT NOT NULL UNIQUE,
        $_columnCreatedAt INTEGER NOT NULL
      )
    ''');
  }

  // 插入文本
  Future<int> insertText(String text) async {
    final db = await database;
    final selectedText = SelectedText(
      text: text,
      createdAt: DateTime.now(),
    );
    
    try {
      return await db.insert(
        _tableName,
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
      _tableName,
      orderBy: '$_columnCreatedAt ASC',
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
      _tableName,
      where: '$_columnId = ?',
      whereArgs: [id],
    );
  }

  // 根据内容删除文本
  Future<int> deleteTextByContent(String text) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: '$_columnText = ?',
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
        _tableName,
        {'text': newText},
        where: '$_columnId = ?',
        whereArgs: [texts[index].id],
      );
    }
    return 0;
  }

  // 清空所有文本
  Future<int> clearAllTexts() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  // 获取文本数量
  Future<int> getTextCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 检查文本是否存在
  Future<bool> textExists(String text) async {
    final db = await database;
    final result = await db.query(
      _tableName,
      where: '$_columnText = ?',
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