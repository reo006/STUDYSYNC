import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder.dart';

class ReminderDatabase {
  static final ReminderDatabase instance = ReminderDatabase._init();
  static Database? _database;

  ReminderDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'reminders.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        repeat TEXT NOT NULL,
        priority TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  Future<List<Reminder>> getAllReminders() async {
    final db = await instance.database;
    final result = await db.query('reminders');
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
