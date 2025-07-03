import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';

class NoteDatabaseService {
  static final NoteDatabaseService instance = NoteDatabaseService._init();

  static Database? _database;

  NoteDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  isMarkdown BOOLEAN NOT NULL,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  categoryId INTEGER NOT NULL,
  tags TEXT,
  images TEXT
)
''');

    await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE
)
''');
  }

  Future<Note> createNote(Note note) async {
    final db = await instance.database;
    final id = await db.insert('notes', note.toMap());
    return note.copyWith(id: id);
  }

  Future<Note> readNote(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      'notes',
      columns: ['id', 'title', 'content', 'isMarkdown', 'createdAt', 'updatedAt', 'categoryId', 'tags', 'images'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Note.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<Note>> readAllNotes() async {
    final db = await instance.database;
    final result = await db.query('notes');
    return result.map((json) => Note.fromMap(json)).toList();
  }

  Future<int> updateNote(Note note) async {
    final db = await instance.database;
    return db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<NoteCategory> createCategory(NoteCategory category) async {
    final db = await instance.database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  Future<List<NoteCategory>> readAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => NoteCategory.fromMap(json)).toList();
  }

  Future<int> updateCategory(NoteCategory category) async {
    final db = await instance.database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}